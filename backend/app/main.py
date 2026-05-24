from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.database import engine, Base
from app.routers import usuarios, tecnicos, pedidos, documentos, admin
import app.models.usuario
import app.models.tecnico
import app.models.pedido
import app.models.documento
import os

os.makedirs("uploads", exist_ok=True)

app = FastAPI(title="Chalao API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)

app.include_router(usuarios.router)
app.include_router(tecnicos.router)
app.include_router(pedidos.router)
app.include_router(documentos.router)
app.include_router(admin.router)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

@app.get("/")
def root():
    return {"mensaje": "Chalao API corriendo", "version": "0.1.0"}

@app.get("/salud")
def salud():
    return {"estado": "ok"}