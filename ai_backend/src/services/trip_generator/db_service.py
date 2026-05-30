"""
DBService — RAG retrieval pipeline cho TourXport.

Luồng:  Request → Embedding (OpenAI) → MongoDB Aggregation Pipeline
        (pre-filter bằng $match + $vectorSearch) → trả danh sách documents.

Ba collection được search song song:
  - places       (địa điểm du lịch)
  - restaurants   (nhà hàng)
  - hotels        (nơi lưu trú)

Tất cả đều dùng index có tên "vector_index" trên field "embedding",
nằm trong database "test".
"""

from __future__ import annotations

import asyncio
from typing import Any, Dict, List, Optional

from fastapi import Depends
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from openai import AsyncOpenAI

from src.dependencies.database import db
from src.dependencies.openai_client import get_openai_client
from src.core.config import settings

import unicodedata

# ──────────────────────────────────────────────
# Hằng số cấu hình
# ──────────────────────────────────────────────

DB_NAME = settings.mongo_db_name

EMBEDDING_MODEL = "text-embedding-3-small"
EMBEDDING_DIMENSIONS = 1536  # Dimension mặc định của text-embedding-3-small

VECTOR_INDEX_NAME = "vector_index"  # Tên Atlas Vector Search index (chung cả 3 collection)
EMBEDDING_FIELD = "embedding"       # Tên field chứa vector trong document

# Các collection cần search
COLLECTION_PLACES = "places"
COLLECTION_RESTAURANTS = "restaurants"
COLLECTION_HOTELS = "hotels"

DEFAULT_TOP_K = 10  # Số kết quả vector search mỗi collection
NUM_CANDIDATES_MULTIPLIER = 10  # numCandidates = topK * multiplier (ảnh hưởng chất lượng)




