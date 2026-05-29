"""
TripOrchestrator — Điều phối luồng xử lý chính.

Quyết định:
  - Nếu destinations là danh sách cụ thể → Chạy RAG (vector search DB → AI sinh dựa trên data)
  - Nếu RAG không trả đủ kết quả → Fallback về Pure LLM (AI tự sinh 100%)
  - Nếu destinations là "auto" → Pure LLM (AI tự chọn điểm đến)
"""

from fastapi import Depends
from typing import List, Optional

from src.schemas.request.trip_generator import TripGenerateRequest
from src.schemas.response.trip_generator import TripGeneratorResponse
from src.services.trip_generator.ai_service import AIService, get_ai_service
from src.services.trip_generator.db_service import DBService, get_db_service, DEFAULT_TOP_K


# Ngưỡng tối thiểu: nếu tổng documents từ DB < con số này → fallback Pure LLM
MIN_RAG_RESULTS = 3


class TripOrchestrator:
    def __init__(self, ai_service: AIService, db_service: DBService):
        self.ai_service = ai_service
        self.db_service = db_service

    # ──────────────────────────────────────────
    # Helper: xây search query từ preferences
    # ──────────────────────────────────────────

    @staticmethod
    def _build_search_query(request_data: TripGenerateRequest) -> str:
        """
        Ghép interests + destinations thành 1 chuỗi text để sinh embedding.
        VD: "temple, culture, local food, scenic view ở Châu Đốc, Cà Mau"
        """
        parts: List[str] = []

        # Sở thích
        if request_data.preferences.interests:
            parts.append(", ".join(request_data.preferences.interests))

        # Điểm đến (thêm context địa lý cho embedding)
        if isinstance(request_data.destinations, list):
            parts.append("ở " + ", ".join(request_data.destinations))

        return " ".join(parts) if parts else "du lịch Việt Nam"

    # ──────────────────────────────────────────
    # Tính top_k dựa trên số ngày
    # ──────────────────────────────────────────

    @staticmethod
    def _calculate_top_k(total_days: int) -> int:
        """
        Lấy nhiều hơn khi chuyến đi dài hơn.
        Mỗi ngày cần ~4-6 items → lấy dư để LLM có nhiều lựa chọn.
        """
        base = total_days * 5  # ~5 items/ngày
        return max(base, DEFAULT_TOP_K)  # Tối thiểu DEFAULT_TOP_K

    # ──────────────────────────────────────────
    # Luồng điều phối chính
    # ──────────────────────────────────────────

    async def execute(self, request_data: TripGenerateRequest) -> TripGeneratorResponse:
        """
        Hàm điều phối luồng xử lý chính:
          1. Nếu destinations = "auto" → Pure LLM (AI tự chọn)
          2. Nếu destinations là list → RAG: search DB → kiểm tra đủ data → AI sinh từ data
          3. Nếu RAG không đủ kết quả → Fallback Pure LLM
        """
        destinations_display = (
            request_data.destinations
            if isinstance(request_data.destinations, str)
            else ", ".join(request_data.destinations)
        )
        print(f"\n{'='*60}")
        print(f"[Orchestrator] Chuyến đi: {destinations_display} "
              f"({request_data.total_days} ngày {request_data.total_nights} đêm)")
        print(f"[Orchestrator] Budget: {request_data.preferences.budget_level} | "
              f"Interests: {request_data.preferences.interests}")
        print(f"{'='*60}")

        # ── Quyết định luồng ──

        # Case 1: destinations = "auto" → AI tự chọn, không cần DB
        if request_data.destinations == "auto":
            print("[Orchestrator] Destinations = 'auto' → Luồng Pure LLM")
            result = await self.ai_service.generate_itinerary_pure_llm(request_data)
            print("[Orchestrator] ✅ Hoàn tất (Pure LLM)")
            return result

        # Case 2: destinations là list → Thử RAG trước
        print("[Orchestrator] Destinations cụ thể → Thử luồng RAG...")

        # Bước 1: Xây query text và tính top_k
        search_query = self._build_search_query(request_data)
        top_k = self._calculate_top_k(request_data.total_days)

        # Bước 2: Xác định city filter
        city_filter: Optional[List[str]] = (
            request_data.destinations
            if isinstance(request_data.destinations, list)
            else None
        )

        # Bước 3: Vector search song song trên 3 collection
        rag_results = await self.db_service.vector_search_all(
            query_text=search_query,
            top_k=top_k,
            city_filter=city_filter,
            budget_level=request_data.preferences.budget_level,
            total_days=request_data.total_days,
            adults=request_data.travelers.adults,
            children=request_data.travelers.children,
        )

        # Bước 4: Kiểm tra đủ kết quả không
        total_results = sum(len(docs) for docs in rag_results.values())

        if total_results < MIN_RAG_RESULTS:
            print(f"[Orchestrator] ⚠ RAG chỉ có {total_results} kết quả "
                  f"(< {MIN_RAG_RESULTS}) → Fallback Pure LLM")
            result = await self.ai_service.generate_itinerary_pure_llm(request_data)
            print("[Orchestrator] ✅ Hoàn tất (Fallback Pure LLM)")
            return result

        # Bước 5: Đủ data → Gọi AI với context DB
        print(f"[Orchestrator] RAG có {total_results} kết quả → Sinh lịch trình từ DB data")
        result = await self.ai_service.generate_itinerary_rag(
            user_input=request_data,
            rag_results=rag_results,
            top_k=top_k,
        )
        print("[Orchestrator] ✅ Hoàn tất (RAG)")
        return result


# ──────────────────────────────────────────
# Dependency Injection cho FastAPI
# ──────────────────────────────────────────

def get_trip_orchestrator(
    ai_service: AIService = Depends(get_ai_service),
    db_service: DBService = Depends(get_db_service),
) -> TripOrchestrator:
    return TripOrchestrator(ai_service=ai_service, db_service=db_service)