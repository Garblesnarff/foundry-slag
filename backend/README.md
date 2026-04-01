# Foundry Slag — Backend

FastAPI-based background removal service with SQLite history, rembg integration, and ONNX Runtime inference.

## Setup

### Prerequisites
- Python 3.11+
- pip or uv

### Installation

```bash
# Create virtual environment (optional but recommended)
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy environment template
cp .env.example .env
```

### Environment Variables

```bash
SLAG_PORT=3458                    # API port
SLAG_MODEL=u2net                  # Default model name
SLAG_MODELS_DIR=./models          # Model cache directory
SLAG_DB_PATH=./slag.db            # SQLite database path
SLAG_RESULT_TTL_DAYS=30           # How long to keep results
SLAG_LOG_LEVEL=INFO               # Logging level
```

## Running

### Development
```bash
uvicorn main:app --reload --port 3458
```

The API will be available at `http://localhost:3458`.

### Production
```bash
uvicorn main:app --host 0.0.0.0 --port 3458 --workers 4
```

## Project Structure

- **main.py** — FastAPI app, routes, CORS, lifespan hooks
- **engine.py** — rembg wrapper, model management, inference
- **database.py** — SQLite schema, history CRUD, settings
- **models.py** — Pydantic request/response models
- **utils.py** — Image processing helpers (feather, shadow, resize)
- **requirements.txt** — Python dependencies

## API Endpoints

See `../docs/API_SPEC.md` for full specification.

Quick reference:
- `GET /health` — Health check
- `POST /slag` — Remove background from single image
- `POST /slag/batch` — Batch processing with SSE progress
- `GET /slag/models` — List available models
- `POST /slag/models/{name}/download` — Download a model
- `GET /history` — List processing history
- `GET /history/{id}` — Get history entry
- `DELETE /history/{id}` — Delete history entry
- `GET /settings` — Get settings
- `PUT /settings` — Update settings
- `GET /export/{id}` — Export processed image
- `POST /export/batch` — Export batch as ZIP

## Database

SQLite database with three main tables:

- **history** — Processing jobs with results and metadata
- **settings** — User configuration
- **batch_sets** — Grouped processing jobs

Database auto-initializes on startup.

## Models

### Available
- `u2net` (176MB) — General purpose, best quality (default)
- `u2netp` (4MB) — Fast/lightweight
- `isnet-general-use` (~44MB) — General purpose alternative
- `isnet-anime` (~44MB) — Anime/illustration
- `silueta` (~44MB) — Silhouette extraction
- `u2net_human_seg` (~176MB) — Human segmentation

### Auto-Download
Models download automatically on first use to `SLAG_MODELS_DIR`. Subsequent requests use cached models.

## Image Processing

### Supported Input Formats
- JPEG, PNG, WebP, BMP

### Edge Refinement
- **Feather** (0-20px) — Gaussian blur on alpha channel
- **Shift** (-10 to +10px) — Erode/dilate alpha channel

### Background Replacement
- **Color** — Pick any background color
- **Shadow** — Optional drop shadow (blur, offset, opacity)

### Export Formats
- **PNG** — Transparent background (lossless)
- **WebP** — Transparent background, optional lossy compression
- **JPG** — Solid background color (lossy)

## Performance

- **Single Image**: 1-5 seconds (u2net on M1 CPU)
- **Batch Processing**: 3-5 images in parallel
- **Memory**: ~2GB peak during inference

## Logging

Structured logging to stdout. Configure level via `SLAG_LOG_LEVEL` environment variable.

## Testing

```bash
pytest tests/
```

## Troubleshooting

### Model Download Fails
- Check internet connection
- Verify `SLAG_MODELS_DIR` is writable
- Check disk space (models can be 100-200MB)

### Out of Memory During Inference
- Reduce batch size
- Close other applications
- Consider using smaller model (u2netp)

### CORS Errors
- Ensure frontend URL is in CORS allowed origins
- Check that backend and frontend ports match config

## References

- **rembg** — https://github.com/danielgatis/rembg
- **FastAPI** — https://fastapi.tiangolo.com/
- **ONNX Runtime** — https://github.com/microsoft/onnxruntime