class DBService:
    """
    Service xử lý RAG retrieval:
      1. Sinh embedding từ preferences (OpenAI)
      2. Chạy $vectorSearch kết hợp pre-filter trên 3 collection song song
      3. Gom kết quả, trả về cho AI Orchestrator
    """

    def __init__(self, openai_client: AsyncOpenAI):
        self.openai_client = openai_client
        self.embedding_model = EMBEDDING_MODEL

    # ──────────────────────────────────────────
    # 1. Sinh embedding vector
    # ──────────────────────────────────────────

    async def get_embedding(self, text: str) -> List[float]:
        """
        Gọi OpenAI Embeddings API để chuyển text → vector.
        Dùng text-embedding-3-small (1536 dimensions).
        """
        response = await self.openai_client.embeddings.create(
            input=text,
            model=self.embedding_model
        )
        return response.data[0].embedding

    # ──────────────────────────────────────────
    # 2. Xây dựng Aggregation Pipeline
    # ──────────────────────────────────────────

    @staticmethod
    def _build_vector_search_pipeline(
        collection_name: str,
        query_vector: List[float],
        top_k: int = DEFAULT_TOP_K,
        city_filter: Optional[List[str]] = None,
        budget_level: Optional[int] = None,
        total_days: Optional[int] = None,
        adults: Optional[int] = None,
        children: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        """
        Tạo MongoDB Aggregation Pipeline cho $vectorSearch.

        Pipeline flow:
          $vectorSearch (vector search + pre-filter city)
          → $match (post-filter budget — vì priceRange chưa index trong vector index)
          → $project (loại bỏ embedding, thêm score)

        Lưu ý: $vectorSearch pre-filter CHỈ hoạt động với các field
        đã được khai báo trong Atlas Vector Search index definition.
        Hiện tại chỉ có 'city' được index → filter giá phải dùng post-filter.
        """

        pipeline: List[Dict[str, Any]] = []

        # ── Stage 1: $vectorSearch (pre-filter chỉ có city) ──
        vector_search_stage: Dict[str, Any] = {
            "$vectorSearch": {
                "index": VECTOR_INDEX_NAME,
                "path": EMBEDDING_FIELD,
                "queryVector": query_vector,
                "numCandidates": top_k * NUM_CANDIDATES_MULTIPLIER,
                "limit": top_k,
            }
        }

        # Pre-filter theo thành phố (phải có trong vector index definition)
        if city_filter:
            vector_search_stage["$vectorSearch"]["filter"] = {
                "city": {"$in": city_filter}
            }

        pipeline.append(vector_search_stage)

        # ── Stage 2: $match post-filter budget (không cần index) ──
        # Tự động tính toán mức giá tối đa cho mỗi dịch vụ dựa trên công thức toán học:
        # 1. Số người quy đổi (effective people): người lớn + 0.5 * trẻ em
        # 2. Ngân sách bình quân đầu người mỗi ngày: daily_per_capita = budget_level / (effective_people * total_days)
        # 3. Phân chia tỷ lệ hợp lý cho từng loại dịch vụ (hotel: 1.2, restaurant: 0.4, place: 0.3)
        max_price = None
        if budget_level and total_days and adults:
            effective_people = float(adults) + 0.5 * float(children or 0)
            daily_per_capita = float(budget_level) / (effective_people * float(total_days))

            # Nếu ngân sách bình quân đầu người mỗi ngày cực cao (> 3 triệu VND/ngày), coi như Luxury -> không filter
            if daily_per_capita < 3000000.0:
                if collection_name == COLLECTION_HOTELS:
                    max_price = max(daily_per_capita * 1.2, 150000.0)
                elif collection_name == COLLECTION_RESTAURANTS:
                    max_price = max(daily_per_capita * 0.4, 50000.0)
                elif collection_name == COLLECTION_PLACES:
                    max_price = max(daily_per_capita * 0.3, 30000.0)

        if max_price is not None:
            pipeline.append({
                "$match": {
                    "$or": [
                        {"priceRange": None},  # doc không có thông tin giá → cho qua
                        {"priceRange": {"$lte": max_price}},
                    ]
                }
            })

        # ── Stage 3: $project — bỏ embedding nặng, thêm score ──
        pipeline.append({
            "$project": {
                "embedding": 0,
                "score": {"$meta": "vectorSearchScore"},
            }
        })

        return pipeline

    # ──────────────────────────────────────────
    # 3. Thực thi Vector Search trên 1 collection
    # ──────────────────────────────────────────

    async def _search_collection(
        self,
        collection_name: str,
        query_vector: List[float],
        top_k: int = DEFAULT_TOP_K,
        city_filter: Optional[List[str]] = None,
        budget_level: Optional[int] = None,
        total_days: Optional[int] = None,
        adults: Optional[int] = None,
        children: Optional[int] = None,
    ) -> List[Dict[str, Any]]:
        """
        Chạy aggregation pipeline trên 1 collection, trả về danh sách documents.
        Mỗi document sẽ có thêm trường 'score' (cosine similarity từ Atlas)
        và '_collection' (để biết nguồn gốc).
        """
        database: AsyncIOMotorDatabase = db.client[DB_NAME]
        collection = database[collection_name]

        pipeline = self._build_vector_search_pipeline(
            collection_name=collection_name,
            query_vector=query_vector,
            top_k=top_k,
            city_filter=city_filter,
            budget_level=budget_level,
            total_days=total_days,
            adults=adults,
            children=children,
        )

        # Debug: log pipeline (bỏ queryVector vì quá dài)
        import json
        debug_pipeline = json.loads(json.dumps(pipeline, default=str))
        for stage in debug_pipeline:
            if "$vectorSearch" in stage:
                stage["$vectorSearch"]["queryVector"] = f"[...{len(query_vector)} dims...]"
        print(f"[DBService] Pipeline cho '{collection_name}': {json.dumps(debug_pipeline, ensure_ascii=False)}")

        try:
            results = []
            async for doc in collection.aggregate(pipeline):
                # Chuyển ObjectId thành string để dễ serialize
                doc["_id"] = str(doc["_id"])
                # Gắn nhãn collection để truy xuất nguồn gốc
                doc["_collection"] = collection_name
                results.append(doc)

            return results
        except Exception as e:
            print(f"[DBService] ❌ Lỗi aggregation trên '{collection_name}': {e}")
            return []

    # ──────────────────────────────────────────
    # 4. Search song song trên cả 3 collection
    # ──────────────────────────────────────────

    async def vector_search_all(
        self,
        query_text: str,
        top_k: int = DEFAULT_TOP_K,
        city_filter: Optional[List[str]] = None,
        budget_level: Optional[int] = None,
        total_days: Optional[int] = None,
        adults: Optional[int] = None,
        children: Optional[int] = None,
    ) -> Dict[str, List[Dict[str, Any]]]:
        """
        Entry point chính:
          1. Chuyển query_text → embedding vector
          2. Chạy vector search song song trên places, restaurants, hotels
          3. Trả về dict với key là tên collection, value là danh sách kết quả

        Returns:
            {
                "places": [...],
                "restaurants": [...],
                "hotels": [...]
            }
        """

        print(f"[DBService] Đang sinh embedding cho query: '{query_text[:80]}...'")
        query_vector = await self.get_embedding(query_text)

        print(f"[DBService] Bắt đầu vector search song song trên 3 collection "
              f"(top_k={top_k}, cities={city_filter}, budget={budget_level})")

        # --- FIX NFD/NFC UNICODE ---
        # TODO(Khôi): Bàn lại với Phát và Khánh về việc chạy script migration (NFD -> NFC) cho toàn bộ DB.
        # Dữ liệu text tiếng Việt trong MongoDB (cột city) đang bị dính chuẩn NFD (Decomposed - tách rời dấu), 
        # trong khi Python nhận vào là chuẩn NFC (Composed). MongoDB so khớp exact match byte-by-byte nên query bị hụt (result = 0).
        # Tạm thời ép kiểu query đầu vào về NFD để khớp với DB hiện tại.
        normalized_city_filter = None
        if city_filter:
            normalized_city_filter = [unicodedata.normalize('NFD', city) for city in city_filter]
        # ---------------------------

        # Chạy song song 3 collection (truyền normalized_city_filter vào thay vì city_filter gốc)
        places_task = self._search_collection(
            COLLECTION_PLACES, query_vector, top_k, normalized_city_filter, budget_level, total_days, adults, children
        )
        restaurants_task = self._search_collection(
            COLLECTION_RESTAURANTS, query_vector, top_k, normalized_city_filter, budget_level, total_days, adults, children
        )
        hotels_task = self._search_collection(
            COLLECTION_HOTELS, query_vector, top_k, normalized_city_filter, budget_level, total_days, adults, children
        )

        places, restaurants, hotels = await asyncio.gather(
            places_task, restaurants_task, hotels_task
        )

        print(f"[DBService] Kết quả: "
              f"places={len(places)}, restaurants={len(restaurants)}, hotels={len(hotels)}")

        return {
            COLLECTION_PLACES: places,
            COLLECTION_RESTAURANTS: restaurants,
            COLLECTION_HOTELS: hotels,
        }


# ──────────────────────────────────────────
# Dependency Injection cho FastAPI
# ──────────────────────────────────────────

def get_db_service(
    openai_client: AsyncOpenAI = Depends(get_openai_client),
) -> DBService:
    return DBService(openai_client=openai_client)
