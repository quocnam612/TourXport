from pymongo import AsyncMongoClient
from src.core.config import settings

# NOTE: Trien khai sau giai doan POC

class Database:
    client: AsyncMongoClient = None

# Singleton instance
db = Database()

async def get_database():
    """
    Dependency Injection để lấy Database instance.
    Sử dụng trong FastAPI route: database = Depends(get_database)
    """
    if db.client is None:
        raise Exception("Database client chưa được khởi tạo. Hãy kiểm tra lại lifespan ở main.py")
    
    return db.client[settings.mongo_db_name]
