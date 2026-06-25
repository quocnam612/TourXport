from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from pymongo import AsyncMongoClient

from src.core.config import settings
from src.dependencies.database import db

from src.api.api import api_router 

from src.core.config import settings


@asynccontextmanager
async def lifespan(app: FastAPI):
    # --- KHI SERVER START ---
    print("Đang khởi động hệ thống...")
    try:
        db.client = AsyncMongoClient(settings.mongo_uri)
        print("Đã kết nối MongoDB.")
    except Exception as e:
        print(f"Lỗi kết nối MongoDB: {e}")
        
    yield 
    
    # --- KHI SERVER SHUTDOWN ---
    print("Đang tắt hệ thống...")
    if db.client:
        db.client.close()
        print("✅ Đã ngắt kết nối MongoDB.")

# Khởi tạo app
app = FastAPI(
    title="TourXport AI Worker",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "AI Worker is running smooth!"}

# ĐĂNG KÝ ROUTER TỔNG VÀO APP
# Điểm bắt đầu của mọi API sẽ có dạng: http://localhost:8000/api/...
app.include_router(api_router, prefix="/api")
