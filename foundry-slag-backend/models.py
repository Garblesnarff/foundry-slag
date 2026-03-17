from __future__ import annotations

from pydantic import BaseModel, Field
from typing import Literal


class ErrorResponse(BaseModel):
    error: str
    message: str
    details: dict = Field(default_factory=dict)


class RefinementPayload(BaseModel):
    edge_feather: float = 0
    edge_shift: float = 0
    bg_type: Literal["transparent", "color", "image"] = "transparent"
    bg_color: str = "#FFFFFF"
    bg_image_path: str | None = None
    shadow_enabled: bool = False
    shadow_opacity: float = 0.3
    shadow_offset_x: float = 5
    shadow_offset_y: float = 5
    shadow_blur: float = 10


class ExportPayload(BaseModel):
    format: Literal["png", "webp", "jpg"] = "png"
    quality: int = 95
    apply_refinements: bool = True


class BatchExportPayload(BaseModel):
    image_ids: list[str]
    format: Literal["png", "webp", "jpg"] = "png"
    apply_refinements: bool = True


class SettingsPatch(BaseModel):
    model: str | None = None
    output_format: str | None = None
    alpha_matting: bool | None = None
    output_directory: str | None = None
    auto_cleanup_days: int | None = None
    default_bg_type: str | None = None
    default_bg_color: str | None = None
    thumbnail_enabled: bool | None = None
