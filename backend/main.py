"""
Foundry Slag — Background Remover API

FastAPI application entry point. Implements background removal endpoints with:
- Single image processing
- Batch processing with SSE progress
- Model management and auto-download
- SQLite history and settings
- CORS for frontend communication

See ../CLAUDE.md for technical overview.
See ../PRD.md for product specification.
See ../docs/API_SPEC.md for full API specification.
"""

import os
import io
import json
import zipfile
import hashlib
from pathlib import Path

from fastapi import FastAPI, UploadFile, File, Form, Query, Path as PathParam
from fastapi.responses import Response, StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from database import get_database, close_database
from engine import get_engine, AVAILABLE_MODELS
from utils import (
    validate_image,
    apply_feather_and_shift,
    export_image,
    image_to_base64,
)
from models import (
    HealthResponse,
    SlagResponse,
    BatchProgressEvent,
    ModelsResponse,
    ModelDownloadResponse,
    HistoryListResponse,
    SettingsResponse,
    ErrorResponse,
    ExportBatchRequest,
)


# Configuration
API_VERSION = "0.1.0"
ALLOWED_ORIGINS = [
    "http://localhost:5175",  # Vite dev
    "http://localhost:3000",  # Alt dev
]


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager for startup/shutdown hooks.
    """
    # Startup
    print("Foundry Slag starting up...")
    
    # Initialize database
    await get_database()
    
    # Pre-initialize default model
    engine = get_engine()
    default_model = os.getenv("SLAG_MODEL", "u2net")
    print(f"Pre-loading default model: {default_model}")
    
    yield
    
    # Shutdown
    print("Foundry Slag shutting down...")
    await close_database()


app = FastAPI(
    title="Foundry Slag",
    description="Local, offline background removal API",
    version=API_VERSION,
    lifespan=lifespan,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==================== Health ====================


@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Check API availability."""
    return HealthResponse(status="ok", version=API_VERSION)


# ==================== Background Removal ====================


@app.post("/slag", response_model=SlagResponse)
async def remove_background(
    file: UploadFile = File(...),
    model: str = Form(default="u2net"),
    feather: int = Form(default=0),
    shift: int = Form(default=0),
):
    """
    Remove background from a single image.
    """
    # Validate model
    if model not in AVAILABLE_MODELS:
        raise ErrorResponse(error="invalid-model", message=f"Unknown model: {model}")
    
    # Read file
    image_data = await file.read()
    
    # Validate image
    is_valid, error = validate_image(image_data)
    if not is_valid:
        raise ErrorResponse(error="invalid-image", message=error)
    
    # Compute hash for dedup
    original_hash = hashlib.sha256(image_data).hexdigest()
    
    # Get engine and database
    engine = get_engine()
    db = await get_database()
    
    # Get original as base64
    original_b64 = image_to_base64(image_data, f"image/{file.content_type or 'png'}")
    
    # Run inference
    result_png, processing_time = await engine.remove_background(image_data, model)
    
    # Apply edge refinement
    if feather > 0 or shift != 0:
        result_png = apply_feather_and_shift(result_png, feather, shift)
    
    # Save to history
    settings = {"feather": feather, "shift": shift}
    entry_id = await db.create_history_entry(
        original_filename=file.filename or "image",
        original_hash=original_hash,
        model_name=model,
        settings=settings,
        result_png=result_png,
        processing_time_ms=processing_time,
    )
    
    # Return response
    result_b64 = image_to_base64(result_png)
    
    return SlagResponse(
        id=entry_id,
        result=result_b64,
        original=original_b64,
        model=model,
        processingTimeMs=processing_time,
        settings=settings,
    )


