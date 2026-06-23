import uuid
from sqlalchemy import Column, String, Float, DateTime, ForeignKey, Enum as SAEnum
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base
from datetime import datetime
import enum

class EstadoSuscripcion(str, enum.Enum):
    activa = "activa"
    vencida = "vencida"
    cancelada = "cancelada"

class Suscripcion(Base):
    __tablename__ = "suscripciones"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    tecnico_id = Column(UUID(as_uuid=True), ForeignKey("usuarios.id"), nullable=False)
    estado = Column(SAEnum(EstadoSuscripcion), default=EstadoSuscripcion.activa)
    monto = Column(Float, default=35.0)
    inicio = Column(DateTime, default=datetime.utcnow)
    vencimiento = Column(DateTime, nullable=False)
    metodo_pago = Column(String, nullable=True)
    creado_en = Column(DateTime, default=datetime.utcnow)