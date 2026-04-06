# Foundry Slag — Background Remover
# Multi-stage Docker build: Node (frontend) + Python (backend)

# Stage 1: Build frontend
FROM node:20-alpine AS frontend-build
WORKDIR /app/frontend
COPY frontend/package.json frontend/package-lock.json* ./
RUN npm ci --no-audit --no-fund
COPY frontend/ ./
RUN npm run build

# Stage 2: Production backend + built frontend
FROM python:3.12-slim AS production
WORKDIR /app

# Install system dependencies for ML/image processing
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY backend/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# Copy backend code (preserving directory structure for static file resolution)
COPY backend/ ./backend/

# Copy built frontend to expected location (backend resolves ../frontend/dist)
COPY --from=frontend-build /app/frontend/dist ./frontend/dist

# Environment
ENV PYTHONUNBUFFERED=1
ENV ENVIRONMENT=production
EXPOSE 3458

WORKDIR /app/backend
CMD ["python", "main.py"]
