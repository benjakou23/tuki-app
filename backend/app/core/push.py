import json
import httpx
from google.oauth2 import service_account
from google.auth.transport.requests import Request

CREDENTIALS_FILE = "firebase-credentials.json"
FCM_URL = "https://fcm.googleapis.com/v1/projects/jnireque-13d5e/messages:send"
SCOPES = ["https://www.googleapis.com/auth/firebase.messaging"]

def _obtener_token():
    try:
        credentials = service_account.Credentials.from_service_account_file(
            CREDENTIALS_FILE, scopes=SCOPES)
        credentials.refresh(Request())
        return credentials.token
    except Exception as e:
        print(f"Error obteniendo token Firebase: {e}")
        return None

async def enviar_push(token: str, titulo: str, cuerpo: str, data: dict = {}):
    if not token:
        return
    access_token = _obtener_token()
    if not access_token:
        return
    try:
        async with httpx.AsyncClient() as client:
            await client.post(
                FCM_URL,
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Content-Type": "application/json",
                },
                json={
                    "message": {
                        "token": token,
                        "notification": {
                            "title": titulo,
                            "body": cuerpo,
                        },
                        "data": {k: str(v) for k, v in data.items()},
                        "android": {
                            "priority": "high",
                            "notification": {
                                "sound": "default",
                                "channel_id": "tuki_canal",
                            }
                        }
                    }
                }
            )
    except Exception as e:
        print(f"Error enviando push: {e}")