@app.post("/slag/batch")
async def remove_background_batch(
    files: list[UploadFile] = File(...),
    model: str = Form(default="u2net"),
    feather: int = Form(default=0),
    shift: int = Form(default=0),
):
    """
    Batch remove backgrounds with SSE progress.
    """
    # Validate model
    if model not in AVAILABLE_MODELS:
        raise ErrorResponse(error="invalid-model", message=f"Unknown model: {model}")
    
    # Get engine and database
    engine = get_engine()
    db = await get_database()
    
    # Create batch set
    batch_set_id = await db.create_batch_set(name=f"Batch {len(files)} images")
    
    async def generate_sse():
        """Generate SSE events for batch progress."""
        total = len(files)
        completed = 0
        results = []
        
        for idx, file in enumerate(files):
            try:
                # Read file
                image_data = await file.read()
                
                # Validate image
                is_valid, error = validate_image(image_data)
                if not is_valid:
                    yield f"data: {json.dumps({'status': 'error', 'message': error})}\n\n"
                    continue
                
                # Compute hash
                original_hash = hashlib.sha256(image_data).hexdigest()
                
                # Run inference
                result_png, processing_time = await engine.remove_background(image_data, model)
                
                # Apply edge refinement
                if feather > 0 or shift != 0:
                    result_png = apply_feather_and_shift(result_png, feather, shift)
                
                # Save to history
                settings = {"feather": feather, "shift": shift, "batchSetId": batch_set_id}
                entry_id = await db.create_history_entry(
                    original_filename=file.filename or f"image_{idx}",
                    original_hash=original_hash,
                    model_name=model,
                    settings=settings,
                    result_png=result_png,
                    processing_time_ms=processing_time,
                    batch_set_id=batch_set_id,
                )
                
                completed += 1
                progress = int((completed / total) * 100)
                
                # Send progress event
                yield f"data: {json.dumps({
                    'status': 'processing',
                    'currentId': entry_id,
                    'completed': completed,
                    'total': total,
                    'progress': progress,
                })}\n\n"
                
                results.append({
                    "id": entry_id,
                    "originalFilename": file.filename or f"image_{idx}",
                    "model": model,
                    "processingTimeMs": processing_time,
                })
                
            except Exception as e:
                yield f"data: {json.dumps({'status': 'error', 'message': str(e)})}\n\n"
        
        # Send final completion event
        yield f"data: {json.dumps({
            'status': 'completed',
            'results': results,
        })}\n\n"
    
    return StreamingResponse(
        generate_sse(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


# ==================== Models ====================


@app.get("/slag/models", response_model=ModelsResponse)
async def list_models():
    """List available models."""
    engine = get_engine()
    return ModelsResponse(models=engine.list_models())


@app.post("/slag/models/{name}/download", response_model=ModelDownloadResponse)
async def download_model(name: str = PathParam(...)):
    """Download and cache a model."""
    if name not in AVAILABLE_MODELS:
        raise ErrorResponse(error="not-found", message=f"Model not found: {name}")
    
    engine = get_engine()
    result = await engine.download_model(name)
    return ModelDownloadResponse(**result)


# ==================== History ====================


@app.get("/history")
async def get_history(
    skip: int = Query(default=0, ge=0),
    limit: int = Query(default=50, ge=1, le=100),
    model: str | None = Query(default=None),
    startDate: str | None = Query(default=None),
    endDate: str | None = Query(default=None),
):
    """List processing history."""
    db = await get_database()
    entries, total = await db.get_history(
        skip=skip,
        limit=limit,
        model=model,
        start_date=startDate,
        end_date=endDate,
    )
    
    # Format entries for response
    formatted_entries = []
    for entry in entries:
        settings = json.loads(entry.get("settings", "{}"))
        formatted_entries.append({
            "id": entry["id"],
            "originalFilename": entry["original_filename"],
            "modelName": entry["model_name"],
            "processingTimeMs": entry["processing_time_ms"],
            "createdAt": entry["created_at"],
            "settings": settings,
            "batchSetId": entry.get("batch_set_id"),
        })
    
    return HistoryListResponse(
        entries=formatted_entries,
        total=total,
        skip=skip,
        limit=limit,
    )


@app.get("/history/{id}")
async def get_history_entry(id: str = PathParam(...)):
    """Get single history entry."""
    db = await get_database()
    entry = await db.get_history_entry(id)
    
    if not entry:
        raise ErrorResponse(error="not-found", message="History entry not found")
    
    settings = json.loads(entry.get("settings", "{}"))
    
    return {
        "id": entry["id"],
        "originalFilename": entry["original_filename"],
        "originalHash": entry.get("original_hash"),
        "modelName": entry["model_name"],
        "processingTimeMs": entry["processing_time_ms"],
        "createdAt": entry["created_at"],
        "settings": settings,
        "batchSetId": entry.get("batch_set_id"),
        "resultPath": f"/export/{id}/png",
    }


@app.delete("/history/{id}")
async def delete_history_entry(id: str = PathParam(...)):
    """Delete history entry."""
    db = await get_database()
    success = await db.delete_history_entry(id)
    
    if not success:
        raise ErrorResponse(error="not-found", message="History entry not found")
    
    return Response(status_code=204)


# ==================== Settings ====================


@app.get("/settings", response_model=SettingsResponse)
async def get_settings():
    """Get current settings."""
    db = await get_database()
    settings = await db.get_settings()
    
    return SettingsResponse(
        defaultModel=settings.get("defaultModel", "u2net"),
        defaultFormat=settings.get("defaultFormat", "png"),
        autoBackup=settings.get("autoBackup", False),
        resultTTLDays=settings.get("resultTTLDays", 30),
    )


@app.put("/settings", response_model=SettingsResponse)
async def update_settings(settings_data: dict):
    """Update settings."""
    db = await get_database()
    await db.update_settings(settings_data)
    
    # Return updated settings
    settings = await db.get_settings()
    return SettingsResponse(
        defaultModel=settings.get("defaultModel", "u2net"),
        defaultFormat=settings.get("defaultFormat", "png"),
        autoBackup=settings.get("autoBackup", False),
        resultTTLDays=settings.get("resultTTLDays", 30),
    )


# ==================== Export ====================


@app.get("/export/{id}")
async def export_result(
    id: str = PathParam(...),
    format: str = Query(default="png"),
    backgroundColor: str | None = Query(default=None),
    feather: int | None = Query(default=None),
    shift: int | None = Query(default=None),
):
    """Export processed image."""
    # Validate format
    if format not in ("png", "webp", "jpg"):
        raise ErrorResponse(error="invalid-format", message=f"Unsupported format: {format}")
    
    # Get history entry
    db = await get_database()
    entry = await db.get_history_entry(id)
    
    if not entry:
        raise ErrorResponse(error="not-found", message="History entry not found")
    
    # Get PNG data
    result_png = await db.get_result_png(id)
    if not result_png:
        raise ErrorResponse(error="not-found", message="Result image not found")
    
    # Apply custom settings if provided
    if feather is not None or shift is not None:
        settings = json.loads(entry.get("settings", "{}"))
        f = feather if feather is not None else settings.get("feather", 0)
        s = shift if shift is not None else settings.get("shift", 0)
        result_png = apply_feather_and_shift(result_png, f, s)
    
    # Export in requested format
    exported_data = export_image(result_png, format)
    
    # Set content type
    content_types = {
        "png": "image/png",
        "webp": "image/webp",
        "jpg": "image/jpeg",
    }
    
    filename = f"{entry['original_filename']}_no_bg.{format}"
    
    return Response(
        content=exported_data,
        media_type=content_types[format],
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
        },
    )


@app.post("/export/batch")
async def export_batch(request: ExportBatchRequest):
    """Export batch as ZIP file."""
    db = await get_database()
    
    # Create ZIP in memory
    zip_buffer = io.BytesIO()
    
    with zipfile.ZipFile(zip_buffer, 'w', zipfile.ZIP_DEFLATED) as zf:
        for idx, entry_id in enumerate(request.ids):
            # Get history entry
            entry = await db.get_history_entry(entry_id)
            if not entry:
                continue
            
            # Get PNG data
            result_png = await db.get_result_png(entry_id)
            if not result_png:
                continue
            
            # Export in requested format
            exported_data = export_image(result_png, request.format)
            
            # Determine filename
            if request.naming == "original":
                name = f"{Path(entry['original_filename']).stem}_no_bg.{request.format}"
            elif request.naming == "numbered":
                name = f"image_{idx + 1:02d}.{request.format}"
            else:
                name = f"{entry_id}.{request.format}"
            
            # Add to ZIP
            zf.writestr(name, exported_data)
        
        # Add manifest
        manifest = {
            "exportedAt": "",
            "count": len(request.ids),
            "format": request.format,
            "ids": request.ids,
        }
        zf.writestr("manifest.json", json.dumps(manifest, indent=2))
    
    zip_buffer.seek(0)
    
    return Response(
        content=zip_buffer.getvalue(),
        media_type="application/zip",
        headers={
            "Content-Disposition": "attachment; filename=slag_export.zip",
        },
    )


if __name__ == "__main__":
    import uvicorn
    
    port = int(os.getenv("SLAG_PORT", "3458"))
    uvicorn.run(app, host="0.0.0.0", port=port)
