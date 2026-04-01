"""
Utils module for Foundry Slag.

Image processing utilities for edge refinement, background replacement,
and export handling.
"""

import io
from typing import Optional
from PIL import Image, ImageFilter, ImageDraw


# Constants
MAX_IMAGE_SIZE = 50 * 1024 * 1024  # 50MB
SUPPORTED_FORMATS = {"JPEG", "PNG", "WEBP", "BMP", "TIFF"}
SUPPORTED_MIME_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
    "image/bmp",
    "image/tiff",
}


def validate_image(image_data: bytes) -> tuple[bool, Optional[str]]:
    """
    Validate image data.
    
    Returns:
        tuple of (is_valid, error_message)
    """
    if len(image_data) > MAX_IMAGE_SIZE:
        return False, f"Image too large. Max size: {MAX_IMAGE_SIZE // (1024*1024)}MB"
    
    try:
        image = Image.open(io.BytesIO(image_data))
        if image.format not in SUPPORTED_FORMATS:
            return False, f"Unsupported format: {image.format}. Supported: {', '.join(SUPPORTED_FORMATS)}"
        return True, None
    except Exception as e:
        return False, f"Invalid image: {str(e)}"


def get_image_info(image_data: bytes) -> dict:
    """Get image metadata."""
    image = Image.open(io.BytesIO(image_data))
    return {
        "format": image.format,
        "mode": image.mode,
        "size": image.size,
        "width": image.width,
        "height": image.height,
    }


def feather_alpha(image: Image.Image, amount: int) -> Image.Image:
    """
    Apply gaussian blur to alpha channel for soft edges.
    
    Args:
        image: PIL Image with alpha channel
        amount: Blur radius (0-20)
    
    Returns:
        Image with feathered edges
    """
    if amount <= 0:
        return image
    
    # Ensure image has alpha channel
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    
    # Apply gaussian blur to alpha channel
    alpha = image.split()[3]
    blurred_alpha = alpha.filter(ImageFilter.GaussianBlur(radius=amount))
    
    # Merge back
    r, g, b, _ = image.split()
    result = Image.merge("RGBA", (r, g, b, blurred_alpha))
    
    return result


def shift_alpha(image: Image.Image, amount: int) -> Image.Image:
    """
    Erode or dilate alpha channel for edge adjustment.
    
    Args:
        image: PIL Image with alpha channel
        amount: Shift amount (-10 to 10)
            - Negative: erode (remove edge pixels)
            - Positive: dilate (add edge pixels)
    
    Returns:
        Image with shifted edges
    """
    if amount == 0:
        return image
    
    # Ensure image has alpha channel
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    
    alpha = image.split()[3]
    
    if amount > 0:
        # Dilate - expand the mask
        shifted_alpha = alpha.filter(ImageFilter.MaxFilter(size=amount * 2 + 1))
    else:
        # Erode - contract the mask  
        shifted_alpha = alpha.filter(ImageFilter.MinFilter(size=abs(amount) * 2 + 1))
    
    # Merge back
    r, g, b, _ = image.split()
    result = Image.merge("RGBA", (r, g, b, shifted_alpha))
    
    return result


def apply_feather_and_shift(
    image_data: bytes,
    feather: int = 0,
    shift: int = 0,
) -> bytes:
    """
    Apply feather and shift to an image.
    
    Args:
        image_data: PNG image bytes with alpha
        feather: Feather amount (0-20)
        shift: Shift amount (-10 to 10)
    
    Returns:
        Processed PNG bytes
    """
    image = Image.open(io.BytesIO(image_data))
    
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    
    # Apply feather first
    if feather > 0:
        image = feather_alpha(image, feather)
    
    # Apply shift
    if shift != 0:
        image = shift_alpha(image, shift)
    
    # Save to bytes
    output = io.BytesIO()
    image.save(output, format="PNG")
    return output.getvalue()


def add_background_color(
    image_data: bytes,
    background_color: str,
) -> bytes:
    """
    Add a solid background color to an image.
    
    Args:
        image_data: PNG/RGBA image bytes
        background_color: Hex color string (e.g., "#ffffff")
    
    Returns:
        RGB PNG bytes with background
    """
    image = Image.open(io.BytesIO(image_data))
    
    # Ensure RGBA mode
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    
    # Parse color
    color = background_color.lstrip("#")
    if len(color) == 6:
        r = int(color[0:2], 16)
        g = int(color[2:4], 16)
        b = int(color[4:6], 16)
    else:
        r, g, b = 255, 255, 255  # Default white
    
    # Create background
    background = Image.new("RGB", image.size, (r, g, b))
    
    # Composite
    background.paste(image, (0, 0), image)
    
    # Save to bytes
    output = io.BytesIO()
    background.save(output, format="PNG")
    return output.getvalue()


