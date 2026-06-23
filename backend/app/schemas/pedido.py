from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional
from app.models.pedido import EstadoPedido

class PedidoCrear(BaseModel):
    categoria: str
    descripcion: str
    direccion: str
    distrito: str
    lat: Optional[float] = None
    lng: Optional[float] = None
    precio_estimado_min: Optional[float] = None
    precio_estimado_max: Optional[float] = None

class PedidoRespuesta(BaseModel):
    id: UUID
    cliente_id: UUID
    tecnico_id: Optional[UUID] = None
    categoria: str
    descripcion: str
    direccion: str
    distrito: str
    lat: Optional[float] = None
    lng: Optional[float] = None
    estado: EstadoPedido
    precio_estimado_min: Optional[float] = None
    precio_estimado_max: Optional[float] = None
    precio_acordado: Optional[float] = None
    precio_final: Optional[float] = None
    comision_tuki: Optional[float] = None
    pago_metodo: Optional[str] = None
    nota_tecnico: Optional[str] = None
    calificacion: Optional[float] = None
    comentario_calificacion: Optional[str] = None
    creado_en: datetime
    actualizado_en: datetime
    aceptado_en: Optional[datetime] = None
    completado_en: Optional[datetime] = None

    class Config:
        from_attributes = True

class PedidoAccion(BaseModel):
    accion: str
    precio_acordado: Optional[float] = None
    precio_final: Optional[float] = None
    nota_tecnico: Optional[str] = None

class PedidoCalificar(BaseModel):
    calificacion: float
    comentario: Optional[str] = None