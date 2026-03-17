import threading
import time
from pathlib import Path

from PIL import Image
from rembg import new_session, remove


class SlagEngine:
    """Wraps rembg for background removal."""

    def __init__(self, model_name: str = "u2net"):
        self.model_name = model_name
        self.session = None
        self.loaded = False
        self.processing = False
        self._lock = threading.Lock()

    async def load_model(self):
        # TODO: Allow choosing custom model cache path/download source when needed.
        self.session = new_session(self.model_name)
        self.loaded = True

    async def switch_model(self, model_name: str):
        self.model_name = model_name
        self.loaded = False
        await self.load_model()

    async def remove_background(
        self,
        input_path: str,
        output_path: str,
        alpha_matting: bool = False,
        alpha_matting_foreground_threshold: int = 240,
        alpha_matting_background_threshold: int = 10,
        alpha_matting_erode_size: int = 10,
    ) -> dict:
        with self._lock:
            self.processing = True
            try:
                start_time = time.time()
                input_img = Image.open(input_path)
                input_width, input_height = input_img.size

                if input_img.mode not in ("RGB", "RGBA"):
                    input_img = input_img.convert("RGB")

                output_img = remove(
                    input_img,
                    session=self.session,
                    alpha_matting=alpha_matting,
                    alpha_matting_foreground_threshold=alpha_matting_foreground_threshold,
                    alpha_matting_background_threshold=alpha_matting_background_threshold,
                    alpha_matting_erode_size=alpha_matting_erode_size,
                )

                if output_img.mode != "RGBA":
                    output_img = output_img.convert("RGBA")

                output_path_obj = Path(output_path)
                output_path_obj.parent.mkdir(parents=True, exist_ok=True)
                output_img.save(str(output_path_obj), "PNG", optimize=True)

                return {
                    "output_path": str(output_path_obj),
                    "input_width": input_width,
                    "input_height": input_height,
                    "output_width": output_img.width,
                    "output_height": output_img.height,
                    "output_file_size_bytes": output_path_obj.stat().st_size,
                    "processing_time_seconds": time.time() - start_time,
                }
            finally:
                self.processing = False
