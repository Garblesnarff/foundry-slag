"""
Database module for Foundry Slag.

SQLite database management via aiosqlite for async operations.
Handles history, settings, and batch sets.
"""

import os
import json
import uuid
from datetime import datetime
from typing import Optional, Any
from pathlib import Path

import aiosqlite


# Database path from environment or default
DB_PATH = os.getenv("SLAG_DB_PATH", "./slag.db")


class Database:
    """Async SQLite database wrapper for Foundry Slag."""

    def __init__(self, db_path: str = DB_PATH):
        self.db_path = db_path
        self._connection: Optional[aiosqlite.Connection] = None

    async def connect(self) -> None:
        """Initialize database connection and create tables."""
        self._connection = await aiosqlite.connect(self.db_path)
        self._connection.row_factory = aiosqlite.Row
        await self._initialize_tables()

    async def close(self) -> None:
        """Close database connection."""
        if self._connection:
            await self._connection.close()
            self._connection = None

    async def _initialize_tables(self) -> None:
        """Create database tables if they don't exist."""
        async with self._connection.execute(
            """
            CREATE TABLE IF NOT EXISTS history (
                id TEXT PRIMARY KEY,
                original_filename TEXT NOT NULL,
                original_hash TEXT,
                model_name TEXT NOT NULL,
                settings TEXT,
                result_png BLOB,
                result_paths TEXT,
                processing_time_ms INTEGER,
                created_at TEXT NOT NULL,
                batch_set_id TEXT
            )
            """
        ):
            pass

        async with self._connection.execute(
            """
            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            )
            """
        ):
            pass

        async with self._connection.execute(
            """
            CREATE TABLE IF NOT EXISTS batch_sets (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                created_at TEXT NOT NULL
            )
            """
        ):
            pass

        # Create indexes for performance
        async with self._connection.execute(
            "CREATE INDEX IF NOT EXISTS idx_history_created_at ON history(created_at DESC)"
        ):
            pass

        async with self._connection.execute(
            "CREATE INDEX IF NOT EXISTS idx_history_model ON history(model_name)"
        ):
            pass

        async with self._connection.execute(
            "CREATE INDEX IF NOT EXISTS idx_history_batch_set ON history(batch_set_id)"
        ):
            pass

        # Initialize default settings if not present
        await self._initialize_default_settings()

        await self._connection.commit()

    async def _initialize_default_settings(self) -> None:
        """Insert default settings if not present."""
        defaults = {
            "defaultModel": "u2net",
            "defaultFormat": "png",
            "autoBackup": False,
            "resultTTLDays": 30,
        }
        for key, value in defaults.items():
            await self._connection.execute(
                "INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)",
                (key, json.dumps(value)),
            )

    # ==================== History CRUD ====================

    async def create_history_entry(
        self,
        original_filename: str,
        original_hash: Optional[str],
        model_name: str,
        settings: dict,
        result_png: Optional[bytes],
        processing_time_ms: int,
        batch_set_id: Optional[str] = None,
    ) -> str:
        """Create a new history entry and return its ID."""
        entry_id = str(uuid.uuid4())
        created_at = datetime.utcnow().isoformat() + "Z"

        await self._connection.execute(
            """
            INSERT INTO history (
                id, original_filename, original_hash, model_name,
                settings, result_png, processing_time_ms, created_at, batch_set_id
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                entry_id,
                original_filename,
                original_hash,
                model_name,
                json.dumps(settings),
                result_png,
                processing_time_ms,
                created_at,
                batch_set_id,
            ),
        )
        await self._connection.commit()
        return entry_id

    async def get_history_entry(self, entry_id: str) -> Optional[dict]:
        """Get a single history entry by ID."""
        async with self._connection.execute(
            "SELECT * FROM history WHERE id = ?", (entry_id,)
        ) as cursor:
            row = await cursor.fetchone()
            if row:
                return dict(row)
        return None

    async def get_history(
        self,
        skip: int = 0,
        limit: int = 50,
        model: Optional[str] = None,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None,
    ) -> tuple[list[dict], int]:
        """Get paginated history entries with optional filters."""
        query = "SELECT * FROM history WHERE 1=1"
        params = []

        if model:
            query += " AND model_name = ?"
            params.append(model)

        if start_date:
            query += " AND created_at >= ?"
            params.append(start_date)

        if end_date:
            query += " AND created_at <= ?"
            params.append(end_date)

        # Get total count
        count_query = query.replace("SELECT *", "SELECT COUNT(*) as count")
        async with self._connection.execute(count_query, params) as cursor:
            row = await cursor.fetchone()
            total = row["count"] if row else 0

        # Get paginated results
        query += " ORDER BY created_at DESC LIMIT ? OFFSET ?"
        params.extend([limit, skip])

        entries = []
        async with self._connection.execute(query, params) as cursor:
            async for row in cursor:
                entries.append(dict(row))

        return entries, total

    async def update_history_entry(
        self, entry_id: str, updates: dict
    ) -> bool:
        """Update a history entry with new values."""
        set_clauses = []
        params = []

        for key, value in updates.items():
            if key == "settings":
                value = json.dumps(value)
            elif key == "result_paths":
                value = json.dumps(value)
            set_clauses.append(f"{key} = ?")
            params.append(value)

        if not set_clauses:
            return False

        params.append(entry_id)
        query = f"UPDATE history SET {', '.join(set_clauses)} WHERE id = ?"

        cursor = await self._connection.execute(query, params)
        await self._connection.commit()
        return cursor.rowcount > 0

    async def delete_history_entry(self, entry_id: str) -> bool:
        """Delete a history entry."""
        cursor = await self._connection.execute(
            "DELETE FROM history WHERE id = ?", (entry_id,)
        )
        await self._connection.commit()
        return cursor.rowcount > 0

    async def get_result_png(self, entry_id: str) -> Optional[bytes]:
        """Get the stored PNG result for an entry."""
        async with self._connection.execute(
            "SELECT result_png FROM history WHERE id = ?", (entry_id,)
        ) as cursor:
            row = await cursor.fetchone()
            if row:
                return row["result_png"]
        return None

    # ==================== Settings CRUD ====================

    async def get_settings(self) -> dict:
        """Get all settings as a dictionary."""
        settings = {}
        async with self._connection.execute(
            "SELECT key, value FROM settings"
        ) as cursor:
            async for row in cursor:
                try:
                    settings[row["key"]] = json.loads(row["value"])
                except json.JSONDecodeError:
                    settings[row["key"]] = row["value"]
        return settings

    async def get_setting(self, key: str) -> Optional[Any]:
        """Get a single setting value."""
        async with self._connection.execute(
            "SELECT value FROM settings WHERE key = ?", (key,)
        ) as cursor:
            row = await cursor.fetchone()
            if row:
                try:
                    return json.loads(row["value"])
                except json.JSONDecodeError:
                    return row["value"]
        return None

    async def set_setting(self, key: str, value: Any) -> None:
        """Set a single setting value."""
        await self._connection.execute(
            "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)",
            (key, json.dumps(value)),
        )
        await self._connection.commit()

    async def update_settings(self, settings: dict) -> dict:
        """Update multiple settings at once."""
        for key, value in settings.items():
            await self.set_setting(key, value)
        return await self.get_settings()

    # ==================== Batch Sets CRUD ====================

    async def create_batch_set(self, name: str) -> str:
        """Create a new batch set and return its ID."""
        set_id = str(uuid.uuid4())
        created_at = datetime.utcnow().isoformat() + "Z"

        await self._connection.execute(
            "INSERT INTO batch_sets (id, name, created_at) VALUES (?, ?, ?)",
            (set_id, name, created_at),
        )
        await self._connection.commit()
        return set_id

    async def get_batch_set(self, set_id: str) -> Optional[dict]:
        """Get a batch set by ID."""
        async with self._connection.execute(
            "SELECT * FROM batch_sets WHERE id = ?", (set_id,)
        ) as cursor:
            row = await cursor.fetchone()
            if row:
                return dict(row)
        return None

    async def get_batch_sets(self) -> list[dict]:
        """Get all batch sets."""
        sets = []
        async with self._connection.execute(
            "SELECT * FROM batch_sets ORDER BY created_at DESC"
        ) as cursor:
            async for row in cursor:
                sets.append(dict(row))
        return sets


# Global database instance
_db: Optional[Database] = None


async def get_database() -> Database:
    """Get the global database instance."""
    global _db
    if _db is None:
        _db = Database()
        await _db.connect()
    return _db


async def close_database() -> None:
    """Close the global database connection."""
    global _db
    if _db:
        await _db.close()
        _db = None
