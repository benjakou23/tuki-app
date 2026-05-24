from pydantic import BaseModel
from typing import Optional
from uuid import UUID
from datetime import datetime
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
    fecha_programada: Optional[datetime] = None

class PedidoRespuesta(BaseModel):
    id: UUID
    cliente_id: UUID
    tecnico_id: Optional[UUID] = None
    categoria: str
    descripcion: str
    direccion: str
    distrito: str
    estado: EstadoPedido
    precio_estimado_min: Optional[float] = None
    precio_estimado_max: Optional[float] = None
    precio_acordado: Optional[float] = None
    fecha_programada: Optional[datetime] = None
    creado_en: datetime

    class Config:
        from_attributes = True

class ActualizarEstado(BaseModel):
    estado: EstadoPedido
    precio_acordado: Optional[float] = None