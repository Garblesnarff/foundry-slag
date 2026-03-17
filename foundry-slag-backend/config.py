from pathlib import Path

APP_NAME = "Foundry Slag"
APP_VERSION = "1.0.0"
API_PORT = 3458
BASE_DIR = Path.home() / "Documents" / "FoundrySlag"
DB_DIR = BASE_DIR / "db"
DB_PATH = DB_DIR / "foundry_slag.db"
INPUT_DIR = BASE_DIR / "input"
OUTPUT_DIR = BASE_DIR / "output"
TEMP_DIR = BASE_DIR / "temp"
THUMBNAILS_DIR = BASE_DIR / "thumbnails"

DEFAULT_MODEL = "u2net"
SUPPORTED_MODELS = [
    "u2net",
    "u2netp",
    "u2net_human_seg",
    "isnet-general-use",
    "isnet-anime",
    "silueta",
]
SUPPORTED_INPUT_FORMATS = [".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tiff", ".tif", ".heic"]
SUPPORTED_OUTPUT_FORMATS = ["png", "webp", "jpg"]
DEFAULT_OUTPUT_FORMAT = "png"
MAX_FILE_SIZE_MB = 100
MAX_IMAGE_DIMENSION = 8192
MAX_BATCH_SIZE = 200

DEFAULT_ALPHA_MATTING = False
DEFAULT_ALPHA_MATTING_FOREGROUND = 240
DEFAULT_ALPHA_MATTING_BACKGROUND = 10
DEFAULT_ALPHA_MATTING_ERODE = 10

THUMBNAIL_SIZE = (400, 400)

DEFAULT_SETTINGS = {
    "model": DEFAULT_MODEL,
    "output_format": DEFAULT_OUTPUT_FORMAT,
    "alpha_matting": "false",
    "output_directory": str(OUTPUT_DIR),
    "auto_cleanup_days": "30",
    "default_bg_type": "transparent",
    "default_bg_color": "#FFFFFF",
    "thumbnail_enabled": "true",
}
