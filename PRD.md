# Product Requirements Document: Foundry Slag

**Full PRD to be provided — this is a generated placeholder.**

## Overview

Foundry Slag is a local, offline background removal tool designed for users who need instant, high-quality image cutouts without cloud uploads or subscriptions. The product targets Etsy sellers, marketers, designers, and content creators.

**Core Value Proposition**: Drop an image, get a clean cutout in seconds. 100% offline. No subscriptions. No clouds. Just you and the forge.

## User Stories

### MVP (Core Removal)
1. **As an e-commerce seller**, I want to remove the background from product photos instantly so I can create professional listings without hiring a designer.
2. **As a batch processor**, I want to drop multiple images at once and process them simultaneously so I can save time on large photo libraries.
3. **As a designer**, I want fine control over edge refinement (feather, erode/dilate) so my cutouts blend perfectly into layouts.
4. **As a bulk uploader**, I want to export an entire batch as a ZIP file so I can organize and download everything at once.

### Advanced Features
5. **As a user**, I want to replace or customize the background so I can show products in different contexts without re-shooting.
6. **As a power user**, I want to see a before/after comparison using an interactive slider so I can verify quality before exporting.
7. **As a frequent user**, I want a searchable history of all my processing jobs so I can re-export or re-process without starting over.
8. **As an image quality enthusiast**, I want to choose different AI models (u2net, isnet, anime-specific, etc.) so I can optimize for my content type.

## Features

### Feature Set 1: Core Background Removal
- **Single Image Processing**: Upload or drag-and-drop a single image, remove background, get result in 1-5 seconds
- **Batch Processing**: Queue multiple images, process in parallel with SSE progress updates
- **Model Selection**: Choose from u2net (default), u2netp, isnet-general-use, isnet-anime, silueta, u2net_human_seg
- **Auto-Download**: Models download automatically on first use with graceful progress indication
- **Format Support**: Input JPEG, PNG, WebP, BMP; output PNG (transparent), WebP, JPG (custom background)

### Feature Set 2: Edge Refinement
- **Feather**: Gaussian blur on alpha channel for soft edges (0-20px)
- **Shift**: Erode/dilate alpha channel for precise edge adjustment (-10 to +10px)
- **Preview**: See real-time preview of edge adjustments before export

### Feature Set 3: Background Replacement
- **Custom Color**: Pick any background color from a color picker
- **Drop Shadow**: Optional drop shadow beneath the subject (blur, offset, opacity)
- **Preview**: Interactive preview with different background options

### Feature Set 4: Comparison & Preview
- **Compare Slider**: Before/after drag slider for quality verification
- **Full Preview**: Full-screen preview mode
- **Zoom**: Ability to zoom in/out on preview to inspect edges

### Feature Set 5: History & Management
- **Processing History**: Persistent SQLite history of all jobs with timestamps
- **Metadata Storage**: Original filename, model used, settings applied, processing time
- **History Search**: Filter by date, model, status
- **Re-export**: Re-export old results with different settings without re-processing
- **Batch Sets**: Group related images (e.g., "Product Launch Q1") for organized export

### Feature Set 6: Export & Organization
- **Single Export**: Download individual result as PNG, WebP, or JPG
- **Batch Export**: Export entire batch/set as organized ZIP with folder structure
- **Naming Convention**: Auto-numbered or custom naming with templates
- **Compression**: Optional lossy compression for WebP/JPG to reduce file size

### Feature Set 7: Settings & Configuration
- **Default Model**: Set default removal model (persists across sessions)
- **Default Format**: Choose default export format
- **Auto-Backup**: Optional automatic backup of history to JSON
- **Model Management**: View installed models, download/delete models, manage disk space

