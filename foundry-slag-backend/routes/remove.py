import asyncio
import json
from pathlib import Path
import shutil
import time

from fastapi import APIRouter, File, Form, HTTPException, Request, UploadFile
from fastapi.responses import StreamingResponse

from config import (
    DEFAULT_ALPHA_MATTING,
    DEFAULT_MODEL,
    MAX_BATCH_SIZE,
    OUTPUT_DIR,
    SUPPORTED_MODELS,
    THUMBNAILS_DIR,
)
from database import create_image, create_job, execute, fetch_all, fetch_one, now_iso
from image_processing import create_thumbnail, validate_image

router = APIRouter(tags=["remove"])


def image_payload(row: dict) -> dict:
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


async def _process_one(request: Request, image_id: str, input_path: str, alpha_matting: bool):
    out = OUTPUT_DIR / f"{image_id}.png"
    result = await request.app.state.engine.remove_background(input_path, str(out), alpha_matting=alpha_matting)
    thumb = THUMBNAILS_DIR / f"{image_id}.png"
    create_thumbnail(str(out), str(thumb))
    await execute(
        """
        UPDATE images SET status='completed', output_path=?, raw_output_path=?, output_width=?, output_height=?,
            output_file_size_bytes=?, processing_time_seconds=?, thumbnail_path=?, completed_at=? WHERE id=?
        """,
        (
            result["output_path"],
            result["output_path"],
            result["output_width"],
            result["output_height"],
            result["output_file_size_bytes"],
            result["processing_time_seconds"],
            str(thumb),
            now_iso(),
            image_id,
        ),
    )
    return result


@router.post("/remove")
async def remove_single(request: Request, file: UploadFile = File(...), model: str = Form(DEFAULT_MODEL), alpha_matting: bool = Form(DEFAULT_ALPHA_MATTING)):
    if not request.app.state.engine.loaded:
        raise HTTPException(status_code=503, detail={"error": "model_not_loaded", "message": "Model still loading", "details": {}})
    if model not in SUPPORTED_MODELS:
        raise HTTPException(status_code=400, detail={"error": "invalid_setting", "message": "Unsupported model", "details": {"model": model}})
    if model != request.app.state.engine.model_name:
        await request.app.state.engine.switch_model(model)

    job_id = await create_job("single", model, 1)
    image_id = None
    input_path = OUTPUT_DIR.parent / "input" / f"{job_id}_{file.filename}"
    with input_path.open("wb") as w:
        shutil.copyfileobj(file.file, w)

    val = validate_image(str(input_path))
    if not val["valid"]:
        raise HTTPException(status_code=400, detail={"error": "invalid_image", "message": val["error"], "details": {}})

    image_id = await create_image(job_id, file.filename, str(input_path), val)
    await execute("UPDATE jobs SET status='processing', started_at=? WHERE id=?", (now_iso(), job_id))
    await execute("UPDATE images SET status='processing' WHERE id=?", (image_id,))

    try:
        request.app.state.queue_length += 1
        start = time.time()
        await _process_one(request, image_id, str(input_path), alpha_matting)
        await execute(
            "UPDATE jobs SET status='completed', completed_images=1, processing_time_seconds=?, completed_at=? WHERE id=?",
            (time.time() - start, now_iso(), job_id),
        )
    except Exception as exc:
        await execute("UPDATE images SET status='failed', error_message=? WHERE id=?", (str(exc), image_id))
        await execute("UPDATE jobs SET status='failed', failed_images=1, error_message=?, completed_at=? WHERE id=?", (str(exc), now_iso(), job_id))
        raise
    finally:
        request.app.state.queue_length -= 1

    row = await fetch_one("SELECT * FROM images WHERE id=?", (image_id,))
    return {"image": image_payload(row)}


async def process_batch(request: Request, job_id: str, image_rows: list[dict], alpha_matting: bool):
    queue = request.app.state.sse_queues.setdefault(job_id, asyncio.Queue())
    await execute("UPDATE jobs SET status='processing', started_at=? WHERE id=?", (now_iso(), job_id))
    start = time.time()
    completed = 0
    failed = 0
    for idx, row in enumerate(image_rows, start=1):
        try:
            await execute("UPDATE images SET status='processing' WHERE id=?", (row["id"],))
            result = await _process_one(request, row["id"], row["input_path"], alpha_matting)
            completed += 1
            await queue.put(("image_complete", {"image_id": row["id"], "index": idx, "total": len(image_rows), "processing_time": result["processing_time_seconds"]}))
        except Exception as exc:
            failed += 1
            await execute("UPDATE images SET status='failed', error_message=? WHERE id=?", (str(exc), row["id"]))
            await queue.put(("image_failed", {"image_id": row["id"], "index": idx, "total": len(image_rows), "error": str(exc)}))
        await execute("UPDATE jobs SET completed_images=?, failed_images=? WHERE id=?", (completed, failed, job_id))
    total_time = time.time() - start
    status = "completed" if failed == 0 else "failed"
    await execute("UPDATE jobs SET status=?, processing_time_seconds=?, completed_at=? WHERE id=?", (status, total_time, now_iso(), job_id))
    await queue.put(("batch_complete", {"job_id": job_id, "completed": completed, "failed": failed, "total_time": total_time}))


@router.post("/remove/batch", status_code=202)
async def remove_batch(request: Request, files: list[UploadFile] = File(...), model: str = Form(DEFAULT_MODEL), alpha_matting: bool = Form(DEFAULT_ALPHA_MATTING)):
    if len(files) > MAX_BATCH_SIZE:
        raise HTTPException(status_code=400, detail={"error": "batch_too_large", "message": "Batch exceeds max size", "details": {"max": MAX_BATCH_SIZE}})
    job_id = await create_job("batch", model, len(files))
    image_rows = []
    for f in files:
        input_path = OUTPUT_DIR.parent / "input" / f"{job_id}_{f.filename}"
        with input_path.open("wb") as w:
            shutil.copyfileobj(f.file, w)
        val = validate_image(str(input_path))
        if not val["valid"]:
            continue
        image_id = await create_image(job_id, f.filename, str(input_path), val)
        image_rows.append({"id": image_id, "input_path": str(input_path)})

    request.app.state.sse_queues = getattr(request.app.state, "sse_queues", {})
    asyncio.create_task(process_batch(request, job_id, image_rows, alpha_matting))
    return {"job": {"id": job_id, "status": "processing", "mode": "batch", "total_images": len(image_rows), "completed_images": 0, "failed_images": 0, "created_at": now_iso()}}


@router.get("/remove/batch/{job_id}")
async def get_batch_status(job_id: str):
    job = await fetch_one("SELECT * FROM jobs WHERE id=?", (job_id,))
    if not job:
        raise HTTPException(status_code=404, detail={"error": "job_not_found", "message": "Job not found", "details": {}})
    imgs = await fetch_all("SELECT * FROM images WHERE job_id=? ORDER BY created_at", (job_id,))
    return {"job": job, "images": [image_payload(i) for i in imgs]}


@router.get("/remove/batch/{job_id}/progress")
async def batch_progress(request: Request, job_id: str):
    request.app.state.sse_queues = getattr(request.app.state, "sse_queues", {})
    q = request.app.state.sse_queues.setdefault(job_id, asyncio.Queue())

    async def event_stream():
        while True:
            event, data = await q.get()
            yield f"event: {event}\ndata: {json.dumps(data)}\n\n"
            if event == "batch_complete":
                break

    return StreamingResponse(event_stream(), media_type="text/event-stream")
