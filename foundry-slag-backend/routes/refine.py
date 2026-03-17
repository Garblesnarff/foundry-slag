from pathlib import Path

from fastapi import APIRouter, HTTPException
from PIL import Image

from database import execute, fetch_one, now_iso
from image_processing import apply_background, apply_drop_shadow, apply_edge_refinement, create_thumbnail
from models import RefinementPayload

router = APIRouter(tags=["refine"])


def serialize_image(row: dict) -> dict:
    return {
        "id": row["id"],
        "job_id": row["job_id"],
        "status": row["status"],
        "original_filename": row["original_filename"],
        "input_width": row.get("input_width"),
        "input_height": row.get("input_height"),
        "output_width": row.get("output_width"),
        "output_height": row.get("output_height"),
        "output_file_size_bytes": row.get("output_file_size_bytes"),
        "processing_time_seconds": row.get("processing_time_seconds"),
        "original_url": f"/api/v1/images/{row['id']}/original",
        "result_url": f"/api/v1/images/{row['id']}/result",
        "thumbnail_url": f"/api/v1/images/{row['id']}/thumbnail",
        "created_at": row["created_at"],
    }


@router.post("/refine/{image_id}")
async def refine_image(image_id: str, payload: RefinementPayload):
    row = await fetch_one("SELECT * FROM images WHERE id=?", (image_id,))
    if not row:
        raise HTTPException(404, detail={"error": "image_not_found", "message": "Image not found", "details": {}})
    source = row.get("raw_output_path") or row.get("output_path")
    if not source:
        raise HTTPException(400, detail={"error": "invalid_refinement", "message": "Image has no output to refine", "details": {}})

    img = Image.open(source).convert("RGBA")
    img = apply_edge_refinement(img, payload.edge_feather, payload.edge_shift)
    if payload.shadow_enabled:
        img = apply_drop_shadow(img, payload.shadow_opacity, payload.shadow_offset_x, payload.shadow_offset_y, payload.shadow_blur)
    img = apply_background(img, payload.bg_type, payload.bg_color, payload.bg_image_path)

    output_path = Path(source).with_name(f"{image_id}_refined.png")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(output_path, "PNG", optimize=True)
    thumb = Path(row["thumbnail_path"]) if row.get("thumbnail_path") else output_path.with_name(f"{image_id}_thumb.png")
    create_thumbnail(str(output_path), str(thumb))

    await execute(
        """
        UPDATE images SET output_path=?, output_width=?, output_height=?, output_file_size_bytes=?,
            edge_feather=?, edge_shift=?, bg_type=?, bg_color=?, bg_image_path=?, shadow_enabled=?,
            shadow_opacity=?, shadow_offset_x=?, shadow_offset_y=?, shadow_blur=?, thumbnail_path=?, completed_at=?
        WHERE id=?
        """,
        (
            str(output_path), img.width, img.height, output_path.stat().st_size,
            payload.edge_feather, payload.edge_shift, payload.bg_type, payload.bg_color, payload.bg_image_path,
            int(payload.shadow_enabled), payload.shadow_opacity, payload.shadow_offset_x, payload.shadow_offset_y,
            payload.shadow_blur, str(thumb), now_iso(), image_id,
        ),
    )
    updated = await fetch_one("SELECT * FROM images WHERE id=?", (image_id,))
    return {"image": serialize_image(updated)}


@router.post("/refine/{image_id}/reset")
async def reset_refinement(image_id: str):
    row = await fetch_one("SELECT * FROM images WHERE id=?", (image_id,))
    if not row:
        raise HTTPException(404, detail={"error": "image_not_found", "message": "Image not found", "details": {}})
    raw = row.get("raw_output_path")
    if not raw:
        raise HTTPException(400, detail={"error": "invalid_refinement", "message": "Raw image unavailable", "details": {}})
    await execute(
        """
        UPDATE images SET output_path=raw_output_path, edge_feather=0, edge_shift=0, bg_type='transparent',
        bg_color='#FFFFFF', bg_image_path=NULL, shadow_enabled=0, shadow_opacity=0.3,
        shadow_offset_x=5, shadow_offset_y=5, shadow_blur=10 WHERE id=?
        """,
        (image_id,),
    )
    updated = await fetch_one("SELECT * FROM images WHERE id=?", (image_id,))
    return {"image": serialize_image(updated)}
