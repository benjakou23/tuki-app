import resend
import os
from dotenv import load_dotenv

load_dotenv()

resend.api_key = os.getenv("RESEND_API_KEY")

REMITENTE = "onboarding@resend.dev"
EMAIL_PRUEBA = "b73472193@gmail.com"  # tu email verificado en Resend

def _to(email: str) -> list:
    return [email] if email else [EMAIL_PRUEBA]

def enviar_bienvenida_cliente(nombre: str, email: str):
    try:
        resend.Emails.send({
            "from": REMITENTE,
            "to": _to(EMAIL_PRUEBA),  # en pruebas siempre a tu email
            "subject": "Bienvenido a Tuki.pe",
            "html": f"""
            <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:32px 24px">
                <h1 style="color:#FF6B00;font-size:28px;margin-bottom:4px">Tuki.pe</h1>
                <p style="color:#888;font-size:13px;margin-bottom:32px">Servicios locales · Lambayeque</p>
                <h2 style="font-size:20px;color:#0F0F0F">Hola {nombre}, bienvenido 👋</h2>
                <p style="color:#444;line-height:1.6">
                    Tu cuenta fue creada. Estamos revisando tus documentos —
                    en menos de <strong>24 horas</strong> te avisamos.
                </p>
                <div style="background:#FFF7F0;border-radius:12px;padding:16px 20px;margin:24px 0;border:1px solid #FFE0CC">
                    <p style="color:#CC5500;font-size:14px;margin:0">
                        ⏳ Cuenta <strong>en revisión</strong>. Te notificamos por email.
                    </p>
                </div>
                <p style="color:#888;font-size:13px">Tuki.pe, y listo.</p>
            </div>
            """
        })
        print(f"Email bienvenida enviado a {EMAIL_PRUEBA}")
    except Exception as e:
        print(f"Error email bienvenida cliente: {e}")

def enviar_bienvenida_tecnico(nombre: str, email: str):
    try:
        resend.Emails.send({
            "from": REMITENTE,
            "to": _to(EMAIL_PRUEBA),
            "subject": "Registro recibido — Tuki.pe técnicos",
            "html": f"""
            <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:32px 24px">
                <h1 style="color:#FF6B00;font-size:28px;margin-bottom:4px">Tuki.pe</h1>
                <p style="color:#888;font-size:13px;margin-bottom:32px">Servicios locales · Lambayeque</p>
                <h2 style="font-size:20px;color:#0F0F0F">Hola {nombre}, recibimos tu registro</h2>
                <p style="color:#444;line-height:1.6">
                    Tus documentos están siendo revisados.
                    En menos de <strong>48 horas</strong> recibirás una respuesta.
                </p>
                <div style="background:#F0FDF4;border-radius:12px;padding:16px 20px;margin:24px 0;border:1px solid #BBF7D0">
                    <p style="color:#166534;font-size:14px;margin:0">
                        ✅ Una vez aprobado aparecerás en búsquedas de clientes en Lambayeque.
                    </p>
                </div>
                <p style="color:#888;font-size:13px">Tuki.pe, y listo.</p>
            </div>
            """
        })
        print(f"Email bienvenida técnico enviado a {EMAIL_PRUEBA}")
    except Exception as e:
        print(f"Error email bienvenida tecnico: {e}")

def enviar_aprobacion(nombre: str, email: str):
    try:
        resend.Emails.send({
            "from": REMITENTE,
            "to": _to(EMAIL_PRUEBA),
            "subject": "¡Tu cuenta fue aprobada! — Tuki.pe",
            "html": f"""
            <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:32px 24px">
                <h1 style="color:#FF6B00;font-size:28px;margin-bottom:4px">Tuki.pe</h1>
                <p style="color:#888;font-size:13px;margin-bottom:32px">Servicios locales · Lambayeque</p>
                <h2 style="font-size:20px;color:#0F0F0F">¡{nombre}, estás verificado! ✓</h2>
                <p style="color:#444;line-height:1.6">
                    Tu cuenta fue aprobada. Ya puedes iniciar sesión en Tuki.pe.
                </p>
                <div style="background:#F0FDF4;border-radius:12px;padding:16px 20px;margin:24px 0;border:1px solid #BBF7D0">
                    <p style="color:#166534;font-size:14px;margin:0">
                        🎉 Badge <strong>verificado</strong> activo en tu perfil.
                    </p>
                </div>
                <p style="color:#888;font-size:13px;margin-top:32px">Tuki.pe, y listo.</p>
            </div>
            """
        })
        print(f"Email aprobacion enviado a {EMAIL_PRUEBA}")
    except Exception as e:
        print(f"Error email aprobacion: {e}")

def enviar_rechazo(nombre: str, email: str, motivo: str):
    try:
        resend.Emails.send({
            "from": REMITENTE,
            "to": _to(EMAIL_PRUEBA),
            "subject": "Revisión de cuenta — Tuki.pe",
            "html": f"""
            <div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:32px 24px">
                <h1 style="color:#FF6B00;font-size:28px;margin-bottom:4px">Tuki.pe</h1>
                <p style="color:#888;font-size:13px;margin-bottom:32px">Servicios locales · Lambayeque</p>
                <h2 style="font-size:20px;color:#0F0F0F">Hola {nombre}</h2>
                <p style="color:#444;line-height:1.6">
                    Necesitamos que corrijas algo antes de continuar.
                </p>
                <div style="background:#FEF2F2;border-radius:12px;padding:16px 20px;margin:24px 0;border:1px solid #FECACA">
                    <p style="color:#DC2626;font-size:14px;margin:0">
                        <strong>Motivo:</strong> {motivo}
                    </p>
                </div>
                <p style="color:#444;line-height:1.6">
                    Vuelve a la app, corrige los datos y envíanos tu solicitud nuevamente.
                </p>
                <p style="color:#888;font-size:13px;margin-top:32px">Tuki.pe, y listo.</p>
            </div>
            """
        })
        print(f"Email rechazo enviado a {EMAIL_PRUEBA}")
    except Exception as e:
        print(f"Error email rechazo: {e}")