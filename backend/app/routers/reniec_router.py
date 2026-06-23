import logging
import httpx
from fastapi import APIRouter, HTTPException

router = APIRouter(prefix="/reniec", tags=["reniec"])

_DECOLECTA_TOKEN = "sk_16364.kblsh6BgADn60U9oM7Z81LC9HI6dxo2n"
_DECOLECTA_URL   = "https://api.decolecta.com/v1/reniec/dni"

logger = logging.getLogger("reniec")


@router.get("/consultar/{dni}")
async def consultar_dni(dni: str):
    """
    Proxy hacia decolecta.com para consultar datos RENIEC por DNI.
    El token queda en el servidor, nunca expuesto al cliente.
    """
    if not dni.isdigit() or len(dni) != 8:
        raise HTTPException(status_code=422, detail="DNI debe tener exactamente 8 dígitos")

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(
                _DECOLECTA_URL,
                params={"numero": dni},
                headers={"Authorization": f"Bearer {_DECOLECTA_TOKEN}"},
            )
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Timeout al consultar RENIEC")
    except httpx.RequestError as e:
        raise HTTPException(status_code=502, detail=f"Error de conexión: {str(e)}")

    # ── Log para debug — quita esto en producción ─────────────────────────
    logger.warning(
        f"[RENIEC] DNI={dni} | HTTP={resp.status_code} | body={resp.text[:400]}"
    )

    if resp.status_code == 401:
        raise HTTPException(status_code=502, detail="Token RENIEC inválido o expirado")

    if resp.status_code not in (200, 404):
        raise HTTPException(
            status_code=502,
            detail=f"Error del proveedor RENIEC: {resp.status_code}",
        )

    # ── Parsear JSON ──────────────────────────────────────────────────────
    try:
        data = resp.json()
    except Exception:
        raise HTTPException(status_code=502, detail="Respuesta inválida del proveedor RENIEC")

    # Decolecta puede envolver en {"data": {...}, "codigo": 1}
    # o devolver los campos directo según el plan
    payload = data.get("data", data)

    # codigo == 0 o status 404 → no encontrado
    if resp.status_code == 404 or data.get("codigo") == 0:
        raise HTTPException(status_code=404, detail="DNI no encontrado en RENIEC")

    nombres = (payload.get("first_name")       or "").strip().title()
    paterno = (payload.get("first_last_name")  or "").strip().title()
    materno = (payload.get("second_last_name") or "").strip().title()
    full_name = (payload.get("full_name") or "").strip().title()
    completo = f"{paterno} {materno} {nombres}".strip() or full_name

    if not completo:
        raise HTTPException(status_code=404, detail="DNI no encontrado en RENIEC")

    return {
        "dni":              dni,
        "nombres":          nombres,
        "apellido_paterno": paterno,
        "apellido_materno": materno,
        "nombre_completo":  completo,
        "full_name_raw":    payload.get("full_name", ""),
    }