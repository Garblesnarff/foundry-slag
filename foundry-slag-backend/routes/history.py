from pathlib import Path

from fastapi import APIRouter, Query

from database import execute, fetch_all, fetch_one

router = APIRouter(tags=["history"])


@router.get("/history")
async def get_history(search: str | None = None, sort: str = "newest", limit: int = 50, offset: int = 0):
    order = {
        "newest": "created_at DESC",
        "oldest": "created_at ASC",
        "largest": "output_file_size_bytes DESC",
        "smallest": "output_file_size_bytes ASC",
    }.get(sort, "created_at DESC")
    where = "WHERE 1=1"
    params: list = []
    if search:
        where += " AND original_filename LIKE ?"
        params.append(f"%{search}%")
    params.extend([limit, offset])
    rows = await fetch_all(f"SELECT * FROM images {where} ORDER BY {order} LIMIT ? OFFSET ?", tuple(params))
    return {"images": rows}


@router.get("/history/stats")
async def history_stats():
    rows = await fetch_all("SELECT processing_time_seconds FROM images WHERE status='completed'")
    total = sum((r["processing_time_seconds"] or 0) for r in rows)
    count = len(rows)
    avg = total / count if count else 0
    return {
        "session": {"images_processed": count, "total_processing_seconds": round(total, 2), "avg_time_per_image": round(avg, 2)},
        "lifetime": {"images_processed": count, "total_processing_seconds": round(total, 2), "avg_time_per_image": round(avg, 2)},
    }


@router.delete("/history/{image_id}")
async def delete_history_item(image_id: str):
    row = await fetch_one("SELECT * FROM images WHERE id=?", (image_id,))
    if not row:
        return {"deleted": False}
    for key in ["input_path", "output_path", "raw_output_path", "thumbnail_path"]:
        p = row.get(key)
        if p:
            Path(p).unlink(missing_ok=True)
    await execute("DELETE FROM images WHERE id=?", (image_id,))
    return {"deleted": True}


@router.delete("/history")
async def clear_history():
    rows = await fetch_all("SELECT * FROM images")
    for row in rows:
        for key in ["input_path", "output_path", "raw_output_path", "thumbnail_path"]:
            p = row.get(key)
            if p:
                Path(p).unlink(missing_ok=True)
    await execute("DELETE FROM images")
    await execute("DELETE FROM jobs")
    return {"deleted": len(rows)}
