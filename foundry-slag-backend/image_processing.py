"""Image processing utilities for Foundry Slag."""

from pathlib import Path
import zipfile

from PIL import Image, ImageDraw, ImageFilter

from config import MAX_FILE_SIZE_MB, MAX_IMAGE_DIMENSION, SUPPORTED_INPUT_FORMATS


def validate_image(file_path: str) -> dict:
    path = Path(file_path)
    if not path.exists():
        return {"valid": False, "error": "File not found"}
    if path.suffix.lower() not in SUPPORTED_INPUT_FORMATS:
        return {"valid": False, "error": f"Unsupported format: {path.suffix}"}
    size = path.stat().st_size
    if size > MAX_FILE_SIZE_MB * 1024 * 1024:
        return {"valid": False, "error": "File too large"}
    try:
        with Image.open(path) as img:
            w, h = img.size
            if w > MAX_IMAGE_DIMENSION or h > MAX_IMAGE_DIMENSION:
                return {"valid": False, "error": "Image too large"}
            if w < 10 or h < 10:
                return {"valid": False, "error": "Image too small"}
            return {
                "valid": True,
                "error": None,
                "width": w,
                "height": h,
                "format": img.format or path.suffix.lstrip(".").upper(),
                "mode": img.mode,
                "file_size_bytes": size,
            }
    except Exception as exc:
        return {"valid": False, "error": f"Could not read image: {exc}"}


def create_checkerboard(width: int, height: int, square_size: int = 10) -> Image.Image:
    img = Image.new("RGB", (width, height))
    draw = ImageDraw.Draw(img)
    light, dark = (220, 220, 220), (180, 180, 180)
    for y in range(0, height, square_size):
        for x in range(0, width, square_size):
            color = light if (x // square_size + y // square_size) % 2 == 0 else dark
            draw.rectangle([x, y, x + square_size, y + square_size], fill=color)
    return img


def create_thumbnail(input_path: str, output_path: str, size=(400, 400)) -> str:
    path = Path(output_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(input_path) as img:
        if img.mode == "RGBA":
            img.thumbnail(size, Image.Resampling.LANCZOS)
            checker = create_checkerboard(img.width, img.height)
            checker.paste(img, mask=img.split()[3])
            checker.save(path, "PNG")
        else:
            img.thumbnail(size, Image.Resampling.LANCZOS)
            img.save(path, "PNG")
    return str(path)


def apply_edge_refinement(img: Image.Image, feather: float = 0, shift: float = 0) -> Image.Image:
    if img.mode != "RGBA":
        return img
    r, g, b, a = img.split()
    if shift != 0:
        kernel = max(3, int(abs(shift) * 2 + 1) | 1)
        a = a.filter(ImageFilter.MaxFilter(kernel) if shift > 0 else ImageFilter.MinFilter(kernel))
    if feather > 0:
        a = a.filter(ImageFilter.GaussianBlur(radius=feather))
    return Image.merge("RGBA", (r, g, b, a))


def apply_background(img: Image.Image, bg_type: str = "transparent", bg_color: str = "#FFFFFF", bg_image_path: str | None = None) -> Image.Image:
    if bg_type == "transparent":
        return img
    if bg_type == "color":
        c = bg_color.lstrip("#")
        r, g, b = int(c[0:2], 16), int(c[2:4], 16), int(c[4:6], 16)
        bg = Image.new("RGBA", img.size, (r, g, b, 255))
        bg.paste(img, mask=img.split()[3])
        return bg
    if bg_type == "image" and bg_image_path:
        bg = Image.open(bg_image_path).convert("RGBA").resize(img.size, Image.Resampling.LANCZOS)
        bg.paste(img, mask=img.split()[3])
        return bg
    return img


def apply_drop_shadow(img: Image.Image, opacity: float = 0.3, offset_x: float = 5, offset_y: float = 5, blur: float = 10) -> Image.Image:
    if img.mode != "RGBA":
        return img
    _, _, _, a = img.split()
    shadow_alpha = a.filter(ImageFilter.GaussianBlur(radius=blur)).point(lambda x: int(x * opacity))
    pad = int(blur * 2 + max(abs(offset_x), abs(offset_y)))
    shadow = Image.new("RGBA", (img.width + pad * 2, img.height + pad * 2), (0, 0, 0, 0))
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    layer.putalpha(shadow_alpha)
    shadow.paste(layer, (pad + int(offset_x), pad + int(offset_y)))
    shadow.paste(img, (pad, pad), mask=a)
    return shadow


def export_image(img: Image.Image, output_path: str, format: str = "png", quality: int = 95) -> dict:
    path = Path(output_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    f = format.lower()
    if f == "png":
        img.save(path, "PNG", optimize=True)
    elif f == "webp":
        img.save(path, "WEBP", quality=quality, lossless=False)
    elif f in ("jpg", "jpeg"):
        if img.mode == "RGBA":
            bg = Image.new("RGB", img.size, (255, 255, 255))
            bg.paste(img, mask=img.split()[3])
            bg.save(path, "JPEG", quality=quality)
        else:
            img.save(path, "JPEG", quality=quality)
    else:
        raise ValueError("Unsupported export format")
    return {"path": str(path), "file_size_bytes": path.stat().st_size}


def create_batch_zip(image_entries: list[dict], output_path: str) -> str:
    zip_path = Path(output_path) / "foundry_slag_export.zip"
    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for entry in image_entries:
            zf.write(entry["path"], f"slagged/{entry['filename']}")
    return str(zip_path)
