from pydantic import BaseModel, EmailStr
from enum import Enum
from uuid import UUID
from datetime import datetime
from typing import Optional

class RolUsuario(str, Enum):
    cliente = "cliente"
    tecnico = "tecnico"
    admin = "admin"

class UsuarioRegistro(BaseModel):
    nombre: str
    telefono: str
    email: Optional[EmailStr] = None
    password: str
    rol: RolUsuario
    dni_numero: Optional[str] = None
    distrito: Optional[str] = None

class UsuarioRespuesta(BaseModel):
    id: UUID
    nombre: str
    telefono: str
    email: Optional[str] = None
    rol: RolUsuario
    activo: bool
    estado_verificacion: Optional[str] = None
    dni_numero: Optional[str] = None
    distrito: Optional[str] = None
    creado_en: datetime

    class Config:
        from_attributes = True

class LoginRequest(BaseModel):
    telefono: str
    password: str

class TokenRespuesta(BaseModel):
    access_token: str
    token_type: str = "bearer"
    usuario: UsuarioRespuesta