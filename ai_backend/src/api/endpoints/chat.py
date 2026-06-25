from fastapi import APIRouter, Depends
from src.schemas.request.guide_chat import GuideChatRequest
from src.services.chat.manager import GuideChatService
from src.dependencies.database import get_database
from src.dependencies.openai_client import get_openai_client

router = APIRouter()

@router.post("/")
async def chat_with_guide(
    payload: GuideChatRequest,
    db = Depends(get_database),
    openai_client = Depends(get_openai_client)
):
    service = GuideChatService(db=db, openai_client=openai_client)
    # Tạm thời để user_id là guest, có thể thay đổi sau nếu có auth
    response = await service.handle_chat(payload=payload, user_id="guest")
    return {"reply": response}