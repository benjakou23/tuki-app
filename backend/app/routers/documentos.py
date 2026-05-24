from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.documento import Documento, TipoDocumento, EstadoDocumento
from app.models.usuario import Usuario, EstadoVerificacion
from app.core.storage import guardar_archivo
from datetime import datetime
import os

router = APIRouter(prefix="/documentos", tags=["documentos"])

EXTENSIONES_PERMITIDAS = {"jpg", "jpeg", "png", "pdf"}
MAX_SIZE_MB = 10

@router.post("/subir")
async def subir_documento(
    usuario_id: str,
    tipo: TipoDocumento,
    archivo: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    # Validar extensión
    ext = archivo.filename.split(".")[-1].lower()
    if ext not in EXTENSIONES_PERMITIDAS:
        raise HTTPException(status_code=400,
            detail="Solo se permiten JPG, PNG o PDF")

    # Validar tamaño
    contenido = await archivo.read()
    if len(contenido) > MAX_SIZE_MB * 1024 * 1024:
        raise HTTPException(status_code=400,
            detail=f"El archivo no puede superar {MAX_SIZE_MB}MB")

    # Guardar archivo
    url = guardar_archivo(contenido, ext)

    # Registrar en BD
    doc = Documento(
        usuario_id=usuario_id,
        tipo=tipo,
        url=url,
    )
    db.add(doc)

    # Actualizar estado del usuario
    usuario = db.query(Usuario).filter(
        Usuario.id == usuario_id).first()
    if usuario:
        usuario.estado_verificacion = EstadoVerificacion.docs_enviados

    db.commit()
    db.refresh(doc)
    return {"mensaje": "Documento subido correctamente", "id": str(doc.id), "url": url}

@router.get("/usuario/{usuario_id}")
def documentos_usuario(usuario_id: str, db: Session = Depends(get_db)):
    docs = db.query(Documento).filter(
        Documento.usuario_id == usuario_id).all()
    return docs