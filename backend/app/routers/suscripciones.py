from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.suscripcion import Suscripcion, EstadoSuscripcion
from app.models.usuario import Usuario
from datetime import datetime, timedelta
from jose import jwt, JWTError
import os

router = APIRouter(prefix="/suscripciones", tags=["suscripciones"])

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
    if not u: raise HTTPException(404, "No encontrado")
    return u

@router.get("/mi-suscripcion")
def mi_suscripcion(u: Usuario = Depends(get_usuario),
    db: Session = Depends(get_db)):
    sus = db.query(Suscripcion).filter(
        Suscripcion.tecnico_id == u.id,
        Suscripcion.estado == EstadoSuscripcion.activa
    ).order_by(Suscripcion.vencimiento.desc()).first()

    if not sus or sus.vencimiento < datetime.utcnow():
        if sus:
            sus.estado = EstadoSuscripcion.vencida
            db.commit()
        return {"activa": False, "dias_restantes": 0}

    return {
        "activa": True,
        "vencimiento": sus.vencimiento,
        "dias_restantes": (sus.vencimiento - datetime.utcnow()).days,
        "monto": sus.monto,
    }

@router.post("/activar")
def activar(u: Usuario = Depends(get_usuario),
    db: Session = Depends(get_db)):
    if u.rol.value != "tecnico":
        raise HTTPException(403, "Solo técnicos")
    nueva = Suscripcion(
        tecnico_id=u.id,
        estado=EstadoSuscripcion.activa,
        monto=35.0,
        inicio=datetime.utcnow(),
        vencimiento=datetime.utcnow() + timedelta(days=30),
        metodo_pago="manual_prueba",
    )
    db.add(nueva); db.commit(); db.refresh(nueva)
    return {"mensaje": "Suscripción activada 30 días",
            "vencimiento": nueva.vencimiento}