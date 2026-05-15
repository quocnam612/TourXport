from fastapi import Depends 
from openai import AsyncOpenAI
from src.schemas.response.trip_generator import TripGeneratorResponse
from src.schemas.request.trip_generator import TripGenerateRequest
from src.core.config import settings
from src.dependencies.openai_client import get_openai_client

class AIService:
    def __init__(self, openai_client: AsyncOpenAI):
        self.client = openai_client
        self.model = "gpt-4o-mini"

    async def generate_itinerary_pure_llm(self, user_input: TripGenerateRequest) -> TripGeneratorResponse:
        """
        Trường hợp Fallback: AI tự chém hoàn toàn dựa trên kiến thức của nó
        khi Database không có dữ liệu.
        """
        
        system_prompt = (
            "Bạn là một chuyên gia lập kế hoạch du lịch thông minh. "
            "Dựa trên ngân sách, số ngày và sở thích của người dùng, hãy tạo một lịch trình chi tiết. "
            "Vì hiện tại không có dữ liệu địa điểm trong cơ sở dữ liệu, hãy tự đề xuất các địa điểm nổi tiếng "
            "phù hợp với sở thích của người dùng. "
            "BẮT BUỘC trả về định dạng JSON chuẩn. Trường 'place_id' phải để null."
        )

        user_prompt = (
            f"Ngân sách: {user_input.budget} VND. "
            f"Thời gian: {user_input.duration_days} ngày. "
            f"Sở thích: {user_input.preferences}"
        )

        try:
            response = await self.client.beta.chat.completions.parse(
                model=self.model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                response_format=TripGeneratorResponse, # Nhét Schema của ông vào đây
                max_tokens=2000,
                temperature=0.7
            )

            # validate response dung schema va parse thanh object TripGeneratorResponse
            result = response.choices[0].message.parsed
            
            # Vì đây là luồng AI tự chém, ta ép cờ is_from_db = False
            result.data.is_from_db = False
            
            return result

        except Exception as e:
            # Log lỗi ở đây nếu cần
            print(f"Lỗi gọi OpenAI: {str(e)}")
            raise e
        
def get_ai_service(openai_client: AsyncOpenAI = Depends(get_openai_client)) -> AIService:
    return AIService(openai_client)
