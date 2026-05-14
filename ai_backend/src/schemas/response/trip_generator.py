from pydantic import BaseModel, Field, ConfigDict, model_validator
from pydantic.alias_generators import to_camel
from typing import List, Optional


# chuyen tu snake_case (python) sang camelCase (js)
class CamelModel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class Location(CamelModel):
    time_slot: str = Field(..., description="Sáng/Chiều/Tối")
    rationale: str = Field(..., description="Lý do AI chọn địa điểm này")
    estimated_cost: float = Field(..., description="Chi phí dự kiến")
    
    place_id: Optional[str] = Field(
        default=None, 
        description="ID trong MongoDB. Trả về null nếu AI tự tạo địa điểm."
    )
    place_name: Optional[str] = Field(
        default=None, 
        description="Tên địa điểm. BẮT BUỘC LLM phải điền nếu place_id bị null."
    )

    @model_validator(mode='after')
    def check_place_reference(self) -> 'Location':
        if not self.place_id and not self.place_name:
            raise ValueError('Phải có ít nhất place_id (từ DB) hoặc place_name (AI tự tạo)')
        return self


class DailyItinerary(CamelModel):
    day: int = Field(..., description="Ngày thứ mấy")
    activities: List[Location] = Field(..., description="Danh sách hoạt động")


class TripData(CamelModel):
    is_from_db: bool = Field(..., description="True nếu 100% địa điểm lấy từ DB, False nếu AI tự tạo 100% địa điểm.")
    total_estimated_cost: float
    itinerary: List[DailyItinerary]


class TripGeneratorResponse(CamelModel):
    status: str = Field(default="success")
    data: TripData