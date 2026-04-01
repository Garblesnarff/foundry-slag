# TODO — Foundry Slag

## MVP Phase

### Backend Infrastructure
- [ ] Set up FastAPI app with CORS, lifespan hooks, health check
- [ ] Implement SQLite schema (history, settings, batch_sets)
- [ ] Create rembg engine wrapper with model management
- [ ] Implement image processing utils (feather, shift, shadow, resize)
- [ ] Set up environment configuration (.env.example, defaults)

### Core Removal
- [ ] `POST /slag` endpoint for single image removal
- [ ] Model auto-download with progress indication
- [ ] Error handling for corrupt/unsupported images
- [ ] Response with base64-encoded PNG result

### Batch Processing
- [ ] `POST /slag/batch` endpoint with SSE progress stream
- [ ] Queue management and parallel processing (3-5 workers)
- [ ] SSE response format (status, progress %, completed count)
- [ ] Batch set storage and retrieval

### History & Settings
- [ ] `GET /history` and `GET /history/{id}` endpoints
- [ ] `DELETE /history/{id}` endpoint
- [ ] `GET /settings` and `PUT /settings` endpoints
- [ ] Persistent settings storage (default model, format, etc.)

### Export
- [ ] `GET /export/{id}` with format selection (PNG/WebP/JPG)
- [ ] `POST /export/batch` for ZIP generation
- [ ] Organized folder structure in ZIP

### Frontend Infrastructure
- [ ] React 19 app setup with TypeScript and Vite
- [ ] Tailwind CSS with custom foundry theme
- [ ] API client wrapper with fetch
- [ ] AppContext for state management
- [ ] useSSE hook for batch progress

### UI Components
- [ ] TitleBar with model selector, status, quick settings
- [ ] Dropzone with drag-and-drop and click-to-browse
- [ ] ResultPreview with side-by-side layout
- [ ] CompareSlider for before/after
- [ ] EdgeControls for feather and shift sliders

### Basic Features
- [ ] Single image upload and removal
- [ ] Result preview and export
- [ ] Model selection UI
- [ ] Simple history view

## Post-MVP Features

### Edge Refinement
- [ ] EdgeControls component with feather and shift sliders
- [ ] Backend processing for feather (gaussian blur alpha)
- [ ] Backend processing for shift (erode/dilate alpha)
- [ ] Real-time preview of refinement changes

### Background Replacement
- [ ] BackgroundPicker component with color and shadow options
- [ ] Color picker integration
- [ ] Drop shadow controls (blur, offset, opacity)
- [ ] Backend image composition (subject + background)
- [ ] Preview updates in real-time

### Batch Features
- [ ] BatchView component for multi-image processing
- [ ] Gallery view of queued/completed images
- [ ] Apply-to-all settings option
- [ ] Individual result preview in batch mode
- [ ] Smart batch naming and folder structure

### History & Management
- [ ] HistoryView with searchable list/grid
- [ ] Metadata display (model, settings, processing time)
- [ ] Re-export functionality
- [ ] Batch set grouping
- [ ] History cleanup/archival options

### Settings Panel
- [ ] SettingsPanel component for preferences
- [ ] Default model selection
- [ ] Default export format
- [ ] Model management (view, download, delete)
- [ ] Disk space display
- [ ] Auto-backup toggle

### Export & Organization
- [ ] ZIP export with custom naming templates
- [ ] Compression options for WebP/JPG
- [ ] Batch folder organization
- [ ] Download progress indication

### Model Management
- [ ] `GET /slag/models` endpoint listing available models
- [ ] `POST /slag/models/{name}/download` with progress
- [ ] Model caching and versioning
- [ ] Disk space tracking

### Advanced Features
- [ ] Support for additional models (isnet-anime, silueta, u2net_human_seg)
- [ ] Custom naming templates for batch export
- [ ] Drag-and-drop reordering in batch mode
- [ ] Keyboard shortcuts (Cmd+E export, Cmd+Z undo, Cmd+R re-slag)
- [ ] Undo/redo stack for single session

## Polish & Testing

- [ ] End-to-end tests (upload → process → export)
- [ ] Unit tests for image processing utils
- [ ] Error recovery and edge case handling
- [ ] Performance profiling and optimization
- [ ] macOS Apple Silicon testing
- [ ] Memory leak detection
- [ ] UI responsive design testing

## Documentation

- [ ] API_SPEC.md with full endpoint documentation
- [ ] ARCHITECTURE.md with design decisions
- [ ] Backend README with setup instructions
- [ ] Frontend README with setup instructions
- [ ] Contributing guidelines
- [ ] Troubleshooting guide

## Tauri Desktop Shell (Future)

- [ ] Tauri 2.0 project setup
- [ ] Native window chrome
- [ ] Auto-update mechanism
- [ ] File association (*.png, *.jpg)
- [ ] Notification support
- [ ] System tray integration