### Feature Set 8: UI/UX
- **Dark Forge Aesthetic**: Charcoal blacks (#141210), amber accents (#E8A849)
- **Title Bar**: Shows current model, processing status, quick settings
- **Dropzone**: Large, clear drag-and-drop area with example images
- **Result Preview**: Side-by-side or slider comparison of original vs. result
- **Edge Controls**: Intuitive sliders for feather, shift, shadow
- **Status Feedback**: Real-time progress indication, processing time
- **Keyboard Shortcuts**: Quick export (Cmd+E), undo (Cmd+Z), re-process (Cmd+R)

## UI Flows

### Flow 1: Single Image Removal
1. User opens app → sees empty dropzone
2. User drags image or clicks to browse
3. App detects image, starts processing with progress spinner
4. Backend calls rembg with default model
5. Result displays side-by-side with original
6. User can:
   - Adjust edge refinement (feather/shift)
   - Add background or shadow
   - Open compare slider
   - Export (PNG/WebP/JPG)
   - Clear and start over

### Flow 2: Batch Processing
1. User clicks "Batch Mode"
2. User drags multiple images or selects folder
3. Images queue in a list with pending status
4. Processing begins; SSE stream updates progress
5. Results appear in gallery as they complete
6. User can:
   - Preview any result
   - Apply same settings to all
   - Select individual results to export
   - Export all as ZIP

### Flow 3: History & Re-export
1. User clicks "History" tab
2. Sees grid/list of past jobs with thumbnails
3. User clicks a result to preview
4. Can re-export with different settings or download original
5. Can delete old entries to free space

### Flow 4: Settings & Model Management
1. User opens Settings panel
2. Can set default model, export format, backup preferences
3. Can view installed models and disk space used
4. Can download new models (with progress)
5. Can delete models to free space

## Technical Requirements

### Backend (FastAPI/Python)
- **Ports**: 3458 for API
- **Database**: SQLite in-memory + file-backed for history
- **Concurrency**: AsyncIO with aiosqlite for non-blocking DB access
- **Image Processing**: Pillow for all image operations (resize, feather, shadow, color fill)
- **ML Engine**: rembg for background removal, ONNX Runtime for inference
- **Model Storage**: Configurable via SLAG_MODELS_DIR (default ./models)
- **Float32 Only**: No float16, no MPS (Apple Metal) — CPU float32 only
- **Error Handling**: Graceful handling of model downloads, missing images, corrupt files
- **Logging**: Structured logging with timestamps for debugging

### Frontend (React/TypeScript)
- **Framework**: React 19 with TypeScript
- **Build Tool**: Vite (fast HMR, optimal bundle)
- **Styling**: Tailwind CSS with custom foundry theme
- **State Management**: React Context (no Redux for MVP)
- **API Client**: Fetch with custom wrapper for consistency
- **SSE Client**: Custom hook for server-sent events (batch progress)
- **File Handling**: File API for drag-drop, multipart/form-data for uploads
- **Image Preview**: Canvas or img elements with custom comparison slider

### ML/Inference
- **Default Model**: u2net (best quality-to-speed ratio)
- **Model Format**: ONNX via rembg
- **Providers**: CPU only (no CUDA, no TensorRT)
- **Memory**: ~2GB for largest models during inference
- **Performance Target**: 1-5 seconds per image on M1-M4 CPU

### Database Schema
```sql
-- Processing history
CREATE TABLE history (
  id TEXT PRIMARY KEY,
  original_filename TEXT,
  original_hash TEXT,
  model_name TEXT,
  settings JSON,  -- feather, shift, background, shadow
  result_png BLOB,  -- or NULL if deleted
  result_paths JSON,  -- URLs to exported formats
  processing_time_ms INTEGER,
  created_at TIMESTAMP,
  batch_set_id TEXT  -- group related images
);

-- User settings
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT
);

-- Batch sets
CREATE TABLE batch_sets (
  id TEXT PRIMARY KEY,
  name TEXT,
  created_at TIMESTAMP
);
```

### API Endpoints (Summary)
See `docs/API_SPEC.md` for full specification.

## Performance Targets
- **Single Image**: 1-5 seconds (u2net on M1 CPU)
- **Batch Queue**: Process 3-5 images in parallel
- **UI Responsiveness**: <100ms frame time during preview
- **Memory**: <2GB peak during inference

## Offline Requirements
- **Zero Cloud**: No external API calls
- **No Telemetry**: No analytics, no phone-home
- **No Updates**: Version-based or manual update checking only
- **Model Distribution**: Models included in installer or downloaded on-demand

## Success Metrics
- **MVP**: All core features working, u2net removal, single+batch processing, basic history
- **1.0**: Edge refinement, background replacement, compare slider, full history, export formats
- **1.1+**: Anime-specific models, advanced batch templates, cloud backup (optional)

## Out of Scope (Future)
- Mobile app (desktop only for now)
- Real-time webcam background removal
- Video processing
- Cloud sync/backup (local only)
- Collaborative features
- API for third-party apps

## Success Criteria
- App launches and removes background in <5 seconds
- Batch processing works for 10+ images
- All edge refinement sliders are intuitive and work smoothly
- History persists across app restart
- Export formats (PNG/WebP/JPG) work correctly
- No crashes or hangs during normal usage
