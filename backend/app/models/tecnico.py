from sqlalchemy import Column, String, Float, Integer, Boolean, ForeignKey, ARRAY
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.database import Base
import uuid

class Tecnico(Base):
    __tablename__ = "tecnicos"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    usuario_id = Column(UUID(as_uuid=True), ForeignKey("usuarios.id"), unique=True, nullable=False)
    especialidades = Column(ARRAY(String), default=[])
    distrito = Column(String(100), nullable=False)
    bio = Column(String(500), nullable=True)
    precio_minimo = Column(Float, default=0)
    foto_url = Column(String(255), nullable=True)
    id_verificado = Column(Boolean, default=False)
    activo = Column(Boolean, default=True)
    calificacion = Column(Float, default=0.0)
    trabajos_completados = Column(Integer, default=0)

    usuario = relationship("Usuario", backref="tecnico")