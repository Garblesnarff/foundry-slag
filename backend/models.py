"""
Models module for Foundry Slag.

Pydantic request/response models for API validation.
"""

from typing import Optional, Any
from pydantic import BaseModel, Field


# ==================== Request Models ====================


class SlagRequest(BaseModel):
    """Request model for single image background removal."""
    model: str = Field(default="u2net", description="Model name for background removal")
    feather: int = Field(default=0, ge=0, le=20, description="Feather amount in pixels")
    shift: int = Field(default=0, ge=-10, le=10, description="Alpha shift amount")


class BatchSlagRequest(BaseModel):
    """Request model for batch background removal."""
    model: str = Field(default="u2net", description="Model name for background removal")
    feather: int = Field(default=0, ge=0, le=20, description="Feather amount")
    shift: int = Field(default=0, ge=-10, le=10, description="Alpha shift amount")


class SettingsUpdateRequest(BaseModel):
    """Request model for updating settings."""
    defaultModel: Optional[str] = Field(default=None, description="Default model name")
    defaultFormat: Optional[str] = Field(default=None, description="Default export format")
    autoBackup: Optional[bool] = Field(default=None, description="Auto backup toggle")
    resultTTLDays: Optional[int] = Field(default=None, ge=1, description="Result TTL in days")


class ExportBatchRequest(BaseModel):
    """Request model for batch export."""
    ids: list[str] = Field(min_length=1, description="List of history entry IDs")
    format: str = Field(default="png", description="Export format")
    folderStructure: str = Field(default="flat", description="Folder structure in ZIP")
    naming: str = Field(default="original", description="File naming convention")


class ExportRequest(BaseModel):
    """Request model for single export."""
    format: str = Field(default="png", description="Export format (png, webp, jpg)")
    backgroundColor: Optional[str] = Field(default=None, description="Background color for JPG")
    feather: Optional[int] = Field(default=None, ge=0, le=20, description="Override feather")
    shift: Optional[int] = Field(default=None, ge=-10, le=10, description="Override shift")


# ==================== Response Models ====================


class HealthResponse(BaseModel):
    """Response model for health check."""
    status: str
    version: str


class SlagResponse(BaseModel):
    """Response model for single image removal."""
    id: str
    result: str = Field(description="Base64-encoded result image")
    original: str = Field(description="Base64-encoded original image")
    model: str
    processingTimeMs: int
    settings: dict[str, Any] = Field(default_factory=dict)


class BatchProgressEvent(BaseModel):
    """SSE event model for batch progress."""
    status: str  # "processing", "completed", "error"
    currentId: Optional[str] = None
    completed: int
    total: int
    progress: Optional[int] = None


class BatchResultItem(BaseModel):
    """Individual result item in batch response."""
    id: str
    originalFilename: str
    model: str
    processingTimeMs: int


class BatchCompleteResponse(BaseModel):
    """Final response for batch completion."""
    status: str = "completed"
    results: list[BatchResultItem]


class ModelInfo(BaseModel):
    """Model information."""
    name: str
    size: str
    useCase: str
    installed: bool


class ModelsResponse(BaseModel):
    """Response model for models list."""
    models: list[ModelInfo]


class ModelDownloadResponse(BaseModel):
    """Response model for model download."""
    name: str
    size: str
    installed: bool
    downloadTimeMs: int


class HistoryEntry(BaseModel):
    """History entry model."""
    id: str
    originalFilename: str
    originalHash: Optional[str] = None
    model: str = Field(alias="modelName")
    processingTimeMs: int
    createdAt: str
    settings: dict[str, Any]
    batchSetId: Optional[str] = None
    resultPath: Optional[str] = None

    class Config:
        populate_by_name = True


class HistoryListResponse(BaseModel):
    """Response model for history list."""
    entries: list[dict]
    total: int
    skip: int
    limit: int


class SettingsResponse(BaseModel):
    """Response model for settings."""
    defaultModel: str
    defaultFormat: str
    autoBackup: bool
    resultTTLDays: int


class ErrorResponse(BaseModel):
    """Error response model."""
    error: str
    message: str
    details: Optional[dict[str, Any]] = None


# ==================== Internal Models ====================


class ProcessingSettings(BaseModel):
    """Internal model for processing settings."""
    feather: int = 0
    shift: int = 0
    backgroundColor: Optional[str] = None
    shadowBlur: int = 0
    shadowOffsetX: int = 0
    shadowOffsetY: int = 0
    shadowOpacity: float = 0
