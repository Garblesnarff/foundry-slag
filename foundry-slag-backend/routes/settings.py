from fastapi import APIRouter, HTTPException, Request

from config import SUPPORTED_MODELS, SUPPORTED_OUTPUT_FORMATS
from database import get_settings, update_setting_values
from models import SettingsPatch

router = APIRouter(tags=["settings"])


@router.get("/settings")
async def read_settings():
    return await get_settings()


@router.patch("/settings")
async def patch_settings(request: Request, payload: SettingsPatch):
    patch = {k: v for k, v in payload.model_dump().items() if v is not None}
    if "model" in patch and patch["model"] not in SUPPORTED_MODELS:
        raise HTTPException(400, detail={"error": "invalid_setting", "message": "Unsupported model", "details": {}})
    if "output_format" in patch and patch["output_format"] not in SUPPORTED_OUTPUT_FORMATS:
        raise HTTPException(400, detail={"error": "invalid_setting", "message": "Unsupported output format", "details": {}})
    if "model" in patch:
        await request.app.state.engine.switch_model(patch["model"])
    await update_setting_values(patch)
    return await get_settings()
