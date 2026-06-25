from typing import List
from uuid import UUID
from openai import AsyncOpenAI
from pymongo import AsyncMongoClient
from pymongo.asynchronous.database import AsyncDatabase
from src.schemas.request.guide_chat import GuideChatRequest
from src.services.chat.router import SemanticRouter
from src.services.chat.wiki_data import WIKI_KNOWLEDGE_BASE
import time

class GuideChatService:
    _base_system_prompt = """
# TourXport - Trợ Lý Ảo Hướng Dẫn Sử Dụng
Bạn là Trợ lý ảo AI của ứng dụng du lịch TourXport. Nhiệm vụ của bạn là hướng dẫn người dùng cách sử dụng các tính năng trong app một cách thân thiện, ngắn gọn và chính xác.
- LUÔN LUÔN dựa vào tài liệu HDSD được cung cấp bên dưới (nếu có) để trả lời. TUYỆT ĐỐI KHÔNG bịa đặt thêm tính năng.
- Trả lời ngắn gọn, đi thẳng vào vấn đề, hướng dẫn từng bước.
- Nếu người dùng hỏi vấn đề ngoài lề không liên quan app TourXport, hãy lịch sự từ chối.

[TÀI LIỆU HƯỚNG DẪN SỬ DỤNG LIÊN QUAN]
{context}
    """

    def __init__(self, db: AsyncDatabase, openai_client: AsyncOpenAI):
        self._db = db
        self._llm = openai_client
        self._router = SemanticRouter(openai_client)
    
    async def _get_or_create_history(self, session_id: UUID, user_id: str):
        result = await self._db["guide-chat-history"].find_one({ "session_id" : str(session_id)})

        if result and "history" in result:
            return result["history"]
        else:
            return []

    async def handle_chat(self, payload: GuideChatRequest, user_id: str = "guest") -> str:
        """
        Nhạc trưởng điều phối luồng: Router -> Lấy DB -> Ghép Prompt -> Gọi LLM -> Lưu DB (Upsert)
        """
        session_str = str(payload.session_id)
        user_message = payload.content

        # 0. Route the message to find relevant wiki sections
        route_result = await self._router.route(user_message)
        
        context_text = "Không tìm thấy tài liệu hướng dẫn cụ thể cho câu hỏi này. Hãy trả lời dựa trên kiến thức chung về app du lịch hoặc yêu cầu người dùng làm rõ."
        if route_result.confidence > 0.4 and len(route_result.selected_topics) > 0:
            segments = []
            for topic in route_result.selected_topics:
                if topic in WIKI_KNOWLEDGE_BASE:
                    segments.append(WIKI_KNOWLEDGE_BASE[topic])
            if segments:
                context_text = "\n\n".join(segments)

        dynamic_system_prompt = self._base_system_prompt.replace("{context}", context_text)

        # 1. Lấy lịch sử cũ (chỉ lấy 20 tin nhắn gần nhất để không nổ token)
        raw_history = await self._get_or_create_history(payload.session_id, user_id)
        recent_history = raw_history[-20:]

        # 2. Xây dựng mảng Context cho OpenAI
        messages = [{"role": "system", "content": dynamic_system_prompt}]
        
        # Đổ lịch sử cũ vào
        for msg in recent_history:
            messages.append({
                "role": msg["role"],
                "content": msg["content"]
            })
            
        # Nhét câu hỏi MỚI NHẤT của user vào cuối mảng
        messages.append({"role": "user", "content": user_message})

        # 3. Gọi LLM Client sinh câu trả lời
        response = await self._llm.chat.completions.create(
            model="gpt-4o", # Đổi tên model nếu nhóm dùng loại khác
            messages=messages,
            temperature=0.7      # Độ sáng tạo của câu trả lời
        )
        ai_reply = response.choices[0].message.content

        # 4. Lưu cả cặp tin nhắn vào MongoDB bằng Cửa sổ trượt (Sliding Window)
        now_timestamp = str(time.time())
        user_msg_doc = {"role": "user", "content": user_message, "time_sent": now_timestamp}
        ai_msg_doc = {"role": "assistant", "content": ai_reply, "time_sent": now_timestamp}

        await self._db["guide-chat-history"].update_one(
            {"session_id": session_str},
            {
                "$push": {
                    "history": {
                        "$each": [user_msg_doc, ai_msg_doc],
                        "$slice": -40  # Luôn giữ mảng không vượt quá 40 phần tử
                    }
                },
                # $setOnInsert CHỈ CHẠY 1 LẦN khi session chưa từng tồn tại
                "$setOnInsert": {
                    "created_at": now_timestamp,
                    "user_id": user_id
                },
                "$set": {
                    "updated_at": now_timestamp
                }
            },
            upsert=True # Cực kỳ quan trọng: Không có thì tự tạo mới!
        )

        # 5. Trả về đúng câu trả lời để API gửi về cho Node.js
        return ai_reply
    