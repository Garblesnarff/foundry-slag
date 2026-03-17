from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

from database import fetch_one

router = APIRouter(tags=["images"])


def get_image_or_404(row):
    if not row:
        raise HTTPException(404, detail={"error": "image_not_found", "message": "Image not found", "details": {}})


@router.get("/images/{image_id}/original")
async def get_original(image_id: str):
    row = await fetch_one("SELECT input_path, input_format FROM images WHERE id=?", (image_id,))
    get_image_or_404(row)
    return FileResponse(row["input_path"])


@router.get("/images/{image_id}/result")
async def get_result(image_id: str):
    row = await fetch_one("SELECT output_path FROM images WHERE id=?", (image_id,))
    get_image_or_404(row)
    return FileResponse(row["output_path"], headers={"Accept-Ranges": "bytes"})


@router.get("/images/{image_id}/thumbnail")
async def get_thumbnail(image_id: str):
    row = await fetch_one("SELECT thumbnail_path FROM images WHERE id=?", (image_id,))
    get_image_or_404(row)
    return FileResponse(row["thumbnail_path"])


@router.get("/images/{image_id}/compare")
async def compare(image_id: str):
    row = await fetch_one("SELECT * FROM images WHERE id=?", (image_id,))
    get_image_or_404(row)
    return {
        "original_url": f"/api/v1/images/{image_id}/original",
        "result_url": f"/api/v1/images/{image_id}/result",
        "input_dimensions": {"width": row["input_width"], "height": row["input_height"]},
        "output_dimensions": {"width": row["output_width"], "height": row["output_height"]},
    }
