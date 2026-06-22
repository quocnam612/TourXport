from pydantic import BaseModel, Field
from uuid import UUID

class GuideChatRequest(BaseModel):
    session_id: UUID = Field(
        ..., # khong duoc trong
        description="ID phiên chat do Backend trung tâm sinh ra. Chuẩn UUIDv4."
    )
    content: str = Field(
        ...,
        min_length=1,
        max_length=1000,
        description="Văn bản tin nhắn của user."
    )