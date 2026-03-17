from contextlib import asynccontextmanager
import asyncio
import platform

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import APP_NAME, APP_VERSION, BASE_DIR, DB_DIR, INPUT_DIR, OUTPUT_DIR, TEMP_DIR, THUMBNAILS_DIR
from database import init_db
from engine import SlagEngine
from routes import export, health, history, images, refine, remove, settings


def ensure_dirs():
    for p in [BASE_DIR, DB_DIR, INPUT_DIR, OUTPUT_DIR, TEMP_DIR, THUMBNAILS_DIR]:
        p.mkdir(parents=True, exist_ok=True)


@asynccontextmanager
async def lifespan(app: FastAPI):
    ensure_dirs()
    await init_db()
    app.state.engine = SlagEngine()
    app.state.status = "loading"
    app.state.queue_length = 0
    app.state.platform = f"{platform.system().lower()}-{platform.machine().lower()}"

    async def loader():
        try:
            await app.state.engine.load_model()
            app.state.status = "ready"
        except Exception:
            app.state.status = "error"

    task = asyncio.create_task(loader())
    yield
    task.cancel()


app = FastAPI(title=APP_NAME, version=APP_VERSION, lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5174", "http://localhost:3458", "tauri://localhost"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router, prefix="/api/v1")
app.include_router(remove.router, prefix="/api/v1")
app.include_router(refine.router, prefix="/api/v1")
app.include_router(history.router, prefix="/api/v1")
app.include_router(images.router, prefix="/api/v1")
app.include_router(export.router, prefix="/api/v1")
app.include_router(settings.router, prefix="/api/v1")
