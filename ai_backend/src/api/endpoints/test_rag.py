"""
Endpoint test nhanh RAG pipeline.
Cho phép gọi trực tiếp vector search mà KHÔNG đi qua AI orchestrator,
để kiểm tra kết quả retrieval từ MongoDB Atlas Vector Search.

URL: POST /api/trip/test-rag
"""

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field, ConfigDict, model_validator
from pydantic.alias_generators import to_camel
from typing import List, Dict, Any, Optional

from src.services.trip_generator.db_service import DBService, get_db_service

MIN_BUDGET_PER_TRAVELER_DAY = 200_000
MAX_BUDGET_PER_TRAVELER_DAY = 200_000_000


router = APIRouter()


# ── Request / Response riêng cho test RAG ──

class CamelModel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class TestRAGRequest(CamelModel):
    """
    Body request đơn giản để test RAG.
    """
    query: str = Field(
        ...,
        description="Chuỗi text mô tả sở thích, sẽ được chuyển thành embedding. "
                    "VD: 'chùa, văn hóa, ẩm thực địa phương, cảnh đẹp'"
    )
    destinations: Optional[List[str]] = Field(
        default=None,
        description="Lọc theo thành phố. VD: ['Châu Đốc', 'Cà Mau']. "
                    "Để null nếu muốn search toàn quốc."
    )
    budget_level: Optional[int] = Field(
        default=None,
        description="Mức ngân sách cụ thể (số nguyên VND). VD: 1000000, 2000000. "
                    "Để null nếu không muốn filter giá."
    )
    total_days: int = Field(
        default=2,
        ge=1,
        le=7,
        description="Tổng số ngày đi để tính toán ngân sách"
    )
    adults: int = Field(
        default=1,
        ge=1,
        description="Số người lớn"
    )
    children: int = Field(
        default=0,
        ge=0,
        description="Số trẻ em"
    )

    @model_validator(mode='after')
    def validate_total_travelers(self) -> 'TestRAGRequest':
        if self.adults + self.children > 5:
            raise ValueError("Tổng số người tham gia chuyến đi tối đa là 5")
        if self.budget_level is not None:
            total_travelers = self.adults + self.children
            min_budget = total_travelers * self.total_days * MIN_BUDGET_PER_TRAVELER_DAY
            max_budget = total_travelers * self.total_days * MAX_BUDGET_PER_TRAVELER_DAY
            if not min_budget <= self.budget_level <= max_budget:
                raise ValueError(
                    f"Ngân sách phải nằm trong khoảng {min_budget:,} - {max_budget:,} VND"
                )
        return self

    top_k: int = Field(
        default=5,
        ge=1,
        le=50,
        description="Số kết quả mỗi collection (1-50)"
    )


class TestRAGResponse(CamelModel):
    """
    Trả về kết quả RAG thô từ 3 collection.
    """
    query: str
    embedding_model: str
    results: Dict[str, Any] = Field(
        description="Dict chứa kết quả từ 3 collection: places, restaurants, hotels"
    )
    total_results: int = Field(
        description="Tổng số documents trả về từ cả 3 collection"
    )


@router.post(
    "/test-rag",
    response_model=TestRAGResponse,
    response_model_by_alias=True,
    summary="Test RAG Pipeline",
    description="Endpoint test nhanh RAG: sinh embedding → vector search → trả kết quả thô."
)
async def test_rag(
    request: TestRAGRequest,
    db_service: DBService = Depends(get_db_service),
):
    """
    Test nhanh RAG pipeline mà không cần qua AI orchestrator.
    Trả về danh sách documents thô từ MongoDB Atlas Vector Search.
    """
    print(f"\n{'='*60}")
    print(f"[TEST-RAG] Query: {request.query}")
    print(f"[TEST-RAG] Destinations: {request.destinations}")
    print(f"[TEST-RAG] Budget: {request.budget_level}")
    print(f"[TEST-RAG] Total Days: {request.total_days}")
    print(f"[TEST-RAG] Adults: {request.adults} | Children: {request.children}")
    print(f"[TEST-RAG] Top-K: {request.top_k}")
    print(f"{'='*60}")

    results = await db_service.vector_search_all(
        query_text=request.query,
        top_k=request.top_k,
        city_filter=request.destinations,
        budget_level=request.budget_level,
        total_days=request.total_days,
        adults=request.adults,
        children=request.children,
    )

    # Đếm tổng
    total = sum(len(docs) for docs in results.values())

    print(f"[TEST-RAG] ✅ Hoàn tất! Tổng: {total} documents.")

    return TestRAGResponse(
        query=request.query,
        embedding_model=db_service.embedding_model,
        results=results,
        total_results=total,
    )
