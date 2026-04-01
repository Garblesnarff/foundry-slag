# API Specification

## Base URL
`http://localhost:3458` (configurable via `SLAG_PORT` environment variable)

## Health Check

### GET /health
Check API availability.

**Response (200 OK)**
```json
{
  "status": "ok",
  "version": "0.1.0"
}
```

## Background Removal

### POST /slag
Remove background from a single image.

**Request**
- Multipart form data
- `file` (File, required) — Image file (JPEG, PNG, WebP, BMP)
- `model` (string, optional) — Model name (default: `u2net`)
- `feather` (number, optional) — Feather amount in pixels (0-20)
- `shift` (number, optional) — Alpha shift (-10 to 10)

**Response (200 OK)**
```json
{
  "id": "uuid-string",
  "result": "data:image/png;base64,...",
  "original": "data:image/png;base64,...",
  "model": "u2net",
  "processingTimeMs": 2500,
  "settings": {
    "feather": 0,
    "shift": 0
  }
}
```

**Error Responses**
- 400 Bad Request — Invalid image format or corrupted file
- 413 Payload Too Large — Image exceeds size limit
- 422 Unprocessable Entity — Model not found

### POST /slag/batch
Batch remove backgrounds with SSE progress.

**Request**
- Multipart form data
- `files` (File[], required) — Multiple image files
- `model` (string, optional) — Model name (default: `u2net`)
- `feather` (number, optional) — Feather amount (0-20)
- `shift` (number, optional) — Alpha shift (-10 to 10)

**Response (200 OK)**
Server-Sent Events stream.

Each event:
```json
{
  "status": "processing|completed|error",
  "currentId": "uuid-string",
  "completed": 5,
  "total": 10,
  "progress": 50
}
```

Final event:
```json
{
  "status": "completed",
  "results": [
    {
      "id": "uuid-string",
      "originalFilename": "image.png",
      "model": "u2net",
      "processingTimeMs": 2500
    }
  ]
}
```

## Models

### GET /slag/models
List available models.

**Response (200 OK)**
```json
{
  "models": [
    {
      "name": "u2net",
      "size": "176MB",
      "useCase": "General purpose, best quality",
      "installed": true
    },
    {
      "name": "u2netp",
      "size": "4MB",
      "useCase": "Fast/lightweight",
      "installed": false
    }
  ]
}
```

### POST /slag/models/{name}/download
Download and cache a model.

**Response (200 OK)**
```json
{
  "name": "u2netp",
  "size": "4MB",
  "installed": true,
  "downloadTimeMs": 8000
}
```

**Error Responses**
- 404 Not Found — Model doesn't exist
- 503 Service Unavailable — Download server unavailable

## History

### GET /history
List processing history.

**Query Parameters**
- `skip` (integer, optional) — Pagination offset (default: 0)
- `limit` (integer, optional) — Results per page (default: 50)
- `model` (string, optional) — Filter by model name
- `startDate` (ISO 8601, optional) — Filter by date range start
- `endDate` (ISO 8601, optional) — Filter by date range end

**Response (200 OK)**
```json
{
  "entries": [
    {
      "id": "uuid-string",
      "originalFilename": "product.png",
      "model": "u2net",
      "processingTimeMs": 2500,
      "createdAt": "2026-03-14T10:30:00Z",
      "settings": {
        "feather": 0,
        "shift": 0
      },
      "batchSetId": "batch-uuid"
    }
  ],
  "total": 150,
  "skip": 0,
  "limit": 50
}
```

### GET /history/{id}
Get single history entry.

**Response (200 OK)**
```json
{
  "id": "uuid-string",
  "originalFilename": "product.png",
  "originalHash": "sha256-hash",
  "model": "u2net",
  "processingTimeMs": 2500,
  "createdAt": "2026-03-14T10:30:00Z",
  "settings": {
    "feather": 0,
    "shift": 0,
    "backgroundColor": "#ffffff",
    "shadowBlur": 0,
    "shadowOpacity": 0
  },
  "batchSetId": "batch-uuid",
  "resultPath": "/export/uuid-string/png"
}
```

**Error Responses**
- 404 Not Found — History entry doesn't exist

### DELETE /history/{id}
Delete history entry and results.

**Response (204 No Content)**

**Error Responses**
- 404 Not Found — History entry doesn't exist

## Settings

### GET /settings
Get current settings.

**Response (200 OK)**
```json
{
  "defaultModel": "u2net",
  "defaultFormat": "png",
  "autoBackup": false,
  "resultTTLDays": 30
}
```

### PUT /settings
Update settings.

**Request**
```json
{
  "defaultModel": "u2net",
  "defaultFormat": "webp",
  "autoBackup": true,
  "resultTTLDays": 60
}
```

**Response (200 OK)**
```json
{
  "defaultModel": "u2net",
  "defaultFormat": "webp",
  "autoBackup": true,
  "resultTTLDays": 60
}
```

## Export

### GET /export/{id}
Export processed image.

**Query Parameters**
- `format` (string, optional) — Export format: `png`, `webp`, `jpg` (default: `png`)
- `backgroundColor` (string, optional) — Background color for JPG export (e.g., `#ffffff`)
- `feather` (number, optional) — Override feather amount
- `shift` (number, optional) — Override shift amount

**Response (200 OK)**
Binary image file with appropriate Content-Type header.

**Error Responses**
- 404 Not Found — History entry doesn't exist
- 400 Bad Request — Invalid format or parameters

### POST /export/batch
Export batch as ZIP file.

**Request**
```json
{
  "ids": ["uuid1", "uuid2", "uuid3"],
  "format": "png",
  "folderStructure": "flat|date|model",
  "naming": "original|numbered|custom"
}
```

**Response (200 OK)**
Binary ZIP file with Content-Disposition header.

**ZIP Structure (example)**
```
exports/
├── product_01.png
├── product_02.png
├── product_03.png
└── manifest.json
```

**Error Responses**
- 400 Bad Request — Invalid parameters
- 404 Not Found — One or more history entries not found

## Error Handling

All errors follow this format:

```json
{
  "error": "error-code",
  "message": "Human-readable error message",
  "details": {
    "field": "value"
  }
}
```

### HTTP Status Codes
- 200 OK — Success
- 204 No Content — Success (no body)
- 400 Bad Request — Invalid parameters
- 404 Not Found — Resource not found
- 413 Payload Too Large — File too large
- 422 Unprocessable Entity — Validation error
- 500 Internal Server Error — Server error
- 503 Service Unavailable — Service temporarily unavailable

## Rate Limiting

No rate limiting for MVP. May be added in future versions.

## CORS

Frontend allowed origins:
- `localhost:5175` (development)
- `localhost:3000` (alternative)

Configure via environment variable if needed.
