from pydantic import BaseModel, Field

class TripGenerateRequest(BaseModel):
    budget: float = Field(
        ..., 
        gt=0, 
        description="Ngân sách tối đa cho chuyến đi (VND)"
    )
    duration_days: int = Field(
        ..., 
        ge=1, 
        le=30, 
        description="Số ngày đi du lịch (từ 1 đến 30 ngày)"
    )
    preferences: str = Field(
        ..., 
        min_length=10, 
        description="Sở thích, yêu cầu cụ thể. Yêu cầu nhập đủ dài để chuyển thành Vector chính xác"
    )

    class Config:
        json_schema_extra = {
            "example": {
                "budget": 5000000,
                "duration_days": 3,
                "preferences": "biển, ăn hải sản, nhịp độ chậm rãi, không hối hả."
            }
        }