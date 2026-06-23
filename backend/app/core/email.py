import os
from html import escape

import resend
from dotenv import load_dotenv

load_dotenv()

resend.api_key = os.getenv("RESEND_API_KEY")

REMITENTE = "onboarding@resend.dev"
EMAIL_PRUEBA = "b73472193@gmail.com"


def _to(email: str) -> list:
    # En desarrollo, todos los emails van a tu correo
    return [EMAIL_PRUEBA]


# Paleta profesional dark
_BG = "#0B0D12"
_CARD = "#11151D"
_CARD_HI = "#151A24"
_BORDER = "#242A36"

_BLUE = "#3B82F6"
_BLUE_DARK = "#1D4ED8"
_BLUE_SOFT = "#93C5FD"

_GREEN = "#34D399"
_GREEN_BG = "#0D241B"
_GREEN_BORDER = "#1E4535"

_AMBER = "#FBBF24"
_AMBER_BG = "#241B08"
_AMBER_BORDER = "#4A3510"

_RED = "#F87171"
_RED_BG = "#241013"
_RED_BORDER = "#4A1F26"

_TEXT = "#FFFFFF"
_TEXT_MID = "#B8C0CC"
_TEXT_MUTED = "#7E8796"
_TEXT_DIM = "#535B68"


def _safe(value: str) -> str:
    return escape(str(value or ""), quote=True)


def _wrapper(content: str, preview: str = "") -> str:
    preview_html = ""
    if preview:
        preview_html = (
            f"<span style='display:none!important;max-height:0;overflow:hidden;"
            f"opacity:0;color:transparent;'>{_safe(preview)}</span>"
        )

    return f"""<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="dark">
  <meta name="supported-color-schemes" content="dark">
  <title>Tuki.pe</title>
</head>
<body style="margin:0;padding:0;background-color:{_BG};font-family:Inter,Arial,sans-serif;">
  {preview_html}

  <table width="100%" cellpadding="0" cellspacing="0" role="presentation"
         style="background-color:{_BG};padding:42px 16px;">
    <tr>
      <td align="center">
        <table width="540" cellpadding="0" cellspacing="0" role="presentation"
               style="width:100%;max-width:540px;">

          <tr>
            <td style="padding:0 0 22px;">
              <table width="100%" cellpadding="0" cellspacing="0" role="presentation">
                <tr>
                  <td align="left" style="vertical-align:middle;">
                    <span style="font-family:Inter,Arial,sans-serif;font-size:20px;
                                 font-weight:500;color:{_TEXT};letter-spacing:-0.2px;">
                      Tuki<span style="font-weight:400;color:{_BLUE_SOFT};">.pe</span>
                    </span>
                  </td>
                  <td align="right" style="vertical-align:middle;">
                    <span style="font-family:Inter,Arial,sans-serif;font-size:12px;
                                 font-weight:400;color:{_TEXT_DIM};">
                      Lambayeque, Perú
                    </span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <tr>
            <td style="background-color:{_CARD};border:1px solid {_BORDER};
                       border-radius:22px;overflow:hidden;">
              {content}
            </td>
          </tr>

          <tr>
            <td style="padding:22px 8px 0;text-align:center;">
              <p style="margin:0;font-family:Inter,Arial,sans-serif;font-size:12px;
                        font-weight:400;color:{_TEXT_DIM};line-height:1.7;">
                Mensaje automático. No respondas este correo.<br>
                © Tuki.pe. Servicios locales de confianza.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>"""


def _hero(status: str, title: str, subtitle: str, kind: str = "neutral") -> str:
    palettes = {
        "neutral": (_BLUE, "#13213A", "#243B63"),
        "success": (_GREEN, _GREEN_BG, _GREEN_BORDER),
        "warning": (_AMBER, _AMBER_BG, _AMBER_BORDER),
        "error": (_RED, _RED_BG, _RED_BORDER),
    }
    accent, bg, border = palettes.get(kind, palettes["neutral"])

    return f"""
<table width="100%" cellpadding="0" cellspacing="0" role="presentation">
  <tr>
    <td style="padding:34px 34px 8px;text-align:center;">
      <span style="display:inline-block;padding:7px 12px;border-radius:999px;
                   background-color:{bg};border:1px solid {border};
                   font-family:Inter,Arial,sans-serif;font-size:12px;
                   font-weight:500;color:{accent};">
        {_safe(status)}
      </span>

      <h1 style="margin:22px 0 0;font-family:Inter,Arial,sans-serif;
                 font-size:26px;font-weight:500;color:{_TEXT};
                 letter-spacing:-0.4px;line-height:1.25;">
        {_safe(title)}
      </h1>

      <p style="margin:10px auto 0;max-width:390px;font-family:Inter,Arial,sans-serif;
                font-size:14px;font-weight:400;color:{_TEXT_MUTED};
                line-height:1.65;">
        {_safe(subtitle)}
      </p>
    </td>
  </tr>
</table>"""


