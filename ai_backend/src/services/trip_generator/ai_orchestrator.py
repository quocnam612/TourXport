from fastapi import Depends
from src.schemas.request.trip_generator import TripGenerateRequest
from src.schemas.response.trip_generator import TripGeneratorResponse
from src.services.trip_generator.ai_service import AIService, get_ai_service
# TODO (Phase 3): import DBService ở đây

class TripOrchestrator:
    def __init__(self, ai_service: AIService):
        self.ai_service = ai_service
        # self.db_service = db_service

    async def execute(self, request_data: TripGenerateRequest) -> TripGeneratorResponse:
        """
        Hàm điều phối luồng xử lý chính.
        Quyết định xem nên lấy data từ DB (RAG) hay để AI tự sinh (Pure LLM).
        """
        print(f"--- Bắt đầu điều phối chuyến đi ({request_data.duration_days} ngày) ---")

        # -------------------------------------------------------------
        # TODO: LOGIC TƯƠNG LAI
        # 1. vector = await self.ai_service.get_embedding(request_data.preferences)
        # 2. db_places = await self.db_service.vector_search(vector, request_data.budget)
        # 3. if len(db_places) > MIN_PLACES:
        #        return await self.ai_service.generate_itinerary_rag(request_data, db_places)
        # -------------------------------------------------------------

        print("MVP Phase: Database trống -> Chuyển luồng Pure LLM (AI tự tạo).")
        result = await self.ai_service.generate_itinerary_pure_llm(request_data)
        
        print("--- Hoàn tất sinh lịch trình! ---")
        return result

# Dependency Injection cho FastAPI
def get_trip_orchestrator(
    ai_service: AIService = Depends(get_ai_service)
    # db_service = Depends(get_db_service) # Mở khóa ở Phase 3
) -> TripOrchestrator:
    return TripOrchestrator(ai_service=ai_service)