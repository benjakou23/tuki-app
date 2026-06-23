from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.pedido import Pedido, EstadoPedido
from app.models.usuario import Usuario
from app.models.suscripcion import Suscripcion, EstadoSuscripcion
from app.schemas.pedido import PedidoCrear, PedidoRespuesta, PedidoAccion, PedidoCalificar
from typing import List, Optional
from datetime import datetime
from jose import jwt, JWTError
import os

router = APIRouter(prefix="/pedidos", tags=["pedidos"])
COMISION = 0.08

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

def suscripcion_activa(tecnico_id, db):
    return db.query(Suscripcion).filter(
        Suscripcion.tecnico_id == tecnico_id,
        Suscripcion.estado == EstadoSuscripcion.activa,
        Suscripcion.vencimiento > datetime.utcnow()
    ).first() is not None

@router.post("/", response_model=PedidoRespuesta, status_code=201)

@router.get("/disponibles", response_model=List[PedidoRespuesta])
def pedidos_disponibles(distrito: Optional[str] = None,
    categoria: Optional[str] = None,
    u: Usuario = Depends(get_usuario), db: Session = Depends(get_db)):
    if u.rol.value != "tecnico":
        raise HTTPException(403, "Solo técnicos")
    q = db.query(Pedido).filter(
        Pedido.estado == EstadoPedido.pendiente,
        Pedido.tecnico_id == None)
    if distrito: q = q.filter(Pedido.distrito == distrito)
    if categoria: q = q.filter(Pedido.categoria == categoria)
    return q.order_by(Pedido.creado_en.desc()).all()

@router.get("/mis-pedidos", response_model=List[PedidoRespuesta])
def mis_pedidos(u: Usuario = Depends(get_usuario), db: Session = Depends(get_db)):
    if u.rol.value == "cliente":
        return db.query(Pedido).filter(
            Pedido.cliente_id == u.id
        ).order_by(Pedido.creado_en.desc()).all()
    return db.query(Pedido).filter(
        Pedido.tecnico_id == u.id
    ).order_by(Pedido.creado_en.desc()).all()

@router.get("/mis-ganancias")
def mis_ganancias(
    u: Usuario = Depends(get_usuario),
    db: Session = Depends(get_db)
):
    if u.rol.value != "tecnico":
        raise HTTPException(403, "Solo técnicos")
    
    from datetime import datetime, timedelta
    from sqlalchemy import extract, func
    
    ahora = datetime.utcnow()
    inicio_mes = ahora.replace(day=1, hour=0, minute=0, second=0)
    
    # Pedidos completados
    pedidos = db.query(Pedido).filter(
        Pedido.tecnico_id == u.id,
        Pedido.estado == EstadoPedido.completado,
        Pedido.precio_final != None
    ).order_by(Pedido.completado_en.desc()).all()
    
    # Stats del mes
    pedidos_mes = [p for p in pedidos 
        if p.completado_en and p.completado_en >= inicio_mes]
    
    total_mes = sum(p.precio_final or 0 for p in pedidos_mes)
    comision_mes = sum(p.comision_tuki or 0 for p in pedidos_mes)
    neto_mes = total_mes - comision_mes
    
    total_historico = sum(p.precio_final or 0 for p in pedidos)
    
    return {
        "total_mes": round(total_mes, 2),
        "comision_mes": round(comision_mes, 2),
        "neto_mes": round(neto_mes, 2),
        "trabajos_mes": len(pedidos_mes),
        "total_historico": round(total_historico, 2),
        "trabajos_total": len(pedidos),
        "pedidos": [{
            "id": str(p.id),
            "categoria": p.categoria,
            "distrito": p.distrito,
            "precio_final": p.precio_final,
            "comision_tuki": p.comision_tuki,
            "neto": round((p.precio_final or 0) - (p.comision_tuki or 0), 2),
            "completado_en": p.completado_en.isoformat() if p.completado_en else None,
        } for p in pedidos]
    }

