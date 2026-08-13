from pathlib import Path
import tempfile, uuid

TEMP_DIR = Path(tempfile.gettempdir()) / "filekit"
TEMP_DIR.mkdir(exist_ok=True)

def tmp(ext: str) -> Path:
    """Tạo temp file path với UUID"""
    return TEMP_DIR / f"{uuid.uuid4()}{ext}"

def cleanup(*paths):
    """Xóa temp files sau khi xử lý xong"""
    for p in paths:
        Path(p).unlink(missing_ok=True)