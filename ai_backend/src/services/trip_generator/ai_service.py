from fastapi import Depends
from openai import AsyncOpenAI
from typing import Any, Dict, List

from src.schemas.response.trip_generator import TripGeneratorResponse, RetrievalInfo
from src.schemas.request.trip_generator import TripGenerateRequest
from src.core.config import settings
from src.dependencies.openai_client import get_openai_client
from src.services.trip_generator.db_service import (
    EMBEDDING_MODEL, VECTOR_INDEX_NAME
)


class AIService:
    def __init__(self, openai_client: AsyncOpenAI):
        self.client = openai_client
        self.model = "gpt-4.1-mini"

    # ──────────────────────────────────────────
    # Helper: xây user prompt chung
    # ──────────────────────────────────────────

    @staticmethod
    def _build_user_prompt(user_input: TripGenerateRequest) -> str:
        """Xây dựng user prompt từ request data (dùng chung cho cả 2 luồng)."""
        if isinstance(user_input.destinations, list):
            destinations_text = ", ".join(user_input.destinations)
        else:
            destinations_text = "tự chọn điểm đến phù hợp nhất"

        interests_text = (
            ", ".join(user_input.preferences.interests)
            if user_input.preferences.interests
            else "không rõ"
        )

        return (
            f"Điểm đến: {destinations_text}\n"
            f"Thời gian: {user_input.total_days} ngày {user_input.total_nights} đêm\n"
            f"Hành khách: {user_input.travelers.adults} người lớn, "
            f"{user_input.travelers.children} trẻ em\n"
            f"Mức ngân sách tối đa mong muốn: {user_input.preferences.budget_level:,} VND\n"
            f"Sở thích: {interests_text}\n"
            f"Phương tiện: {user_input.preferences.transport_mode}\n"
            f"Nhịp độ: {user_input.preferences.pace}"
        )

    @staticmethod
    def _validate_trip_day_count(
        result: TripGeneratorResponse,
        user_input: TripGenerateRequest,
    ) -> None:
        requested_days = user_input.total_days
        actual_days = len(result.days or [])

        if result.total_days != requested_days:
            raise ValueError(
                f"AI response totalDays={result.total_days}, expected {requested_days}"
            )

        if result.total_nights != user_input.total_nights:
            raise ValueError(
                f"AI response totalNights={result.total_nights}, expected {user_input.total_nights}"
            )

        if actual_days != requested_days:
            raise ValueError(
                f"AI response has {actual_days} day(s), expected {requested_days}"
            )

        expected_day_numbers = list(range(1, requested_days + 1))
        actual_day_numbers = [day.day_number for day in result.days]
        if actual_day_numbers != expected_day_numbers:
            raise ValueError(
                f"AI response dayNumber sequence={actual_day_numbers}, expected {expected_day_numbers}"
            )

    @staticmethod
    def _build_day_count_retry_message(user_input: TripGenerateRequest) -> str:
        return (
            "Response trước đó chưa đúng số ngày yêu cầu. Hãy tạo lại toàn bộ JSON.\n"
            f"BẮT BUỘC totalDays = {user_input.total_days}.\n"
            f"BẮT BUỘC days có đúng {user_input.total_days} phần tử.\n"
            f"BẮT BUỘC dayNumber lần lượt là 1 đến {user_input.total_days}.\n"
            "Không được gộp nhiều ngày vào một phần tử day. Không được trả thiếu ngày."
        )

    # ──────────────────────────────────────────
    # Helper: format DB documents thành context text
    # ──────────────────────────────────────────

    @staticmethod
    def _format_db_context(rag_results: Dict[str, List[Dict[str, Any]]]) -> str:
        """
        Chuyển kết quả RAG (dict 3 collection) thành chuỗi text cho LLM.
        Mỗi document bao gồm _id, _collection, title, city, category, tags, score, location.
        """
        lines: List[str] = []

        for collection_name, docs in rag_results.items():
            if not docs:
                continue
            lines.append(f"\n=== {collection_name.upper()} ({len(docs)} kết quả) ===")
            for i, doc in enumerate(docs, 1):
                doc_id = doc.get("_id", "?")
                title = doc.get("title", "Không tên")
                city = doc.get("city", "?")
                category = doc.get("category", "?")
                tags = ", ".join(doc.get("tags", []))
                score = doc.get("score", 0)
                location = doc.get("location", {})
                coords = location.get("coordinates", [None, None]) if location else [None, None]

                lines.append(
                    f"  {i}. [{doc_id}] {title}\n"
                    f"     Thành phố: {city} | Loại: {category} | Tags: {tags}\n"
                    f"     Score: {score:.4f} | Tọa độ GeoJSON [longitude, latitude]: {coords}"
                )

        return "\n".join(lines) if lines else "(Không có dữ liệu từ Database)"

    # ──────────────────────────────────────────
    # Luồng 1: RAG — AI sinh dựa trên dữ liệu DB
    # ──────────────────────────────────────────

    async def generate_itinerary_rag(
        self,
        user_input: TripGenerateRequest,
        rag_results: Dict[str, List[Dict[str, Any]]],
        top_k: int,
    ) -> TripGeneratorResponse:
        """
        Luồng RAG: AI lập lịch trình dựa trên dữ liệu thực từ MongoDB.
        LLM được cung cấp danh sách địa điểm/nhà hàng/khách sạn từ DB
        và phải ưu tiên sử dụng chúng trong lịch trình.
        """

        db_context = self._format_db_context(rag_results)

        system_prompt = (
            "Bạn là một chuyên gia lập kế hoạch du lịch Việt Nam thông minh.\n\n"
            "BẠN ĐƯỢC CUNG CẤP danh sách địa điểm, nhà hàng, khách sạn THỰC TẾ "
            "từ cơ sở dữ liệu (DB). Hãy ƯU TIÊN sử dụng chúng khi lập lịch trình.\n\n"
            "LUẬT QUAN TRỌNG:\n"
            "- Trả về JSON đúng schema được yêu cầu.\n"
            "- Với mỗi item lấy từ DB: source.provider = 'database', "
            "source.collection = tên collection (places/restaurants/hotels), "
            "source.id = _id của document.\n"
            "- Nếu cần thêm địa điểm ngoài danh sách DB (bổ sung cho đủ lịch trình): "
            "source.provider = 'ai_generated', source.collection = null, source.id = null.\n"
            "- Sử dụng title gốc từ DB, không đổi tên.\n"
            "- Lấy tọa độ location từ DB nếu có. Tọa độ DB đã là GeoJSON [longitude, latitude], hãy copy đúng thứ tự và không đảo lat/lng.\n"
            "- Mỗi ngày phải có trường 'dayNumber', 'title', 'summary', và danh sách 'items'.\n"
            f"- BẮT BUỘC trường 'days' phải có đúng {user_input.total_days} phần tử, tương ứng đúng {user_input.total_days} ngày.\n"
            f"- BẮT BUỘC dayNumber phải lần lượt từ 1 đến {user_input.total_days}; không được gộp nhiều ngày vào một object.\n"
            f"- BẮT BUỘC top-level totalDays phải bằng {user_input.total_days} và totalNights phải bằng {user_input.total_nights}.\n"
            "- Mỗi item cần có order, type, title, category, startTime, endTime.\n"
            "- type của item: 'place' cho places, 'restaurant' cho restaurants, 'hotel' cho hotels.\n"
            "- Trường 'date' trong mỗi day có thể để null.\n"
            "- estimatedCost (cấp top-level) phải ước tính tổng chi phí cho toàn bộ chuyến đi. Hãy thiết kế lịch trình sao cho tổng chi phí tối đa ước tính (estimatedCost.max) phù hợp và nằm trong tầm ngân sách mong muốn của người dùng.\n"
            "- Trường 'ai.model' phải là '" + self.model + "'.\n"
            "- Trường 'ai.generatedBy' phải là 'ai_backend'.\n"
            "- Trường 'ai.embeddingModel' phải là '" + EMBEDDING_MODEL + "'.\n"
            "- Trường 'ai.retrieval' phải có strategy='vector_search', "
            "index='" + VECTOR_INDEX_NAME + "', topK=" + str(top_k) + ".\n"
        )

        user_prompt = (
            self._build_user_prompt(user_input)
            + "\n\n--- DỮ LIỆU TỪ DATABASE ---\n"
            + db_context
        )

        try:
            messages = [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ]

            last_error: Exception | None = None
            for attempt in range(2):
                response = await self.client.beta.chat.completions.parse(
                    model=self.model,
                    messages=messages,
                    response_format=TripGeneratorResponse,
                    max_tokens=10000,
                    temperature=0.7
                )

                result = response.choices[0].message.parsed

                # Ép metadata AI đúng cho luồng RAG
                result.ai.generated_by = "ai_backend"
                result.ai.model = self.model
                result.ai.embedding_model = EMBEDDING_MODEL
                result.ai.retrieval = RetrievalInfo(
                    strategy="vector_search",
                    index=VECTOR_INDEX_NAME,
                    top_k=top_k,
                )

                try:
                    self._validate_trip_day_count(result, user_input)
                    return result
                except ValueError as validation_error:
                    last_error = validation_error
                    print(
                        f"[AIService] RAG response sai số ngày "
                        f"(attempt {attempt + 1}/2): {validation_error}"
                    )
                    messages.append({
                        "role": "assistant",
                        "content": result.model_dump_json(by_alias=True),
                    })
                    messages.append({
                        "role": "user",
                        "content": self._build_day_count_retry_message(user_input),
                    })

            raise last_error or ValueError("AI response sai số ngày")

        except Exception as e:
            print(f"[AIService] Lỗi gọi OpenAI (RAG): {str(e)}")
            raise e

    # ──────────────────────────────────────────
    # Luồng 2: Pure LLM — AI tự sinh 100%
    # ──────────────────────────────────────────

    async def generate_itinerary_pure_llm(
        self, user_input: TripGenerateRequest
    ) -> TripGeneratorResponse:
        """
        Trường hợp Fallback: AI tự chém hoàn toàn dựa trên kiến thức của nó
        khi Database không có dữ liệu.
        """

        system_prompt = (
            "Bạn là một chuyên gia lập kế hoạch du lịch Việt Nam thông minh. "
            "Dựa trên thông tin người dùng cung cấp, hãy tạo một lịch trình du lịch chi tiết.\n\n"
            "LUẬT QUAN TRỌNG:\n"
            "- Trả về JSON đúng schema được yêu cầu.\n"
            "- Vì đây là luồng AI tự sinh (không truy vấn DB), trong trường 'source' của mỗi item: "
            "  provider phải là 'ai_generated', collection và id phải là null.\n"
            "- Mỗi ngày phải có trường 'dayNumber', 'title', 'summary', và danh sách 'items'.\n"
            f"- BẮT BUỘC trường 'days' phải có đúng {user_input.total_days} phần tử, tương ứng đúng {user_input.total_days} ngày.\n"
            f"- BẮT BUỘC dayNumber phải lần lượt từ 1 đến {user_input.total_days}; không được gộp nhiều ngày vào một object.\n"
            f"- BẮT BUỘC top-level totalDays phải bằng {user_input.total_days} và totalNights phải bằng {user_input.total_nights}.\n"
            "- Mỗi item cần có order, type, title, category, startTime, endTime.\n"
            "- Trường 'date' trong mỗi day có thể để null.\n"
            "- Tọa độ trong location phải là [longitude, latitude] (GeoJSON). Nếu biết tọa độ theo dạng phổ biến latitude,longitude thì phải đảo lại trước khi trả về.\n"
            "- estimatedCost (cấp top-level) phải ước tính tổng chi phí cho toàn bộ chuyến đi. Hãy thiết kế lịch trình sao cho tổng chi phí tối đa ước tính (estimatedCost.max) phù hợp và nằm trong tầm ngân sách mong muốn của người dùng.\n"
            "- Trường 'ai.model' phải là '" + self.model + "'.\n"
            "- Trường 'ai.generatedBy' phải là 'ai_backend'.\n"
            "- Trường 'ai.retrieval' phải là null (vì không dùng RAG).\n"
            "- Trường 'ai.embeddingModel' phải là null (vì không dùng RAG).\n"
        )

        user_prompt = self._build_user_prompt(user_input)

        try:
            messages = [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt},
            ]

            last_error: Exception | None = None
            for attempt in range(2):
                response = await self.client.beta.chat.completions.parse(
                    model=self.model,
                    messages=messages,
                    response_format=TripGeneratorResponse,
                    max_tokens=10000,
                    temperature=0.7
                )

                result = response.choices[0].message.parsed

                # Ép metadata AI cho đúng (phòng trường hợp LLM trả sai)
                result.ai.generated_by = "ai_backend"
                result.ai.model = self.model
                result.ai.embedding_model = None
                result.ai.retrieval = None

                try:
                    self._validate_trip_day_count(result, user_input)
                    return result
                except ValueError as validation_error:
                    last_error = validation_error
                    print(
                        f"[AIService] Pure LLM response sai số ngày "
                        f"(attempt {attempt + 1}/2): {validation_error}"
                    )
                    messages.append({
                        "role": "assistant",
                        "content": result.model_dump_json(by_alias=True),
                    })
                    messages.append({
                        "role": "user",
                        "content": self._build_day_count_retry_message(user_input),
                    })

            raise last_error or ValueError("AI response sai số ngày")

        except Exception as e:
            print(f"[AIService] Lỗi gọi OpenAI (Pure LLM): {str(e)}")
            raise e


def get_ai_service(openai_client: AsyncOpenAI = Depends(get_openai_client)) -> AIService:
    return AIService(openai_client)
