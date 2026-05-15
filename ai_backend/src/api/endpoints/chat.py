from fastapi import APIRouter

# ĐÂY NÈ: Phải khai báo biến 'router' thì thằng api.py mới thấy được
router = APIRouter()

@router.get("/")
async def test_chat():
    return {"message": "Chat endpoint is working"}