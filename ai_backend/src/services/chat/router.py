from pydantic import BaseModel, Field
from typing import List
from openai import AsyncOpenAI
from src.services.chat.wiki_data import TOPIC_DESCRIPTIONS

class RouterResponse(BaseModel):
    selected_topics: List[str] = Field(description="Danh sách các topic ID liên quan nhất đến câu hỏi của người dùng")
    confidence: float = Field(description="Độ tự tin từ 0.0 đến 1.0 về mức độ chắc chắn các topic này chứa câu trả lời")

class SemanticRouter:
    def __init__(self, openai_client: AsyncOpenAI):
        self._llm = openai_client

    async def route(self, user_message: str) -> RouterResponse:
        # Build topic list text
        topics_text = ""
        for topic_id, desc in TOPIC_DESCRIPTIONS.items():
            topics_text += f"- {topic_id}: {desc}\n"

        system_prompt = f"""
        Bạn là một hệ thống phân loại câu hỏi (Semantic Router) cho ứng dụng du lịch TourXport.
        Nhiệm vụ của bạn là đọc câu hỏi của người dùng và chọn ra những 'Topic ID' chứa hướng dẫn sử dụng tương ứng.
        Chỉ chọn các topic thực sự liên quan. Nếu câu hỏi nằm ngoài phạm vi hoặc chỉ là chào hỏi bình thường, hãy trả về danh sách rỗng và độ tự tin thấp.

        [DANH SÁCH CÁC TOPIC ID]
        {topics_text}
        """

        response = await self._llm.beta.chat.completions.parse(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message}
            ],
            response_format=RouterResponse,
            temperature=0.0
        )

        return response.choices[0].message.parsed
