from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.usuario import Usuario
from app.models.tecnico import Tecnico
from pydantic import BaseModel
from typing import Optional, List
from jose import jwt, JWTError
import os

router = APIRouter(prefix="/perfil", tags=["perfil"])

class PerfilTecnicoUpdate(BaseModel):
    bio: Optional[str] = None
    precio_minimo: Optional[float] = None
    distrito: Optional[str] = None

class SolicitudEspecialidades(BaseModel):
    especialidades: List[str]
    motivo: Optional[str] = None

def get_usuario(authorization: str = Header(None), db: Session = Depends(get_db)):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="No autorizado")
    try:
        payload = jwt.decode(authorization.split(" ")[1],
            os.getenv("SECRET_KEY"), algorithms=[os.getenv("ALGORITHM")])
        uid = payload.get("sub")
    except JWTError:
        raise HTTPException(status_code=401, detail="Token inválido")
    u = db.query(Usuario).filter(Usuario.id == uid).first()
    if not u:
        raise HTTPException(status_code=404, detail="No encontrado")
    return u

@router.get("/tecnico")
def get_perfil_tecnico(
    u: Usuario = Depends(get_usuario),
    db: Session = Depends(get_db)
):
    tecnico = db.query(Tecnico).filter(
        Tecnico.usuario_id == u.id).first()
    if not tecnico:
        return {
            "tiene_perfil": False,
            "especialidades": [],
            "bio": None,
            "precio_minimo": None,
            "distrito": u.distrito,
            "calificacion": 0,
            "trabajos_completados": 0,
        }
    return {
        "tiene_perfil": True,
        "especialidades": tecnico.especialidades or [],
        "bio": tecnico.bio,
        "precio_minimo": tecnico.precio_minimo,
        "distrito": tecnico.distrito,
        "calificacion": tecnico.calificacion,
        "trabajos_completados": tecnico.trabajos_completados,
        "id_verificado": tecnico.id_verificado,
    }

@router.patch("/tecnico")
def actualizar_perfil_tecnico(
    datos: PerfilTecnicoUpdate,
    u: Usuario = Depends(get_usuario),
    db: Session = Depends(get_db)
):
    tecnico = db.query(Tecnico).filter(
        Tecnico.usuario_id == u.id).first()
    if not tecnico:
        raise HTTPException(404, "Perfil técnico no encontrado")

    if datos.bio is not None:
        tecnico.bio = datos.bio
    if datos.precio_minimo is not None:
        tecnico.precio_minimo = datos.precio_minimo
    if datos.distrito is not None:
        tecnico.distrito = datos.distrito

    db.commit()
    db.refresh(tecnico)
    return {"mensaje": "Perfil actualizado", "tecnico": {
        "bio": tecnico.bio,
        "precio_minimo": tecnico.precio_minimo,
        "distrito": tecnico.distrito,
        "especialidades": tecnico.especialidades,
    }}



@router.get("/tecnico-publico/{usuario_id}")
def get_perfil_tecnico_publico(usuario_id: str, db: Session = Depends(get_db)):
    from app.models.tecnico import Tecnico
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    tecnico = db.query(Tecnico).filter(
        Tecnico.usuario_id == usuario_id).first()
    if not usuario:
        raise HTTPException(404, "No encontrado")
    return {
        "nombre": usuario.nombre,
        "especialidades": tecnico.especialidades if tecnico else [],
        "calificacion": tecnico.calificacion if tecnico else 0,
        "trabajos_completados": tecnico.trabajos_completados if tecnico else 0,
    }
@router.post("/tecnico/solicitar-especialidades")
def solicitar_especialidades(
    datos: SolicitudEspecialidades,
    u: Usuario = Depends(get_usuario),
    db: Session = Depends(get_db)
):
    if u.rol.value != "tecnico":
        raise HTTPException(403, "Solo técnicos")

    # Guardamos la solicitud como nota en el usuario
    # En producción esto iría a una tabla separada
    u.motivo_rechazo = f"SOLICITUD_ESPECIALIDADES:{','.join(datos.especialidades)}"
    db.commit()

    return {
        "mensaje": "Solicitud enviada. El admin revisará en 24-48 horas.",
        "especialidades_solicitadas": datos.especialidades
    }