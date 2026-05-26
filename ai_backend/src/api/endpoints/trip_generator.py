from fastapi import APIRouter, Depends
from src.core.security import verify_token
from src.schemas.request.trip_generator import TripGenerateRequest
from src.schemas.response.trip_generator import TripGeneratorResponse
from src.services.trip_generator.ai_orchestrator import TripOrchestrator, get_trip_orchestrator

router = APIRouter()

@router.post("/generate", response_model=TripGeneratorResponse, response_model_by_alias=True)
async def generate_trip(
    request_data: TripGenerateRequest,
    orchestrator: TripOrchestrator = Depends(get_trip_orchestrator),
    token_data: dict = Depends(verify_token)
):
    """
    API tạo lịch trình du lịch.
    Mọi logic quyết định (DB hay AI) đều được xử lý ngầm trong Orchestrator.
    """
    
    result = await orchestrator.execute(request_data)
    
    return result