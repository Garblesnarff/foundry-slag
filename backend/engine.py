"""
Engine module for Foundry Slag.

ML engine wrapper around rembg for background removal.
Handles model loading, inference, and caching.
"""

import os
import io
import time
import shutil
import asyncio
from pathlib import Path
from typing import Optional, BinaryIO

from PIL import Image
from rembg import remove, new_session
import numpy as np


# Model configuration
MODELS_DIR = os.getenv("SLAG_MODELS_DIR", "./models")
DEFAULT_MODEL = os.getenv("SLAG_MODEL", "u2net")

# Supported models
AVAILABLE_MODELS = {
    "u2net": {
        "size": "176MB",
        "use_case": "General purpose, best quality",
    },
    "u2netp": {
        "size": "4MB",
        "use_case": "Fast/lightweight",
    },
    "isnet-general-use": {
        "size": "44MB",
        "use_case": "General purpose alternative",
    },
    "isnet-anime": {
        "size": "44MB",
        "use_case": "Anime/illustration",
    },
    "silueta": {
        "size": "44MB",
        "use_case": "Silhouette extraction",
    },
    "u2net_human_seg": {
        "size": "176MB",
        "use_case": "Human segmentation",
    },
}


class Engine:
    """Background removal engine using rembg."""

    def __init__(self, models_dir: str = MODELS_DIR):
        self.models_dir = Path(models_dir)
        self.models_dir.mkdir(parents=True, exist_ok=True)
        self._model_cache: dict[str, any] = {}
        self._model_downloading: dict[str, bool] = {}

    def list_models(self) -> list[dict]:
        """List all available models with installation status."""
        models = []
        for name, info in AVAILABLE_MODELS.items():
            installed = self._is_model_installed(name)
            models.append({
                "name": name,
                "size": info["size"],
                "useCase": info["use_case"],
                "installed": installed,
            })
        return models

    def _is_model_installed(self, model_name: str) -> bool:
        """Check if model is installed (cached by rembg)."""
        # rembg caches models in ~/.u2net/ by default
        u2net_dir = Path.home() / ".u2net"
        if u2net_dir.exists():
            model_file = u2net_dir / f"{model_name}.onnx"
            if model_file.exists():
                return True

        # Also check ~/.cache/rembg (alternate cache location)
        cache_dir = Path.home() / ".cache" / "rembg"
        if cache_dir.exists():
            model_file = cache_dir / f"{model_name}.onnx"
            if model_file.exists():
                return True

        # Also check in local models directory
        if (self.models_dir / f"{model_name}.onnx").exists():
            return True

        return False

    async def _get_model(self, model_name: str):
        """Get or load a model session."""
        if model_name not in self._model_cache:
            if model_name not in AVAILABLE_MODELS:
                raise ValueError(f"Unknown model: {model_name}")
            
            # Load model using new_session (rembg handles download if needed)
            session = new_session(model_name)
            self._model_cache[model_name] = session
        
        return self._model_cache[model_name]

    async def download_model(self, model_name: str) -> dict:
        """Download and cache a model."""
        if model_name not in AVAILABLE_MODELS:
            raise ValueError(f"Unknown model: {model_name}")
        
        if self._is_model_installed(model_name):
            return {
                "name": model_name,
                "size": AVAILABLE_MODELS[model_name]["size"],
                "installed": True,
                "downloadTimeMs": 0,
            }
        
        # Mark as downloading to avoid duplicate downloads
        if self._model_downloading.get(model_name, False):
            # Wait for existing download to complete
            while self._model_downloading.get(model_name, False):
                await asyncio.sleep(0.5)
            return {
                "name": model_name,
                "size": AVAILABLE_MODELS[model_name]["size"],
                "installed": True,
            }
        
        self._model_downloading[model_name] = True
        start_time = time.time()
        
        try:
            # Load model to trigger download
            await self._get_model(model_name)
            download_time = int((time.time() - start_time) * 1000)
            
            return {
                "name": model_name,
                "size": AVAILABLE_MODELS[model_name]["size"],
                "installed": True,
                "downloadTimeMs": download_time,
            }
        finally:
            self._model_downloading[model_name] = False

    async def remove_background(
        self,
        image_data: bytes,
        model_name: str = DEFAULT_MODEL,
    ) -> tuple[bytes, int]:
        """
        Remove background from an image.
        
        Returns:
            tuple of (result_bytes, processing_time_ms)
        """
        start_time = time.time()
        
        # Load image
        input_image = Image.open(io.BytesIO(image_data))
        
        # Convert to RGBA if needed
        if input_image.mode != "RGBA":
            input_image = input_image.convert("RGBA")
        
        # Get model session and run inference
        session = await self._get_model(model_name)
        
        # Run background removal
        output_image = remove(input_image, session=session)
        
        # Convert back to PNG bytes
        output_buffer = io.BytesIO()
        output_image.save(output_buffer, format="PNG")
        result_bytes = output_buffer.getvalue()
        
        processing_time = int((time.time() - start_time) * 1000)
        
        return result_bytes, processing_time

    async def remove_background_stream(
        self,
        image_stream: BinaryIO,
        model_name: str = DEFAULT_MODEL,
    ) -> tuple[bytes, int]:
        """Remove background from a stream/image file."""
        image_data = image_stream.read()
        return await self.remove_background(image_data, model_name)

    def clear_cache(self, model_name: Optional[str] = None) -> None:
        """Clear model cache to free memory."""
        if model_name:
            if model_name in self._model_cache:
                del self._model_cache[model_name]
        else:
            self._model_cache.clear()

    def get_model_size(self, model_name: str) -> str:
        """Get the size string for a model."""
        return AVAILABLE_MODELS.get(model_name, {}).get("size", "unknown")


# Global engine instance
_engine: Optional[Engine] = None


def get_engine() -> Engine:
    """Get the global engine instance."""
    global _engine
    if _engine is None:
        _engine = Engine()
    return _engine
