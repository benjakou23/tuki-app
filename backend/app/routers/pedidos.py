from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.pedido import Pedido, EstadoPedido
from app.models.tecnico import Tecnico
from app.schemas.pedido import PedidoCrear, PedidoRespuesta, ActualizarEstado
from typing import List

router = APIRouter(prefix="/pedidos", tags=["pedidos"])

@router.post("/", response_model=PedidoRespuesta, status_code=201)
def crear_pedido(datos: PedidoCrear, cliente_id: str, db: Session = Depends(get_db)):
    pedido = Pedido(
        cliente_id=cliente_id,
        categoria=datos.categoria,
        descripcion=datos.descripcion,
        direccion=datos.direccion,
        distrito=datos.distrito,
        lat=datos.lat,
        lng=datos.lng,
        precio_estimado_min=datos.precio_estimado_min,
        precio_estimado_max=datos.precio_estimado_max,
        fecha_programada=datos.fecha_programada,
    )
    db.add(pedido)
    db.commit()
    db.refresh(pedido)
    return pedido

@router.get("/", response_model=List[PedidoRespuesta])
def listar_pedidos(cliente_id: str = None, tecnico_id: str = None, 
                   estado: EstadoPedido = None, db: Session = Depends(get_db)):
    query = db.query(Pedido)
    if cliente_id:
        query = query.filter(Pedido.cliente_id == cliente_id)
    if tecnico_id:
        query = query.filter(Pedido.tecnico_id == tecnico_id)
    if estado:
        query = query.filter(Pedido.estado == estado)
    return query.order_by(Pedido.creado_en.desc()).all()

@router.get("/{pedido_id}", response_model=PedidoRespuesta)
def obtener_pedido(pedido_id: str, db: Session = Depends(get_db)):
    pedido = db.query(Pedido).filter(Pedido.id == pedido_id).first()
    if not pedido:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")
    return pedido

@router.patch("/{pedido_id}/estado", response_model=PedidoRespuesta)
def actualizar_estado(pedido_id: str, datos: ActualizarEstado, db: Session = Depends(get_db)):
    pedido = db.query(Pedido).filter(Pedido.id == pedido_id).first()
    if not pedido:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")
    pedido.estado = datos.estado
    if datos.precio_acordado:
        pedido.precio_acordado = datos.precio_acordado
    db.commit()
    db.refresh(pedido)
    return pedido

@router.patch("/{pedido_id}/asignar-tecnico", response_model=PedidoRespuesta)
def asignar_tecnico(pedido_id: str, tecnico_id: str, db: Session = Depends(get_db)):
    pedido = db.query(Pedido).filter(Pedido.id == pedido_id).first()
    if not pedido:
        raise HTTPException(status_code=404, detail="Pedido no encontrado")
    tecnico = db.query(Tecnico).filter(Tecnico.id == tecnico_id).first()
    if not tecnico:
        raise HTTPException(status_code=404, detail="Técnico no encontrado")
    pedido.tecnico_id = tecnico_id
    pedido.estado = EstadoPedido.confirmado
    db.commit()
    db.refresh(pedido)
    return pedido