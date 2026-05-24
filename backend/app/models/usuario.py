from sqlalchemy import Column, String, Boolean, DateTime, Enum, Date
from sqlalchemy.dialects.postgresql import UUID
from app.database import Base
from datetime import datetime
import uuid
import enum

class RolUsuario(str, enum.Enum):
    cliente = "cliente"
    tecnico = "tecnico"
    admin = "admin"

class EstadoVerificacion(str, enum.Enum):
    sin_verificar = "sin_verificar"
    docs_enviados = "docs_enviados"
    en_revision = "en_revision"
    verificado = "verificado"
    rechazado = "rechazado"
    suspendido = "suspendido"

class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    nombre = Column(String(100), nullable=False)
    telefono = Column(String(20), unique=True, nullable=False)
    email = Column(String(150), unique=True, nullable=True)
    password_hash = Column(String(255), nullable=False)
    rol = Column(Enum(RolUsuario), nullable=False)
    fecha_nacimiento = Column(Date, nullable=True)
    distrito = Column(String(100), nullable=True)
    dni_numero = Column(String(20), nullable=True)
    ruc_numero = Column(String(15), nullable=True)
    foto_perfil_url = Column(String(255), nullable=True)
    estado_verificacion = Column(
        Enum(EstadoVerificacion),
        default=EstadoVerificacion.sin_verificar
    )
    motivo_rechazo = Column(String(500), nullable=True)
    activo = Column(Boolean, default=True)
    creado_en = Column(DateTime, default=datetime.utcnow)
    actualizado_en = Column(DateTime, default=datetime.utcnow,
                           onupdate=datetime.utcnow)