def _section(content: str) -> str:
    return f"""
<table width="100%" cellpadding="0" cellspacing="0" role="presentation">
  <tr>
    <td style="padding:22px 34px 34px;">
      {content}
    </td>
  </tr>
</table>"""


def _divider() -> str:
    return f"""
<div style="height:1px;background-color:{_BORDER};margin:22px 0;"></div>"""


def _paragraph(text: str) -> str:
    return f"""
<p style="margin:0 0 14px;font-family:Inter,Arial,sans-serif;font-size:14px;
          font-weight:400;color:{_TEXT_MID};line-height:1.75;">
  {text}
</p>"""


def _callout(text: str, kind: str = "neutral") -> str:
    palettes = {
        "neutral": ("#13213A", "#243B63", _BLUE_SOFT),
        "success": (_GREEN_BG, _GREEN_BORDER, _GREEN),
        "warning": (_AMBER_BG, _AMBER_BORDER, _AMBER),
        "error": (_RED_BG, _RED_BORDER, _RED),
    }
    bg, border, fg = palettes.get(kind, palettes["neutral"])

    return f"""
<table width="100%" cellpadding="0" cellspacing="0" role="presentation"
       style="margin:20px 0;">
  <tr>
    <td style="background-color:{bg};border:1px solid {border};
               border-radius:14px;padding:15px 16px;">
      <p style="margin:0;font-family:Inter,Arial,sans-serif;font-size:13px;
                font-weight:400;color:{fg};line-height:1.65;">
        {text}
      </p>
    </td>
  </tr>
</table>"""


def _details(rows: list[tuple[str, str]]) -> str:
    items = ""

    for label, value in rows:
        items += f"""
<tr>
  <td style="padding:12px 0;border-bottom:1px solid {_BORDER};
             font-family:Inter,Arial,sans-serif;font-size:12px;
             font-weight:400;color:{_TEXT_DIM};width:120px;">
    {_safe(label)}
  </td>
  <td style="padding:12px 0;border-bottom:1px solid {_BORDER};
             font-family:Inter,Arial,sans-serif;font-size:13px;
             font-weight:400;color:{_TEXT_MID};line-height:1.45;">
    {_safe(value)}
  </td>
</tr>"""

    return f"""
<table width="100%" cellpadding="0" cellspacing="0" role="presentation"
       style="margin:18px 0 6px;background-color:{_CARD_HI};
              border:1px solid {_BORDER};border-radius:14px;
              padding:0 16px;">
  {items}
</table>"""


def _cta_button(text: str, url: str = "#") -> str:
    return f"""
<table width="100%" cellpadding="0" cellspacing="0" role="presentation"
       style="margin:24px 0 4px;">
  <tr>
    <td align="center">
      <a href="{_safe(url)}"
         style="display:inline-block;background-color:{_BLUE_DARK};
                color:#FFFFFF;font-family:Inter,Arial,sans-serif;
                font-size:14px;font-weight:500;padding:14px 30px;
                border-radius:14px;text-decoration:none;">
        {_safe(text)}
      </a>
    </td>
  </tr>
</table>"""


def _signature() -> str:
    return f"""
{_divider()}
<p style="margin:0;font-family:Inter,Arial,sans-serif;font-size:13px;
          font-weight:400;color:{_TEXT_MUTED};line-height:1.6;">
  Atentamente,<br>
  <span style="color:{_TEXT_MID};">Equipo de Tuki.pe</span>
</p>"""


def _send(to: str, subject: str, html: str, label: str):
    try:
        resend.Emails.send({
            "from": REMITENTE,
            "to": _to(to),
            "subject": subject,
            "html": html,
        })
        print(f"[tuki/email] {label} -> {to}")
    except Exception as e:
        print(f"[tuki/email] error {label}: {e}")


