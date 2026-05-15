from openai import AsyncOpenAI
from src.core.config import settings

client = AsyncOpenAI(api_key=settings.openai_api_key)

async def get_openai_client() -> AsyncOpenAI:
    """
    Dependency Injection để lấy OpenAI Client.
    Sử dụng trong FastAPI route: client = Depends(get_openai_client)
    """
    return client