from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.usuario import Usuario, EstadoVerificacion
from app.models.documento import Documento, EstadoDocumento
from app.models.tecnico import Tecnico
from app.models.pedido import Pedido
from datetime import datetime
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/admin", tags=["admin"])

class AccionVerificacion(BaseModel):
    accion: str  # aprobar | rechazar | suspender | pedir_mas
    motivo: Optional[str] = None

@router.get("/dashboard")
def dashboard(db: Session = Depends(get_db)):
    total_usuarios = db.query(Usuario).count()
    total_tecnicos = db.query(Tecnico).filter(
        Tecnico.activo == True).count()
    pendientes = db.query(Usuario).filter(
        Usuario.estado_verificacion.in_([
            EstadoVerificacion.docs_enviados,
            EstadoVerificacion.en_revision
        ])).count()
    verificados = db.query(Usuario).filter(
        Usuario.estado_verificacion == EstadoVerificacion.verificado
    ).count()
    total_pedidos = db.query(Pedido).count()

    return {
        "total_usuarios": total_usuarios,
        "total_tecnicos": total_tecnicos,
        "pendientes_verificacion": pendientes,
        "usuarios_verificados": verificados,
        "total_pedidos": total_pedidos,
    }

@router.get("/verificaciones/pendientes")
def verificaciones_pendientes(db: Session = Depends(get_db)):
    usuarios = db.query(Usuario).filter(
        Usuario.estado_verificacion.in_([
            EstadoVerificacion.docs_enviados,
            EstadoVerificacion.en_revision,
        ])
    ).order_by(Usuario.creado_en.asc()).all()

    resultado = []
    for u in usuarios:
        docs = db.query(Documento).filter(
            Documento.usuario_id == u.id).all()
        resultado.append({
            "id": str(u.id),
            "nombre": u.nombre,
            "telefono": u.telefono,
            "rol": u.rol,
            "dni_numero": u.dni_numero,
            "distrito": u.distrito,
            "estado_verificacion": u.estado_verificacion,
            "creado_en": u.creado_en,
            "documentos": [{
                "id": str(d.id),
                "tipo": d.tipo,
                "url": d.url,
                "estado": d.estado,
                "subido_en": d.subido_en,
            } for d in docs]
        })
    return resultado

@router.get("/usuarios")
def listar_usuarios(
    rol: str = None,
    estado: str = None,
    db: Session = Depends(get_db)
):
    query = db.query(Usuario)
    if rol:
        query = query.filter(Usuario.rol == rol)
    if estado:
        query = query.filter(
            Usuario.estado_verificacion == estado)
    usuarios = query.order_by(Usuario.creado_en.desc()).all()
    return [{
        "id": str(u.id),
        "nombre": u.nombre,
        "telefono": u.telefono,
        "email": u.email,
        "rol": u.rol,
        "dni_numero": u.dni_numero,
        "distrito": u.distrito,
        "estado_verificacion": u.estado_verificacion,
        "activo": u.activo,
        "creado_en": u.creado_en,
    } for u in usuarios]

@router.post("/verificaciones/{usuario_id}/accion")
def accionar_verificacion(
    usuario_id: str,
    datos: AccionVerificacion,
    db: Session = Depends(get_db)
):
    from app.core.email import enviar_aprobacion, enviar_rechazo

    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")

    if datos.accion == "aprobar":
        usuario.estado_verificacion = EstadoVerificacion.verificado
        usuario.motivo_rechazo = None
        tecnico = db.query(Tecnico).filter(
            Tecnico.usuario_id == usuario_id).first()
        if tecnico:
            tecnico.id_verificado = True
        db.commit()
        if usuario.email:
            try:
                enviar_aprobacion(usuario.nombre, usuario.email)
            except Exception:
                pass

    elif datos.accion == "rechazar":
        usuario.estado_verificacion = EstadoVerificacion.rechazado
        usuario.motivo_rechazo = datos.motivo
        db.commit()
        if usuario.email:
            try:
                enviar_rechazo(usuario.nombre, usuario.email, datos.motivo or "Documentos inválidos")
            except Exception:
                pass

    elif datos.accion == "suspender":
        usuario.estado_verificacion = EstadoVerificacion.suspendido
        usuario.activo = False
        db.commit()

    elif datos.accion == "pedir_mas":
        usuario.estado_verificacion = EstadoVerificacion.sin_verificar
        usuario.motivo_rechazo = datos.motivo
        db.commit()

    else:
        raise HTTPException(status_code=400, detail="Acción no válida")

    return {"mensaje": f"Acción '{datos.accion}' aplicada correctamente"}