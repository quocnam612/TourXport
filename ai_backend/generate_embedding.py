import os
import asyncio
from dotenv import load_dotenv
from motor.motor_asyncio import AsyncIOMotorClient
from pymongo import UpdateOne
import openai

load_dotenv()

client = AsyncIOMotorClient(os.getenv("MONGO_URI"))
db = client["test"]
openai_client = openai.AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))

async def generate_and_update_embeddings(collection_name, batch_size=100):
    collection = db[collection_name]
    
    # Lấy toàn bộ danh sách docs cần xử lý về RAM trước (chỉ lấy _id và searchText để nhẹ)
    # Cách này giải quyết triệt để lỗi cursor khi update
    cursor = collection.find({"embedding": None}, {"_id": 1, "searchText": 1})
    docs = await cursor.to_list(length=None)
    
    if not docs:
        print(f"Không có dữ liệu cần update trong collection: {collection_name}")
        return

    print(f"Tìm thấy {len(docs)} documents cần sinh embedding trong {collection_name}...")

    # Chia nhỏ danh sách thành từng batch để gom request
    for i in range(0, len(docs), batch_size):
        batch = docs[i:i + batch_size]
        
        # Lọc bỏ các doc lỗi không có searchText hoặc searchText rỗng
        valid_batch = [d for d in batch if d.get("searchText")]
        if not valid_batch:
            continue
            
        texts = [d["searchText"] for d in valid_batch]
        
        try:
            # 1. Gọi OpenAI sinh embed cho cả nhóm cùng lúc
            response = await openai_client.embeddings.create(
                input=texts,
                model="text-embedding-3-small"
            )
            
            # 2. Gom các lệnh update vào một Bulk Write
            bulk_operations = []
            for idx, doc in enumerate(valid_batch):
                vector = response.data[idx].embedding
                bulk_operations.append(
                    UpdateOne({"_id": doc["_id"]}, {"$set": {"embedding": vector}})
                )
            
            # 3. Thực thi ghi vào DB một lần duy nhất cho cả batch
            if bulk_operations:
                await collection.bulk_write(bulk_operations)
                print(f"Đã cập nhật thành công một batch {len(bulk_operations)} docs.")
                
        except Exception as e:
            print(f"Lỗi khi xử lý batch từ vị trí {i}: {e}")
            # Bạn có thể quyết định continue để chạy tiếp batch sau hoặc raise lỗi tùy nhu cầu

async def main():
    # Chạy lần lượt cho các collection bạn muốn
    # await generate_and_update_embeddings("hotels")
    # await generate_and_update_embeddings("restaurants")
    await generate_and_update_embeddings("places")

if __name__ == "__main__":
    # Điểm kích hoạt chạy script async an toàn trong Python
    asyncio.run(main())