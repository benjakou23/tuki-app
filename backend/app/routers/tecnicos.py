from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models.tecnico import Tecnico
from app.models.usuario import Usuario, RolUsuario
from app.schemas.tecnico import TecnicoRegistro, TecnicoRespuesta

router = APIRouter(prefix="/tecnicos", tags=["tecnicos"])

@router.post("/", response_model=TecnicoRespuesta, status_code=201)
def crear_perfil_tecnico(datos: TecnicoRegistro, usuario_id: str, db: Session = Depends(get_db)):
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuario no encontrado")
    if usuario.rol != RolUsuario.tecnico:
        raise HTTPException(status_code=400, detail="El usuario no tiene rol de técnico")

    existe = db.query(Tecnico).filter(Tecnico.usuario_id == usuario_id).first()
    if existe:
        raise HTTPException(status_code=400, detail="Este usuario ya tiene perfil de técnico")

    tecnico = Tecnico(
        usuario_id=usuario_id,
        especialidades=datos.especialidades,
        distrito=datos.distrito,
        bio=datos.bio,
        precio_minimo=datos.precio_minimo,
    )
    db.add(tecnico)
    db.commit()
    db.refresh(tecnico)
    return tecnico

@router.get("/", response_model=list[TecnicoRespuesta])
def listar_tecnicos(distrito: str = None, especialidad: str = None, db: Session = Depends(get_db)):
    query = db.query(Tecnico).filter(Tecnico.activo == True)
    if distrito:
        query = query.filter(Tecnico.distrito == distrito)
    if especialidad:
        query = query.filter(Tecnico.especialidades.contains([especialidad]))
    return query.all()

@router.get("/{tecnico_id}", response_model=TecnicoRespuesta)
def obtener_tecnico(tecnico_id: str, db: Session = Depends(get_db)):
    tecnico = db.query(Tecnico).filter(Tecnico.id == tecnico_id).first()
    if not tecnico:
        raise HTTPException(status_code=404, detail="Técnico no encontrado")
    return tecnico