def add_drop_shadow(
    image_data: bytes,
    blur: int = 10,
    offset: tuple[int, int] = (5, 5),
    opacity: float = 0.5,
    color: tuple[int, int, int] = (0, 0, 0),
) -> bytes:
    """
    Add a drop shadow to an image.
    
    Args:
        image_data: RGBA image bytes
        blur: Shadow blur radius
        offset: Shadow offset (x, y)
        opacity: Shadow opacity (0-1)
        color: Shadow color RGB
    
    Returns:
        RGBA PNG bytes with shadow
    """
    image = Image.open(io.BytesIO(image_data))
    
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    
    # Create shadow
    shadow = image.copy()
    
    # Create shadow mask with opacity
    shadow_alpha = shadow.split()[3]
    shadow_alpha = shadow_alpha.point(lambda p: int(p * opacity))
    shadow.putalpha(shadow_alpha)
    
    # Blur shadow
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    
    # Offset shadow
    ox, oy = offset
    result = Image.new("RGBA", 
        (image.width + abs(ox), image.height + abs(oy)), 
        (0, 0, 0, 0)
    )
    
    # Position shadow
    sx = max(0, ox)
    sy = max(0, oy)
    result.paste(shadow, (sx, sy))
    
    # Position original image
    tx = max(0, -ox)
    ty = max(0, -oy)
    result.paste(image, (tx, ty), image)
    
    # Save to bytes
    output = io.BytesIO()
    result.save(output, format="PNG")
    return output.getvalue()


def compose_final_image(
    image_data: bytes,
    background_color: Optional[str] = None,
    shadow: Optional[dict] = None,
) -> bytes:
    """
    Compose final image with optional background and shadow.
    
    Args:
        image_data: RGBA image bytes
        background_color: Optional hex color for background
        shadow: Optional shadow config {blur, offset_x, offset_y, opacity}
    
    Returns:
        Final composed image bytes
    """
    image = Image.open(io.BytesIO(image_data))
    
    if image.mode != "RGBA":
        image = image.convert("RGBA")
    
    # Apply shadow if specified
    if shadow:
        image = add_drop_shadow(
            io.BytesIO(image_data).read(),  # Original bytes
            blur=shadow.get("blur", 10),
            offset=(shadow.get("offsetX", 5), shadow.get("offsetY", 5)),
            opacity=shadow.get("opacity", 0.5),
        )
        image = Image.open(io.BytesIO(image))
    
    # Apply background color if specified
    if background_color:
        image = add_background_color(
            bytes(Image.open(io.BytesIO(image_data)).tobytes()),
            background_color,
        )
        image = Image.open(io.BytesIO(image))
    
    # Save to bytes
    output = io.BytesIO()
    image.save(output, format="PNG")
    return output.getvalue()


def export_image(
    image_data: bytes,
    format: str = "png",
    quality: int = 95,
) -> bytes:
    """
    Export image in specified format.
    
    Args:
        image_data: Input image bytes
        format: Export format (png, webp, jpg)
        quality: Quality for lossy formats
    
    Returns:
        Exported image bytes
    """
    image = Image.open(io.BytesIO(image_data))
    
    # Handle format
    format_lower = format.lower()
    
    if format_lower == "png":
        output = io.BytesIO()
        image.save(output, format="PNG")
        return output.getvalue()
    
    elif format_lower in ("jpg", "jpeg"):
        # Convert to RGB for JPEG (no alpha)
        if image.mode in ("RGBA", "LA"):
            # Create white background
            background = Image.new("RGB", image.size, (255, 255, 255))
            background.paste(image, mask=image.split()[-1])
            image = background
        elif image.mode != "RGB":
            image = image.convert("RGB")
        
        output = io.BytesIO()
        image.save(output, format="JPEG", quality=quality)
        return output.getvalue()
    
    elif format_lower == "webp":
        output = io.BytesIO()
        image.save(output, format="WEBP", quality=quality)
        return output.getvalue()
    
    else:
        raise ValueError(f"Unsupported export format: {format}")


def resize_image(
    image_data: bytes,
    max_width: int = 2000,
    max_height: int = 2000,
) -> bytes:
    """
    Resize image if it exceeds max dimensions.
    
    Args:
        image_data: Input image bytes
        max_width: Maximum width
        max_height: Maximum height
    
    Returns:
        Resized image bytes
    """
    image = Image.open(io.BytesIO(image_data))
    
    if image.width <= max_width and image.height <= max_height:
        return image_data
    
    # Calculate new size maintaining aspect ratio
    ratio = min(max_width / image.width, max_height / image.height)
    new_size = (int(image.width * ratio), int(image.height * ratio))
    
    image = image.resize(new_size, Image.Resampling.LANCZOS)
    
    output = io.BytesIO()
    image.save(output, format="PNG")
    return output.getvalue()


def image_to_base64(image_data: bytes, mime_type: str = "image/png") -> str:
    """Convert image bytes to base64 data URL."""
    import base64
    b64 = base64.b64encode(image_data).decode("utf-8")
    return f"data:{mime_type};base64,{b64}"


def base64_to_bytes(base64_string: str) -> bytes:
    """Convert base64 data URL to image bytes."""
    import base64
    if "base64," in base64_string:
        _, b64 = base64_string.split("base64,", 1)
        return base64.b64decode(b64)
    return base64.b64decode(base64_string)
