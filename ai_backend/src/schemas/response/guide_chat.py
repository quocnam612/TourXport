from pydantic import BaseModel, Field
from typing import Optional, Literal, List
from uuid import UUID

class Message(BaseModel):
    role: Literal["user", "assistant"]
    content: str
    time_sent: int

class GuideChatResponse(BaseModel):
    session_id: UUID
    latest_reply: str