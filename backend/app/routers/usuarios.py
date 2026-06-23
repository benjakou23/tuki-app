from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.usuario import Usuario, EstadoVerificacion
from app.schemas.usuario import UsuarioRegistro, UsuarioRespuesta, LoginRequest, TokenRespuesta
from typing import Optional
from app.auth.jwt import hashear_password, verificar_password, crear_token
from jose import jwt, JWTError
import os

router = APIRouter(prefix="/usuarios", tags=["usuarios"])

@router.post("/registro", response_model=TokenRespuesta, status_code=201)
def registrar(datos: UsuarioRegistro, db: Session = Depends(get_db)):
    existe = db.query(Usuario).filter(
        Usuario.telefono == datos.telefono).first()
    if existe:
        raise HTTPException(status_code=400,
            detail="Este teléfono ya está registrado")

    nuevo = Usuario(
        nombre=datos.nombre,
        telefono=datos.telefono,
        email=datos.email,
        password_hash=hashear_password(datos.password),
        rol=datos.rol,
        dni_numero=datos.dni_numero,
        distrito=datos.distrito,
        estado_verificacion=EstadoVerificacion.sin_verificar,
    )
    db.add(nuevo)
    db.commit()
    db.refresh(nuevo)

    if nuevo.email:
        try:
            from app.core.email import (
                enviar_bienvenida_cliente,
                enviar_bienvenida_tecnico,
            )
            if nuevo.rol.value == "tecnico":
                enviar_bienvenida_tecnico(nuevo.nombre, nuevo.email)
            else:
                enviar_bienvenida_cliente(nuevo.nombre, nuevo.email)
        except Exception as e:
            print(f"Error email registro: {e}")

    token = crear_token({"sub": str(nuevo.id), "rol": nuevo.rol})
    return {"access_token": token, "usuario": nuevo}


@router.post("/login", response_model=TokenRespuesta)
def login(datos: LoginRequest, db: Session = Depends(get_db)):
    usuario = db.query(Usuario).filter(
        Usuario.telefono == datos.telefono).first()
    if not usuario or not verificar_password(
            datos.password, usuario.password_hash):
        raise HTTPException(status_code=401,
            detail="Teléfono o contraseña incorrectos")
    token = crear_token({"sub": str(usuario.id), "rol": usuario.rol})
    return {"access_token": token, "usuario": usuario}


from pydantic import BaseModel as PydanticBase

class UsuarioUpdate(PydanticBase):
    nombre: Optional[str] = None
    distrito: Optional[str] = None

@router.patch("/actualizar", response_model=UsuarioRespuesta)
def actualizar_usuario(
    datos: UsuarioUpdate,
    authorization: str = Header(None),
    db: Session = Depends(get_db)
):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="No autorizado")
    token = authorization.split(" ")[1]
    try:
        payload = jwt.decode(token, os.getenv("SECRET_KEY"),
            algorithms=[os.getenv("ALGORITHM")])
        usuario_id = payload.get("sub")
    except JWTError:
        raise HTTPException(status_code=401, detail="Token inválido")

    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="No encontrado")

    if datos.nombre:
        usuario.nombre = datos.nombre
    if datos.distrito:
        usuario.distrito = datos.distrito

    db.commit()
    db.refresh(usuario)
    return usuario

@router.get("/me", response_model=UsuarioRespuesta)
def mi_perfil(
    authorization: str = Header(None),
    db: Session = Depends(get_db)
):
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="No autorizado")

    token = authorization.split(" ")[1]
    try:
        payload = jwt.decode(
            token,
            os.getenv("SECRET_KEY"),
            algorithms=[os.getenv("ALGORITHM")]
        )
        usuario_id = payload.get("sub")
    except JWTError:
        raise HTTPException(status_code=401, detail="Token inválido")

    usuario = db.query(Usuario).filter(
        Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404,
            detail="Usuario no encontrado")
    return usuario