def enviar_bienvenida_cliente(nombre: str, email: str):
    nombre_html = _safe(nombre)

    content = (
        _hero(
            status="Cuenta en revisión",
            title=f"Hola, {nombre}",
            subtitle="Tu cuenta fue creada correctamente. Estamos revisando la información registrada.",
            kind="warning",
        )
        + _section(
            _divider()
            + _paragraph(
                "Gracias por registrarte en Tuki.pe. Antes de activar tu cuenta, "
                "nuestro equipo revisará los datos enviados para mantener una plataforma segura y confiable."
            )
            + _callout(
                "Tu cuenta se encuentra <strong>en revisión</strong>. "
                "Recibirás una notificación cuando el proceso haya finalizado.",
                kind="warning",
            )
            + _details([
                ("Estado", "En revisión"),
                ("Plazo estimado", "Máximo 24 horas"),
                ("Canal de aviso", "Correo electrónico"),
            ])
            + _signature()
        )
    )

    _send(
        email,
        "Cuenta en revisión - Tuki.pe",
        _wrapper(content, preview=f"Hola {nombre_html}, tu cuenta está en revisión."),
        "bienvenida-cliente",
    )


def enviar_bienvenida_tecnico(nombre: str, email: str):
    nombre_html = _safe(nombre)

    content = (
        _hero(
            status="Solicitud recibida",
            title=f"Hola, {nombre}",
            subtitle="Recibimos tu solicitud para formar parte de la red de técnicos de Tuki.pe.",
            kind="neutral",
        )
        + _section(
            _divider()
            + _paragraph(
                "Estamos revisando tu documentación y los datos de tu perfil. "
                "Una vez aprobada la solicitud, tu perfil podrá aparecer en las búsquedas de clientes dentro de tu zona."
            )
            + _callout(
                "El proceso de verificación puede tomar hasta "
                "<strong>48 horas hábiles</strong>. Te notificaremos por este correo con el resultado.",
                kind="neutral",
            )
            + _details([
                ("Estado", "En revisión"),
                ("Zona", "Lambayeque"),
                ("Plazo estimado", "Máximo 48 horas hábiles"),
            ])
            + _signature()
        )
    )

    _send(
        email,
        "Solicitud recibida - Tuki.pe Técnicos",
        _wrapper(content, preview=f"Hola {nombre_html}, tu solicitud está siendo revisada."),
        "bienvenida-tecnico",
    )


def enviar_aprobacion(nombre: str, email: str):
    nombre_html = _safe(nombre)

    content = (
        _hero(
            status="Cuenta aprobada",
            title=f"{nombre}, tu cuenta fue aprobada",
            subtitle="La revisión finalizó correctamente. Ya puedes acceder a las funciones de Tuki.pe.",
            kind="success",
        )
        + _section(
            _divider()
            + _paragraph(
                "Hemos completado la revisión de tu información. Tu cuenta ya se encuentra activa "
                "y lista para utilizarse dentro de la plataforma."
            )
            + _callout(
                "Tu perfil ahora figura como <strong>verificado</strong>, lo que ayuda a generar "
                "mayor confianza dentro de Tuki.pe.",
                kind="success",
            )
            + _cta_button("Abrir Tuki.pe")
            + _signature()
        )
    )

    _send(
        email,
        "Cuenta aprobada - Tuki.pe",
        _wrapper(content, preview=f"Felicidades {nombre_html}. Tu cuenta fue aprobada."),
        "aprobacion",
    )


def enviar_rechazo(nombre: str, email: str, motivo: str):
    nombre_html = _safe(nombre)
    motivo_html = _safe(motivo)

    content = (
        _hero(
            status="Acción requerida",
            title=f"Hola, {nombre}",
            subtitle="Encontramos información que debe corregirse antes de continuar con la revisión.",
            kind="error",
        )
        + _section(
            _divider()
            + _paragraph(
                "Revisamos tu solicitud y necesitamos que actualices algunos datos para poder continuar "
                "con el proceso de verificación."
            )
            + _callout(
                f"<strong>Motivo:</strong> {motivo_html}",
                kind="error",
            )
            + _paragraph(
                "Ingresa a la aplicación, corrige la información indicada y vuelve a enviar tu solicitud. "
                "La revisaremos nuevamente a la brevedad."
            )
            + _cta_button("Corregir información")
            + _signature()
        )
    )

    _send(
        email,
        "Acción requerida en tu cuenta - Tuki.pe",
        _wrapper(content, preview=f"Hola {nombre_html}, necesitamos que corrijas información de tu cuenta."),
        "rechazo",
    )