@router.get("/{pedido_id}")
def obtener_pedido(pedido_id: str,
    u: Usuario = Depends(get_usuario), db: Session = Depends(get_db)):
    p = db.query(Pedido).filter(Pedido.id == pedido_id).first()
    if not p: raise HTTPException(404, "No encontrado")
    
    resultado = {c.name: getattr(p, c.name) for c in p.__table__.columns}
    resultado['id'] = str(p.id)
    resultado['cliente_id'] = str(p.cliente_id)
    if p.tecnico_id:
        resultado['tecnico_id'] = str(p.tecnico_id)
        tecnico = db.query(Usuario).filter(
            Usuario.id == p.tecnico_id).first()
        resultado['tecnico_nombre'] = tecnico.nombre if tecnico else None
    cliente = db.query(Usuario).filter(
        Usuario.id == p.cliente_id).first()
    resultado['cliente_nombre'] = cliente.nombre if cliente else None
    return resultado






@router.post("/{pedido_id}/accion", response_model=PedidoRespuesta)
def accionar(pedido_id: str, datos: PedidoAccion,
    u: Usuario = Depends(get_usuario), db: Session = Depends(get_db)):
    p = db.query(Pedido).filter(Pedido.id == pedido_id).first()
    if not p: raise HTTPException(404, "No encontrado")

    if datos.accion == "aceptar":
        if u.rol.value != "tecnico":
            raise HTTPException(403, "Solo técnicos")
        if not suscripcion_activa(u.id, db):
            raise HTTPException(403, "Necesitas suscripción activa")
        if p.estado != EstadoPedido.pendiente:
            raise HTTPException(400, "Pedido no disponible")
        p.tecnico_id = u.id
        p.estado = EstadoPedido.aceptado
        p.precio_acordado = datos.precio_acordado
        p.nota_tecnico = datos.nota_tecnico
        p.aceptado_en = datetime.utcnow()

    elif datos.accion == "confirmar":
        if u.rol.value != "cliente" or str(p.cliente_id) != str(u.id):
            raise HTTPException(403, "No autorizado")
        if p.estado != EstadoPedido.aceptado:
            raise HTTPException(400, "El técnico aún no aceptó")
        p.estado = EstadoPedido.confirmado

    elif datos.accion == "en_camino":
        if str(p.tecnico_id) != str(u.id):
            raise HTTPException(403, "No es tu pedido")
        if p.estado != EstadoPedido.confirmado:
            raise HTTPException(400, "Pedido no confirmado")
        p.estado = EstadoPedido.en_camino

    elif datos.accion == "llegar":
        if str(p.tecnico_id) != str(u.id):
            raise HTTPException(403, "No es tu pedido")
        p.estado = EstadoPedido.en_progreso

    elif datos.accion == "completar":
        if str(p.tecnico_id) != str(u.id):
            raise HTTPException(403, "No es tu pedido")
        precio = datos.precio_final or p.precio_acordado or 0
        p.estado = EstadoPedido.completado
        p.precio_final = precio
        p.comision_tuki = round(precio * COMISION, 2)
        p.completado_en = datetime.utcnow()

    elif datos.accion == "cancelar":
        if str(p.cliente_id) != str(u.id) and str(p.tecnico_id) != str(u.id):
            raise HTTPException(403, "No puedes cancelar")
        p.estado = EstadoPedido.cancelado

    else:
        raise HTTPException(400, "Acción inválida")

    p.actualizado_en = datetime.utcnow()
    db.commit(); db.refresh(p)
    return p

@router.post("/{pedido_id}/calificar", response_model=PedidoRespuesta)
def calificar(pedido_id: str, datos: PedidoCalificar,
    u: Usuario = Depends(get_usuario), db: Session = Depends(get_db)):
    p = db.query(Pedido).filter(Pedido.id == pedido_id).first()
    if not p: raise HTTPException(404, "No encontrado")
    if str(p.cliente_id) != str(u.id):
        raise HTTPException(403, "Solo el cliente califica")
    if p.estado != EstadoPedido.completado:
        raise HTTPException(400, "Solo pedidos completados")
    if p.calificacion is not None:
        raise HTTPException(400, "Ya calificaste")
    if not 1.0 <= datos.calificacion <= 5.0:
        raise HTTPException(400, "Entre 1 y 5")
    p.calificacion = datos.calificacion
    p.comentario_calificacion = datos.comentario
    db.commit(); db.refresh(p)
    return p