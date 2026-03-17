from fastapi import APIRouter, Request

router = APIRouter(tags=["health"])


@router.get("/health")
async def get_health(request: Request):
    engine = request.app.state.engine
    return {
        "status": request.app.state.status,
        "model": engine.model_name,
        "model_loaded": engine.loaded,
        "processing": engine.processing,
        "queue_length": request.app.state.queue_length,
        "platform": request.app.state.platform,
    }
