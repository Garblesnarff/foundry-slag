# Foundry Slag — Background Remover

## What This Is
Foundry Slag is a local, offline background removal tool that strips backgrounds from images instantly using AI. Built for Etsy sellers, marketers, designers, and anyone who needs clean cutouts without subscriptions. Drop an image into the forge, and the slag burns away — leaving only the gold.

## Tech Stack
- **Backend**: Python 3.11+, FastAPI, uvicorn, SQLite (aiosqlite)
- **Frontend**: React 19 + TypeScript + Vite + Tailwind CSS
- **ML**: rembg (U2-Net / ISNet via ONNX Runtime)
- **Desktop**: Tauri 2.0 shell (scaffold only)
- **Target**: macOS Apple Silicon (M1-M4), CPU inference, float32

## Architecture
```
┌─────────────────────────────────────────────┐
│              Tauri 2.0 Shell                │
│  ┌───────────────────────────────────────┐  │
│  │     React 19 + TypeScript Frontend    │  │
│  │         localhost:5175                 │  │
│  └──────────────┬────────────────────────┘  │
│                 │ HTTP/SSE                   │
│  ┌──────────────▼────────────────────────┐  │
│  │      FastAPI Backend (Python)         │  │
│  │         localhost:3458                 │  │
│  │  ┌─────────┐  ┌──────────────────┐   │  │
│  │  │ SQLite  │  │  rembg Engine    │   │  │
│  │  │ (history│  │  U2-Net/ISNet    │   │  │
│  │  │  + sets)│  │  ONNX Runtime    │   │  │
│  │  └─────────┘  └──────────────────┘   │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

## Port Assignment
- Backend API: localhost:3458
- Frontend dev: localhost:5175

## Design System
This app uses the Foundry shared design system. See `~/Projects/foundry/_shared/DESIGN_SYSTEM.md`.

Key rules:
- Dark forge aesthetic: charcoal blacks (#141210), amber accents (#E8A849)
- Fonts: DM Sans (body), JetBrains Mono (technical), Playfair Display (titles only)
- Forge language: use metallurgy verbs, not generic tech verbs
- Slag-specific language: "Slag it" / "Slagging..." / "Slagged!" / "RE-SLAG" / "The slag burns away, the gold remains"

## Models Available
| Model | Size | Use Case |
|-------|------|----------|
| u2net | 176MB | General purpose, best quality |
| u2netp | 4MB | Fast/lightweight |
| isnet-general-use | ~44MB | General purpose alternative |
| isnet-anime | ~44MB | Anime/illustration |
| silueta | ~44MB | Silhouette extraction |
| u2net_human_seg | ~176MB | Human segmentation |

## Critical Implementation Notes
- Default model: `u2net` (best quality-to-speed ratio)
- Single image processing is synchronous (1-5 seconds) — no SSE needed
- Batch processing uses SSE for progress reporting
- All models auto-download on first use via rembg — handle gracefully with progress
- Edge refinement: feather (gaussian blur on alpha), shift (erode/dilate alpha channel)
- Export formats: PNG (transparency), WebP (transparency), JPG (with background color)
- Batch export as ZIP file

## File Structure
```
backend/
├── main.py              # FastAPI app, routes, CORS, lifespan
├── engine.py            # rembg wrapper, model management
├── database.py          # SQLite schema, history CRUD
├── models.py            # Pydantic request/response models
├── utils.py             # Image processing helpers (feather, shadow, resize)
├── requirements.txt
└── .env.example

frontend/
├── index.html
├── package.json
├── vite.config.ts
├── tsconfig.json
├── tailwind.config.ts
├── src/
│   ├── main.tsx
│   ├── App.tsx
│   ├── api/client.ts          # API wrapper
│   ├── components/
│   │   ├── TitleBar.tsx
│   │   ├── Dropzone.tsx
│   │   ├── CompareSlider.tsx
│   │   ├── ResultPreview.tsx
│   │   ├── EdgeControls.tsx
│   │   ├── BackgroundPicker.tsx
│   │   ├── BatchView.tsx
│   │   ├── HistoryView.tsx
│   │   └── SettingsPanel.tsx
│   ├── hooks/
│   │   ├── useSSE.ts
│   │   └── useHistory.ts
│   ├── context/
│   │   └── AppContext.tsx
│   └── styles/
│       └── foundry.css
```

## API Summary
- `GET /health` — Health check
- `POST /slag` — Remove background from single image
- `POST /slag/batch` — Batch removal with SSE progress
- `GET /slag/models` — List available models
- `POST /slag/models/{name}/download` — Download a model
- `GET /history` — List processing history
- `GET /history/{id}` — Get single history entry
- `DELETE /history/{id}` — Delete history entry
- `GET /settings` — Get current settings
- `PUT /settings` — Update settings
- `GET /export/{id}` — Export processed image
- `POST /export/batch` — Export batch as ZIP

## Build & Run
```bash
# Backend
cd backend && pip install -r requirements.txt && uvicorn main:app --port 3458

# Frontend
cd frontend && npm install && npm run dev
```

## Legal
- rembg: MIT License
- U2-Net model weights: Apache 2.0
- ISNet model weights: Apache 2.0
- Cleanest licensing in the Foundry lineup — no attribution required in UI
