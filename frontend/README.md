# Foundry Slag — Frontend

React 19 + TypeScript + Vite + Tailwind CSS frontend for background removal.

## Setup

### Prerequisites
- Node.js 18+
- npm or yarn

### Installation

```bash
# Install dependencies
npm install

# Copy environment template (if needed)
cp .env.example .env
```

### Environment Variables

```bash
VITE_API_URL=http://localhost:3458
```

## Running

### Development
```bash
npm run dev
```

The frontend will be available at `http://localhost:5175`.

### Build
```bash
npm run build
```

Output in `dist/`.

### Preview Built App
```bash
npm run preview
```

## Project Structure

```
src/
├── main.tsx              # React entry point
├── App.tsx               # Root component
├── api/
│   └── client.ts         # API wrapper with fetch
├── components/
│   ├── TitleBar.tsx      # Header with model selector
│   ├── Dropzone.tsx      # Drag-and-drop area
│   ├── CompareSlider.tsx # Before/after slider
│   ├── ResultPreview.tsx # Result display
│   ├── EdgeControls.tsx  # Feather/shift sliders
│   ├── BackgroundPicker.tsx  # Color and shadow
│   ├── BatchView.tsx     # Batch processing UI
│   ├── HistoryView.tsx   # Processing history
│   └── SettingsPanel.tsx # Settings UI
├── hooks/
│   ├── useSSE.ts         # Server-sent events hook
│   └── useHistory.ts     # History management hook
├── context/
│   └── AppContext.tsx    # Global app state
└── styles/
    └── foundry.css       # Custom foundry theme

index.html               # HTML entry point
package.json
vite.config.ts
tsconfig.json
tailwind.config.ts
```

## Development

### TypeScript
All source files are TypeScript (.tsx, .ts). Type checking is enforced.

### Tailwind CSS
Custom foundry theme in `tailwind.config.ts`. Use Tailwind utilities directly in JSX.

### State Management
React Context for global state (no Redux for MVP). See `src/context/AppContext.tsx`.

### API Communication
Fetch-based API wrapper in `src/api/client.ts`. All API calls go through this wrapper.

### Server-Sent Events
Custom hook `useSSE` for batch processing progress updates. See `src/hooks/useSSE.ts`.

## Components

### TitleBar
Header with:
- Current model display
- Processing status
- Quick settings access

### Dropzone
Large drag-and-drop area with:
- File input fallback
- Image format validation
- Upload progress

### ResultPreview
Side-by-side or slider comparison of:
- Original image
- Processed result

### CompareSlider
Interactive before/after slider for quality verification.

### EdgeControls
Sliders for:
- Feather (0-20px)
- Shift (-10 to +10px)

### BackgroundPicker
Options for:
- Background color
- Drop shadow (blur, offset, opacity)

### BatchView
UI for batch processing:
- Image list/gallery
- Progress indicators
- Individual result preview
- Select-all export option

### HistoryView
Searchable history of past jobs:
- Thumbnail grid/list
- Metadata display
- Re-export/delete options
- Batch set grouping

### SettingsPanel
User preferences:
- Default model
- Export format
- Auto-backup
- Model management

## API Integration

All API calls use the wrapper in `src/api/client.ts`. Example:

```typescript
import { api } from '@/api/client';

// Single image
const result = await api.removeBackground(file, 'u2net');

// Batch with progress
api.batchRemoveBackground(files, { model: 'u2net' }, (progress) => {
  console.log(`${progress.completed}/${progress.total}`);
});

// History
const history = await api.getHistory();

// Export
await api.exportResult(id, 'png');
```

## Styling

### Colors
- Primary black: #141210 (charcoal)
- Accent: #E8A849 (amber)
- Text: #F5F5F5 (off-white)
- Border: #3A3935 (dark gray)

### Typography
- Body: DM Sans
- Code: JetBrains Mono
- Titles: Playfair Display (sparingly)

See `src/styles/foundry.css` for theme definitions.

## Keyboard Shortcuts

- `Cmd+E` — Quick export
- `Cmd+Z` — Undo
- `Cmd+R` — Re-slag current image

## Testing

```bash
npm run test
```

## Build & Deployment

```bash
npm run build
```

Output: `dist/` directory with optimized static files.

For Tauri desktop app, `dist/` is served by the native shell.

## Troubleshooting

### CORS Errors
- Check backend is running on localhost:3458
- Verify `VITE_API_URL` in .env or browser dev tools
- Check backend CORS middleware allows frontend origin

### Images Not Uploading
- Check file size (should be <50MB)
- Verify format (JPEG, PNG, WebP, BMP)
- Check browser console for errors

### Preview Not Showing
- Ensure result was generated successfully
- Check that result PNG is valid base64
- Try different browser or clear cache

## References

- **React** — https://react.dev/
- **Vite** — https://vitejs.dev/
- **Tailwind CSS** — https://tailwindcss.com/
- **TypeScript** — https://www.typescriptlang.org/
