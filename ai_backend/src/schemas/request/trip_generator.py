from pydantic import BaseModel, Field, model_validator
from pydantic import ConfigDict
from pydantic.alias_generators import to_camel
from typing import List, Optional, Union, Literal

MIN_BUDGET_PER_TRAVELER_DAY = 200_000
MAX_BUDGET_PER_TRAVELER_DAY = 200_000_000


# Base model chung: tự chuyển snake_case (Python) sang camelCase (JSON)
class CamelModel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class Travelers(CamelModel):
    adults: int = Field(default=1, ge=1, description="Số người lớn")
    children: int = Field(default=0, ge=0, description="Số trẻ em")

    @model_validator(mode='after')
    def validate_total_travelers(self) -> 'Travelers':
        if self.adults + self.children > 5:
            raise ValueError("Tổng số người tham gia chuyến đi tối đa là 5")
        return self


class Preferences(CamelModel):
    budget_level: int = Field(
        default=2000000,
        description="Mức ngân sách cụ thể (số nguyên VND), VD: 1000000, 2000000"
    )
    interests: List[str] = Field(
        default_factory=list,
        description="Danh sách sở thích, VD: ['temple', 'culture', 'local food']"
    )
    transport_mode: str = Field(
        default="auto",
        description="Phương tiện di chuyển: auto / motorbike / car / public"
    )
    pace: str = Field(
        default="relaxed",
        description="Nhịp độ: relaxed / moderate / packed"
    )


class TripGenerateRequest(CamelModel):
    destinations: Union[List[str], Literal["auto"]] = Field(
        ...,
        description="Danh sách điểm đến hoặc 'auto' để AI tự chọn"
    )
    total_days: int = Field(
        ...,
        ge=1,
        le=7,
        description="Tổng số ngày (1-7)"
    )
    total_nights: Optional[int] = Field(
        default=None,
        ge=0,
        le=7,
        description="Tổng số đêm. Nếu không truyền sẽ = totalDays - 1"
    )
    travelers: Travelers = Field(
        default_factory=Travelers,
        description="Thông tin hành khách. Mặc định 1 người lớn"
    )
    preferences: Preferences = Field(
        default_factory=Preferences,
        description="Sở thích & tùy chọn cho chuyến đi"
    )

    @model_validator(mode='after')
    def validate_trip_limits(self) -> 'TripGenerateRequest':
        if self.total_nights is None:
            self.total_nights = max(self.total_days - 1, 0)

        total_travelers = self.travelers.adults + self.travelers.children
        min_budget = total_travelers * self.total_days * MIN_BUDGET_PER_TRAVELER_DAY
        max_budget = total_travelers * self.total_days * MAX_BUDGET_PER_TRAVELER_DAY
        if not min_budget <= self.preferences.budget_level <= max_budget:
            raise ValueError(
                f"Ngân sách phải nằm trong khoảng {min_budget:,} - {max_budget:,} VND"
            )

        return self

    class Config:
        json_schema_extra = {
            "example": {
                "destinations": ["Châu Đốc", "Cà Mau", "Rạch Giá"],
                "totalDays": 2,
                "totalNights": 1,
                "travelers": {
                    "adults": 2,
                    "children": 0
                },
                "preferences": {
                    "budgetLevel": 2000000,
                    "interests": ["temple", "culture", "local food", "scenic view"],
                    "transportMode": "auto",
                    "pace": "relaxed"
                }
            }
        }
