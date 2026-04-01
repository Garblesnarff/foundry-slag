# Architecture

## System Overview

Foundry Slag is a local, offline background removal tool with three main components:

1. **FastAPI Backend** (Python) — REST API for background removal, history, settings
2. **React Frontend** (TypeScript) — Web UI for image upload, preview, export
3. **rembg Engine** (ONNX Runtime) — AI model inference for background segmentation

## Component Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Desktop (Tauri 2.0)                   │
│                   Optional Shell Layer                  │
└─────────────────────────────────────────────────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│                    React Frontend                            │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ App.tsx (Root)                                         │  │
│  │ ├── TitleBar                                           │  │
│  │ ├── Dropzone                                           │  │
│  │ ├── ResultPreview / CompareSlider / EdgeControls      │  │
│  │ ├── BackgroundPicker                                  │  │
│  │ ├── BatchView                                          │  │
│  │ ├── HistoryView                                        │  │
│  │ └── SettingsPanel                                      │  │
│  │                                                        │  │
│  │ AppContext (Global State)                              │  │
│  │ ├── currentModel                                       │  │
│  │ ├── isProcessing                                       │  │
│  │ └── settings                                           │  │
│  │                                                        │  │
│  │ Hooks                                                  │  │
│  │ ├── useSSE (batch progress)                            │  │
│  │ └── useHistory (history management)                    │  │
│  └────────────────────────────────────────────────────────┘  │
│  localhost:5175 (Vite dev server)                            │
└──────────────────────────────────────────────────────────────┘
                            ↕ HTTP/SSE
                    ┌───────────────┐
                    │ localhost:3458│
                    └───────────────┘
                            ↓
┌──────────────────────────────────────────────────────────────┐
│                   FastAPI Backend                            │
│  ┌────────────────────────────────────────────────────────┐  │
│  │ main.py (App & Routes)                                 │  │
│  │ ├── Lifespan (startup/shutdown)                        │  │
│  │ ├── CORS middleware                                    │  │
│  │ └── Route handlers                                     │  │
│  │                                                        │  │
│  │ engine.py (rembg Wrapper)                              │  │
│  │ ├── Model management                                  │  │
│  │ ├── Auto-download & caching                            │  │
│  │ └── Inference (U2-Net / ISNet)                         │  │
│  │                                                        │  │
│  │ database.py (SQLite)                                   │  │
│  │ ├── Schema initialization                             │  │
│  │ ├── History CRUD                                       │  │
│  │ └── Settings management                               │  │
│  │                                                        │  │
│  │ utils.py (Image Processing)                            │  │
│  │ ├── Feather (gaussian blur alpha)                      │  │
│  │ ├── Shift (erode/dilate alpha)                         │  │
│  │ ├── Shadow (drop shadow composition)                   │  │
│  │ └── Color replacement                                 │  │
│  │                                                        │  │
│  │ models.py (Pydantic)                                   │  │
│  │ └── Request/response validation                        │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                                │
│  ┌─────────────────┐      ┌───────────────┐                  │
│  │  SQLite DB      │      │  rembg Engine │                  │
│  │  ./slag.db      │      │  ONNX Runtime │                  │
│  │ ├── history     │      │  ./models/    │                  │
│  │ ├── settings    │      │ ├── u2net     │                  │
│  │ └── batch_sets  │      │ ├── u2netp    │                  │
│  │                 │      │ └── isnet-*   │                  │
│  └─────────────────┘      └───────────────┘                  │
└──────────────────────────────────────────────────────────────┘
```

## Data Flow

### Single Image Removal
```
1. User drops image on Dropzone
   ↓
2. Dropzone component reads file via File API
   ↓
3. api.client.removeBackground(file, model)
   ↓
4. POST /slag with multipart form data
   ↓
5. Backend:
   - Load image with Pillow
   - Run rembg inference (1-5 seconds)
   - Apply edge refinement (feather/shift)
   ↓
6. Return base64-encoded PNG + metadata
   ↓
7. ResultPreview displays result + original side-by-side
   ↓
8. User can export or adjust settings and re-process
```

### Batch Processing
```
1. User selects multiple files
   ↓
2. BatchView queues all files
   ↓
3. api.client.batchRemoveBackground(files)
   ↓
4. POST /slag/batch
   ↓
5. Backend:
   - Queue all images
   - Process in parallel (3-5 workers)
   - Stream progress via SSE
   ↓
6. Frontend:
   - useSSE hook connects to EventSource
   - Receives progress events: {status, completed, total}
   - Updates UI in real-time
   ↓
7. Results collected and displayed in gallery
   ↓
8. User selects results to export as ZIP
```

### History & Settings
```
History:
1. GET /history → Fetch entries from SQLite
2. Frontend caches with useHistory hook
3. Display as grid/list with metadata
4. Click to preview, re-export, or delete

