from pydantic import BaseModel, Field, ConfigDict
from pydantic.alias_generators import to_camel
from typing import List, Optional


# Base model chung: tự chuyển snake_case (Python) sang camelCase (JSON)
class CamelModel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


# --- Sub-models dùng lại từ Request (echo lại input) ---

class Travelers(CamelModel):
    adults: int = Field(..., description="Số người lớn")
    children: int = Field(default=0, description="Số trẻ em")


class Preferences(CamelModel):
    budget_level: int = Field(..., description="Mức ngân sách (số nguyên VND)")
    interests: List[str] = Field(default_factory=list, description="Danh sách sở thích")
    transport_mode: str = Field(default="auto", description="Phương tiện di chuyển")
    pace: str = Field(default="relaxed", description="Nhịp độ")


# --- Estimated Cost ---

class EstimatedCost(CamelModel):
    min: int = Field(..., description="Chi phí tối thiểu ước tính")
    max: int = Field(..., description="Chi phí tối đa ước tính")
    currency: str = Field(default="VND", description="Đơn vị tiền tệ")
    note: Optional[str] = Field(default=None, description="Ghi chú chi phí")


# --- GeoJSON Location ---

class GeoLocation(CamelModel):
    type: str = Field(default="Point", description="Loại GeoJSON (luôn là 'Point')")
    coordinates: List[float] = Field(
        ...,
        min_length=2,
        max_length=2,
        description="[longitude, latitude]"
    )


# --- Data Source (truy xuất nguồn gốc địa điểm) ---

class DataSource(CamelModel):
    provider: str = Field(
        ...,
        description="Nguồn dữ liệu: 'database' hoặc 'ai_generated'"
    )
    collection: Optional[str] = Field(
        default=None,
        description="Tên collection trong MongoDB (nếu provider='database')"
    )
    id: Optional[str] = Field(
        default=None,
        description="Object ID trong MongoDB (nếu provider='database')"
    )


# --- Day Item (mỗi hoạt động trong 1 ngày) ---

class DayItem(CamelModel):
    order: int = Field(..., description="Thứ tự hoạt động trong ngày")
    type: str = Field(
        ...,
        description="Loại: 'place', 'restaurant', 'hotel', 'transport', ..."
    )
    title: str = Field(..., description="Tên hoạt động / địa điểm")
    category: str = Field(..., description="Phân loại: Tâm linh, Ẩm thực, ...")
    start_time: str = Field(..., description="Giờ bắt đầu (HH:MM)")
    end_time: str = Field(..., description="Giờ kết thúc (HH:MM)")
    notes: Optional[str] = Field(default=None, description="Ghi chú gợi ý")
    estimated_cost: Optional[EstimatedCost] = Field(
        default=None,
        description="Chi phí ước tính cho hoạt động (nếu có)"
    )
    location: Optional[GeoLocation] = Field(
        default=None,
        description="Tọa độ GeoJSON của địa điểm"
    )
    source: DataSource = Field(
        ...,
        description="Nguồn dữ liệu của item"
    )


# --- Day (1 ngày trong lịch trình) ---

class Day(CamelModel):
    day_number: int = Field(..., description="Ngày thứ mấy trong tour")
    date: Optional[str] = Field(
        default=None,
        description="Ngày cụ thể (YYYY-MM-DD), có thể null nếu chưa xác định"
    )
    title: str = Field(..., description="Tiêu đề của ngày")
    summary: str = Field(..., description="Tóm tắt hoạt động trong ngày")
    items: List[DayItem] = Field(..., description="Danh sách hoạt động trong ngày")


# --- AI Metadata ---

class RetrievalInfo(CamelModel):
    strategy: str = Field(..., description="Chiến lược truy xuất: vector_search, ...")
    index: str = Field(..., description="Tên index được sử dụng")
    top_k: int = Field(..., description="Số kết quả top-K lấy ra")


class AIMetadata(CamelModel):
    generated_by: str = Field(default="ai_backend", description="Hệ thống sinh ra")
    model: str = Field(..., description="Model LLM được sử dụng")
    embedding_model: Optional[str] = Field(
        default=None,
        description="Model embedding (nếu dùng RAG)"
    )
    retrieval: Optional[RetrievalInfo] = Field(
        default=None,
        description="Thông tin RAG retrieval (nếu dùng)"
    )


# --- Response chính ---

class TripGeneratorResponse(CamelModel):
    title: str = Field(..., description="Tiêu đề chuyến đi")
    destinations: List[str] = Field(..., description="Danh sách điểm đến")
    total_days: int = Field(..., description="Tổng số ngày")
    total_nights: int = Field(..., description="Tổng số đêm")
    travelers: Travelers = Field(..., description="Thông tin hành khách")
    preferences: Preferences = Field(..., description="Sở thích đã dùng để sinh")
    estimated_cost: EstimatedCost = Field(..., description="Chi phí ước tính tổng")
    days: List[Day] = Field(..., description="Lịch trình từng ngày")
    ai: AIMetadata = Field(..., description="Metadata AI engine")