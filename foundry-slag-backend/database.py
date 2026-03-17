from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path
import uuid

import aiosqlite

from config import DB_PATH, DEFAULT_SETTINGS


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


async def init_db() -> None:
    Path(DB_PATH).parent.mkdir(parents=True, exist_ok=True)
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("PRAGMA foreign_keys = ON")
        await db.execute(
            """
            CREATE TABLE IF NOT EXISTS jobs (
                id TEXT PRIMARY KEY,
                status TEXT NOT NULL DEFAULT 'queued',
                mode TEXT NOT NULL DEFAULT 'single',
                model TEXT NOT NULL DEFAULT 'u2net',
                total_images INTEGER NOT NULL DEFAULT 1,
                completed_images INTEGER NOT NULL DEFAULT 0,
                failed_images INTEGER NOT NULL DEFAULT 0,
                processing_time_seconds REAL,
                created_at TEXT NOT NULL,
                started_at TEXT,
                completed_at TEXT,
                error_message TEXT
            )
            """
        )
        await db.execute(
            """
            CREATE TABLE IF NOT EXISTS images (
                id TEXT PRIMARY KEY,
                job_id TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'queued',
                original_filename TEXT NOT NULL,
                input_path TEXT NOT NULL,
                input_width INTEGER,
                input_height INTEGER,
                input_format TEXT,
                input_file_size_bytes INTEGER,
                output_path TEXT,
                raw_output_path TEXT,
                output_width INTEGER,
                output_height INTEGER,
                output_file_size_bytes INTEGER,
                thumbnail_path TEXT,
                edge_feather REAL DEFAULT 0,
                edge_shift REAL DEFAULT 0,
                bg_type TEXT DEFAULT 'transparent',
                bg_color TEXT,
                bg_image_path TEXT,
                shadow_enabled INTEGER DEFAULT 0,
                shadow_opacity REAL DEFAULT 0.3,
                shadow_offset_x REAL DEFAULT 5,
                shadow_offset_y REAL DEFAULT 5,
                shadow_blur REAL DEFAULT 10,
                processing_time_seconds REAL,
                error_message TEXT,
                created_at TEXT NOT NULL,
                completed_at TEXT,
                FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE
            )
            """
        )
        await db.execute(
            """
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            )
            """
        )
        for k, v in DEFAULT_SETTINGS.items():
            await db.execute("INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)", (k, v))
        await db.commit()


async def fetch_one(query: str, params: tuple = ()):
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(query, params) as cur:
            row = await cur.fetchone()
            return dict(row) if row else None


async def fetch_all(query: str, params: tuple = ()):
    async with aiosqlite.connect(DB_PATH) as db:
        db.row_factory = aiosqlite.Row
        async with db.execute(query, params) as cur:
            return [dict(r) for r in await cur.fetchall()]


async def execute(query: str, params: tuple = ()):
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("PRAGMA foreign_keys = ON")
        await db.execute(query, params)
        await db.commit()


async def create_job(mode: str, model: str, total_images: int) -> str:
    job_id = str(uuid.uuid4())
    await execute(
        "INSERT INTO jobs (id, status, mode, model, total_images, created_at) VALUES (?, 'queued', ?, ?, ?, ?)",
        (job_id, mode, model, total_images, now_iso()),
    )
    return job_id


async def create_image(job_id: str, filename: str, input_path: str, metadata: dict) -> str:
    image_id = str(uuid.uuid4())
    await execute(
        """
        INSERT INTO images (
            id, job_id, status, original_filename, input_path, input_width, input_height,
            input_format, input_file_size_bytes, created_at
        ) VALUES (?, ?, 'queued', ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            image_id,
            job_id,
            filename,
            input_path,
            metadata.get("width"),
            metadata.get("height"),
            metadata.get("format"),
            metadata.get("file_size_bytes"),
            now_iso(),
        ),
    )
    return image_id


async def get_settings() -> dict:
    rows = await fetch_all("SELECT key, value FROM settings")
    out = {r["key"]: r["value"] for r in rows}
    out["alpha_matting"] = out.get("alpha_matting", "false") == "true"
    out["thumbnail_enabled"] = out.get("thumbnail_enabled", "true") == "true"
    out["auto_cleanup_days"] = int(out.get("auto_cleanup_days", 30))
    return out


async def update_setting_values(patch: dict):
    for k, v in patch.items():
        store = str(v).lower() if isinstance(v, bool) else str(v)
        await execute("INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value=excluded.value", (k, store))
