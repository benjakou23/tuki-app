from pydantic import BaseModel
from typing import Optional, List
from uuid import UUID

class TecnicoRegistro(BaseModel):
    especialidades: List[str]
    distrito: str
    bio: Optional[str] = None
    precio_minimo: Optional[float] = 0

class TecnicoRespuesta(BaseModel):
    id: UUID
    usuario_id: UUID
    especialidades: List[str]
    distrito: str
    bio: Optional[str] = None
    precio_minimo: float
    foto_url: Optional[str] = None
    id_verificado: bool
    activo: bool
    calificacion: float
    trabajos_completados: int

    class Config:
        from_attributes = True

class TecnicoConUsuario(TecnicoRespuesta):
    nombre: str
    telefono: str

    class Config:
        from_attributes = True