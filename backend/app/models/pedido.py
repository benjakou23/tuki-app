import uuid
from sqlalchemy import Column, String, Float, DateTime, ForeignKey, Enum as SAEnum, Text
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base
from datetime import datetime
import enum

class EstadoPedido(str, enum.Enum):
    pendiente = "pendiente"
    aceptado = "aceptado"
    confirmado = "confirmado"
    en_camino = "en_camino"
    en_progreso = "en_progreso"
    completado = "completado"
    cancelado = "cancelado"
    expirado = "expirado"

class Pedido(Base):
    __tablename__ = "pedidos"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    cliente_id = Column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=False)
    tecnico_id = Column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=True)
    categoria = Column(String, nullable=False)
    descripcion = Column(Text, nullable=False)
    direccion = Column(String, nullable=False)
    distrito = Column(String, nullable=False)
    lat = Column(Float, nullable=True)
    lng = Column(Float, nullable=True)
    estado = Column(SAEnum(EstadoPedido), default=EstadoPedido.pendiente)
    precio_estimado_min = Column(Float, nullable=True)
    precio_estimado_max = Column(Float, nullable=True)
    precio_acordado = Column(Float, nullable=True)
    precio_final = Column(Float, nullable=True)
    comision_tuki = Column(Float, nullable=True)
    pago_metodo = Column(String, nullable=True)
    nota_tecnico = Column(String, nullable=True)
    calificacion = Column(Float, nullable=True)
    comentario_calificacion = Column(Text, nullable=True)
    creado_en = Column(DateTime, default=datetime.utcnow)
    actualizado_en = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    aceptado_en = Column(DateTime, nullable=True)
    completado_en = Column(DateTime, nullable=True)