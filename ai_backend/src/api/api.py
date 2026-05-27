from fastapi import APIRouter

# Import các router từ thư mục endpoints
from src.api.endpoints import trip_generator
from src.api.endpoints import chat
from src.api.endpoints import test_rag

# Khởi tạo một Router tổng
api_router = APIRouter()

api_router.include_router(
    trip_generator.router, 
    prefix="/trip",        # URL sẽ thành: /api/trip/generate
    tags=["Trip Generator"]
)

api_router.include_router(
    chat.router, 
    prefix="/chat",        # URL sẽ thành: /api/chat/...
    tags=["Chat (Assistant)"]
)

api_router.include_router(
    test_rag.router,
    prefix="/trip",        # URL sẽ thành: /api/trip/test-rag
    tags=["RAG Test"]
)
