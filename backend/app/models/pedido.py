from sqlalchemy import Column, String, Float, DateTime, Enum, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base
from datetime import datetime
import uuid
import enum

class EstadoPedido(str, enum.Enum):
    pendiente = "pendiente"
    confirmado = "confirmado"
    en_camino = "en_camino"
    llego = "llego"
    completado = "completado"
    cancelado = "cancelado"

class Pedido(Base):
    __tablename__ = "pedidos"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    cliente_id = Column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=False)
    tecnico_id = Column(UUID(as_uuid=True), ForeignKey("tecnicos.id"), nullable=True)
    categoria = Column(String(100), nullable=False)
    descripcion = Column(Text, nullable=False)
    direccion = Column(String(255), nullable=False)
    distrito = Column(String(100), nullable=False)
    lat = Column(Float, nullable=True)
    lng = Column(Float, nullable=True)
    estado = Column(Enum(EstadoPedido), default=EstadoPedido.pendiente)
    precio_estimado_min = Column(Float, nullable=True)
    precio_estimado_max = Column(Float, nullable=True)
    precio_acordado = Column(Float, nullable=True)
    fecha_programada = Column(DateTime, nullable=True)
    creado_en = Column(DateTime, default=datetime.utcnow)
    actualizado_en = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    cliente = relationship("Usuario", foreign_keys=[cliente_id])
    tecnico = relationship("Tecnico", foreign_keys=[tecnico_id])