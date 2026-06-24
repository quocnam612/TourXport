from pymongo import AsyncMongoClient
from openai import AsyncOpenAI
from uuid import UUID

class GuideChatService:
    _db_client: AsyncMongoClient
    _openai_client: AsyncOpenAI
    _system_prompt = """
        (System Prompt đang để lại nghiên cứu vaf viết sao cho tốt nhất)
    """

    def __init__(self, db_client, openai_client):
        self._db_client = db_client
        self._openai_client = openai_client
    
    def _get_or_create_history(session_id: UUID):
        
        pass