Settings:
1. GET /settings → Load from SQLite key-value table
2. AppContext stores in memory
3. User updates via SettingsPanel
4. PUT /settings → Save to database
```

## Database Schema

### history table
```sql
CREATE TABLE history (
  id TEXT PRIMARY KEY,              -- UUIDv4
  original_filename TEXT,            -- User-provided or default
  original_hash TEXT,                -- SHA256 for dedup
  model_name TEXT,                   -- u2net, u2netp, etc.
  settings JSON,                     -- {feather, shift, bg, shadow}
  result_png BLOB,                   -- Binary PNG data
  result_paths JSON,                 -- {png: path, webp: path, jpg: path}
  processing_time_ms INTEGER,        -- Inference time
  created_at TIMESTAMP,              -- ISO 8601
  batch_set_id TEXT NULLABLE         -- Group related jobs
);
```

### settings table
```sql
CREATE TABLE settings (
  key TEXT PRIMARY KEY,              -- Setting name
  value TEXT                         -- JSON value
);
```

### batch_sets table
```sql
CREATE TABLE batch_sets (
  id TEXT PRIMARY KEY,               -- UUIDv4
  name TEXT,                         -- User-provided name
  created_at TIMESTAMP               -- ISO 8601
);
```

## Model Management

### Model Lifecycle

1. **Discovery** → List available models via rembg
2. **Download** → Auto-fetch on first use or manual download
3. **Caching** → Store in `SLAG_MODELS_DIR` (default: `./models`)
4. **Loading** → Lazy-load into memory on inference
5. **Cleanup** → User can delete unused models to free space

### Supported Models
- `u2net` — General purpose, best quality (default)
- `u2netp` — Fast/lightweight
- `isnet-general-use` — Alternative general model
- `isnet-anime` — Anime/illustration specialization
- `silueta` — Silhouette extraction
- `u2net_human_seg` — Human-specific segmentation

All via rembg/ONNX Runtime, CPU inference, float32 only.

## State Management

### AppContext
Global state for:
- `currentModel` — Selected model for next processing
- `isProcessing` — Flag to disable UI during processing
- `settings` — User preferences (default model, format, etc.)

No Redux or other state library. React Context sufficient for MVP.

### Local State
Components manage local UI state:
- `Dropzone` — selectedFiles, uploadProgress
- `ResultPreview` — previewMode (side-by-side or slider)
- `EdgeControls` — featherValue, shiftValue
- `BatchView` — selectedResults for export

## Performance Considerations

### Backend
- **Inference**: 1-5 seconds per image (u2net on M1 CPU)
- **Memory**: ~2GB peak during inference
- **Batch**: 3-5 parallel workers to avoid OOM
- **Database**: SQLite sufficient for history; index on `created_at` for pagination

### Frontend
- **Bundle Size**: ~200KB (React + Vite optimized)
- **Memory**: Minimal; results stored as base64 strings
- **UI Responsiveness**: <100ms frame time with canvas rendering
- **Image Preview**: Use canvas for efficient scaling/comparison

## Concurrency

### Backend Concurrency
- AsyncIO for I/O (database, file operations)
- ThreadPool for CPU-bound inference (rembg)
- Max 3-5 concurrent inferences to avoid memory overload

### Frontend Concurrency
- Single user interaction at a time (no multi-tab processing)
- SSE stream for batch progress (no polling)

## Error Handling

### Backend
- Validate file format (JPEG, PNG, WebP, BMP)
- Check image size (<50MB)
- Handle model download failures gracefully
- Log all errors with context
- Return structured error responses

### Frontend
- Catch API errors in try-catch blocks
- Display user-friendly error messages
- Retry mechanism for transient failures
- Fallback UI if API is unavailable

## Offline Capability

100% offline design:
- No cloud calls or telemetry
- Models cached locally after first download
- All processing on-device
- History stored in local SQLite
- No external dependencies except rembg (still offline)

## Security Considerations

### No Authentication
- Local-only app; no user accounts
- CORS restricted to localhost only

### File Handling
- Validate MIME types on upload
- Limit file size (<50MB)
- Auto-delete old results (configurable TTL)
- No transmission of files outside local system

### Model Verification
- rembg handles model verification
- ONNX models are sandboxed (safe to run untrusted models)

## Future Extensibility

### Desktop Shell (Tauri)
- Replace Vite dev server with native window
- File associations (*.png, *.jpg → drag to app)
- System tray integration
- Auto-update mechanism

### Additional Models
- Support for custom ONNX models
- Model marketplace or community models
- Fine-tuning capability for specific use cases

### Cloud Sync (Optional)
- Local-first sync to cloud backup
- Encrypted backup of history
- Device sync (if multiple devices)
