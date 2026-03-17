from pathlib import Path

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse
from PIL import Image

from config import OUTPUT_DIR
from database import fetch_all, fetch_one
from image_processing import create_batch_zip, export_image
from models import BatchExportPayload, ExportPayload

router = APIRouter(tags=["export"])


@router.post("/export/{image_id}")
async def export_single(image_id: str, payload: ExportPayload):
    row = await fetch_one("SELECT * FROM images WHERE id=?", (image_id,))
    if not row:
        raise HTTPException(404, detail={"error": "image_not_found", "message": "Image not found", "details": {}})
    path = row["output_path"] if payload.apply_refinements else row.get("raw_output_path")
    img = Image.open(path)
    out = OUTPUT_DIR / f"{image_id}_export.{payload.format}"
    export_image(img, str(out), payload.format, payload.quality)
    media = "application/octet-stream"
    return FileResponse(out, filename=out.name, media_type=media)


@router.post("/export/batch")
async def export_batch(payload: BatchExportPayload):
    rows = []
    for image_id in payload.image_ids:
        row = await fetch_one("SELECT * FROM images WHERE id=?", (image_id,))
        if row:
            rows.append(row)
    entries = []
    for row in rows:
        src = row["output_path"] if payload.apply_refinements else row.get("raw_output_path")
        img = Image.open(src)
        filename = f"{Path(row['original_filename']).stem}.{payload.format}"
        out_path = OUTPUT_DIR / f"{row['id']}_batch_export.{payload.format}"
        export_image(img, str(out_path), payload.format)
        entries.append({"filename": filename, "path": str(out_path)})
    zip_path = create_batch_zip(entries, str(OUTPUT_DIR))
    return FileResponse(zip_path, filename=Path(zip_path).name, media_type="application/zip")
