# Foundry Slag — Background Remover

A local, offline background removal tool for images. Built for Etsy sellers, marketers, designers, and anyone who needs instant clean cutouts without subscriptions or cloud uploads.

**The slag burns away. The gold remains.**

## Features

- **Instant Removal**: Drop an image and get a cutout in seconds
- **100% Offline**: No cloud, no uploads, no subscriptions
- **Single & Batch**: Process one image or hundreds at once
- **Edge Refinement**: Feather, erode/dilate, shift alpha channels
- **Background Replacement**: Swap or customize the background
- **Compare Slider**: Before/after visualization
- **History**: Keep track of all your processing
- **Export Formats**: PNG (transparent), WebP, JPG (with background color)
- **Batch ZIP Export**: Download entire batches as organized archives

## Quick Start

### Prerequisites
- Python 3.11+
- Node.js 18+
- macOS Apple Silicon (M1-M4) recommended for CPU inference

### Backend Setup
```bash
cd backend
pip install -r requirements.txt
cp .env.example .env
uvicorn main:app --port 3458
```

The API will be available at `http://localhost:3458`.

### Frontend Setup
```bash
cd frontend
npm install
npm run dev
```

The frontend will be available at `http://localhost:5175`.

## Architecture

- **Backend**: FastAPI (Python 3.11+)
- **Frontend**: React 19 + TypeScript + Vite + Tailwind CSS
- **ML Engine**: rembg with U2-Net/ISNet (ONNX Runtime)
- **Database**: SQLite for history and settings
- **Desktop Shell**: Tauri 2.0 (optional)

See `CLAUDE.md` for the full technical overview and `docs/ARCHITECTURE.md` for detailed design decisions.

## Design System

This app follows the Foundry shared design system. See `docs/DESIGN_SYSTEM.md` and the shared system at `~/Projects/foundry/_shared/DESIGN_SYSTEM.md`.

### Visual Identity
- **Color Scheme**: Dark forge aesthetic with charcoal blacks and amber accents
- **Typography**: DM Sans (body), JetBrains Mono (code), Playfair Display (titles)
- **Language**: Metallurgy verbs and slag-specific terminology

## Available Models

| Model | Size | Use Case |
|-------|------|----------|
| **u2net** | 176MB | General purpose, best quality (default) |
| u2netp | 4MB | Fast/lightweight |
| isnet-general-use | ~44MB | General purpose alternative |
| isnet-anime | ~44MB | Anime/illustration |
| silueta | ~44MB | Silhouette extraction |
| u2net_human_seg | ~176MB | Human segmentation |

Models auto-download on first use.

## API Endpoints

See `docs/API_SPEC.md` for the full API specification.

Quick reference:
- `POST /slag` — Remove background from a single image
- `POST /slag/batch` — Batch processing with progress
- `GET /history` — List processing history
- `PUT /settings` — Customize settings
- `GET /export/{id}` — Export a processed image

## Development

- See `CLAUDE.md` for technical notes
- See `AGENTS.md` for coordination rules
- See `TODO.md` for prioritized tasks
- See `PRD.md` for the full product specification

## Legal

- **rembg**: MIT License
- **U2-Net weights**: Apache 2.0
- **ISNet weights**: Apache 2.0

No attribution required in UI. This is the cleanest-licensed tool in the Foundry lineup.

## License

TBD — See LICENSE file for details.
