from sqlalchemy import Column, String, DateTime, Enum, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base
from datetime import datetime
import uuid
import enum

class TipoDocumento(str, enum.Enum):
    dni_anverso = "dni_anverso"
    dni_reverso = "dni_reverso"
    selfie_dni = "selfie_dni"
    certificado = "certificado"
    foto_trabajo = "foto_trabajo"
    ruc = "ruc"

class EstadoDocumento(str, enum.Enum):
    pendiente = "pendiente"
    aprobado = "aprobado"
    rechazado = "rechazado"

class Documento(Base):
    __tablename__ = "documentos"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    usuario_id = Column(UUID(as_uuid=True),
                       ForeignKey("usuarios.id"), nullable=False)
    tipo = Column(Enum(TipoDocumento), nullable=False)
    url = Column(String(500), nullable=False)
    estado = Column(Enum(EstadoDocumento),
                   default=EstadoDocumento.pendiente)
    nota_admin = Column(Text, nullable=True)
    subido_en = Column(DateTime, default=datetime.utcnow)
    revisado_en = Column(DateTime, nullable=True)

    usuario = relationship("Usuario", backref="documentos")