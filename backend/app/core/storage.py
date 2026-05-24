import os
import uuid
from pathlib import Path

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

def guardar_archivo(contenido: bytes, extension: str) -> str:
    nombre = f"{uuid.uuid4()}.{extension}"
    ruta = UPLOAD_DIR / nombre
    with open(ruta, "wb") as f:
        f.write(contenido)
    return f"/uploads/{nombre}"