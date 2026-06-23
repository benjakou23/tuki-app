import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';

// ── Paleta dark (consistente con el sistema) ──────────────────────────────────
const _bg        = Color(0xFF0D0F14);
const _surface   = Color(0x0AFFFFFF);
const _surfaceHi = Color(0x14FFFFFF);
const _border    = Color(0x14FFFFFF);
const _blue      = Color(0xFF2563EB);
const _blueLight = Color(0xFF60A5FA);
const _blueDim   = Color(0x1A60A5FA);
const _blueBorder = Color(0x3360A5FA);
const _green     = Color(0xFF34D399);
const _greenDim  = Color(0x1434D399);
const _greenBorder = Color(0x2834D399);
const _amber     = Color(0xFFFBBF24);
const _amberDim  = Color(0x14FBBF24);
const _amberBorder = Color(0x28FBBF24);
const _textPri   = Color(0xFFFFFFFF);
const _textMid   = Color(0x99FFFFFF);
const _textMuted = Color(0x61FFFFFF);
const _textDim   = Color(0x38FFFFFF);

class EnRevisionScreen extends StatefulWidget {
  const EnRevisionScreen({super.key});
  @override
  State<EnRevisionScreen> createState() => _EnRevisionScreenState();
}

class _EnRevisionScreenState extends State<EnRevisionScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  bool _verificando = false;

  late final AnimationController _pulsoCtrl;
  late final Animation<double>   _pulsoAnim;
  late final AnimationController _entradaCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  static const _pasos = [
    (titulo: 'Documentos recibidos',
     subtitulo: 'Tu información llegó correctamente',
     completo: true),
    (titulo: 'Revisión en proceso',
     subtitulo: 'Nuestro equipo está verificando tus datos',
     completo: false),
    (titulo: 'Cuenta activada',
     subtitulo: 'Podrás acceder a todos los servicios',
     completo: false),
  ];

  TextStyle _tx(double s, FontWeight w, Color c, {double? ls, double? h}) =>
      GoogleFonts.inter(
          fontSize: s, fontWeight: w, color: c,
          letterSpacing: ls ?? 0, height: h);

  @override
  void initState() {
    super.initState();

    _entradaCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _fadeAnim  = CurvedAnimation(
        parent: _entradaCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _entradaCtrl, curve: Curves.easeOutCubic));

    _pulsoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
    _pulsoAnim = Tween<double>(begin: 0.94, end: 1.06).animate(
        CurvedAnimation(parent: _pulsoCtrl, curve: Curves.easeInOut));

    _timer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await context.read<AuthProvider>().refrescarUsuario();
      if (!mounted) return;
      if (context.read<AuthProvider>().estadoVerificacion == 'verificado') {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulsoCtrl.dispose();
    _entradaCtrl.dispose();
    super.dispose();
  }

  Future<void> _refrescarManual() async {
    setState(() => _verificando = true);
    await context.read<AuthProvider>().refrescarUsuario();
    if (!mounted) return;
    setState(() => _verificando = false);

    final estado = context.read<AuthProvider>().estadoVerificacion;
    if (estado == 'verificado') {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Aún en revisión. Te avisamos por email.',
            style: _tx(13, FontWeight.w400, _textPri)),
        backgroundColor: const Color(0xFF1A1D24),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),

                  // ── Logo ────────────────────────────────────────────
                  Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(10)),
                      child: Center(
                        child: Text('T',
                            style: _tx(17, FontWeight.w500,
                                Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text('Tuki',
                        style: _tx(18, FontWeight.w500, _textPri,
                            ls: -0.4)),
                    Text('.pe',
                        style: _tx(16, FontWeight.w400, _blueLight)),
                  ]),

                  const SizedBox(height: 48),

                  // ── Ícono central con pulso ──────────────────────────
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulsoAnim,
                      builder: (_, child) => Transform.scale(
                          scale: _pulsoAnim.value, child: child),
                      child: Container(
                        width: 84, height: 84,
                        decoration: BoxDecoration(
                          color: _amberDim,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _amberBorder, width: 1.5),
                        ),
                        child: const Icon(
                            Icons.hourglass_top_rounded,
                            size: 36, color: _amber),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // ── Título ───────────────────────────────────────────
                  Center(
                    child: Column(children: [
                      Text('Documentos\nenviados',
                          textAlign: TextAlign.center,
                          style: _tx(32, FontWeight.w500, _textPri,
                              ls: -1.0, h: 1.15)),
                      const SizedBox(height: 10),
                      Text(
                          'Estamos revisando tu información.\nTe avisamos en menos de 48 horas.',
                          textAlign: TextAlign.center,
                          style: _tx(13, FontWeight.w400, _textMuted,
                              h: 1.55)),
                    ]),
                  ),

                  const SizedBox(height: 32),

                  // ── Timeline ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _border)),
                    child: Column(
                      children: List.generate(_pasos.length, (i) {
                        final paso     = _pasos[i];
                        final esUltimo = i == _pasos.length - 1;
                        final completo = paso.completo;
                        final activo   = !completo && i == 1;

                        return Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // Nodo + conector
                            SizedBox(
                              width: 28,
                              child: Column(children: [
                                AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 220),
                                  width: 28, height: 28,
                                  decoration: BoxDecoration(
                                    color: completo
                                        ? _blue
                                        : activo
                                            ? _amberDim
                                            : _surface,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: completo
                                            ? _blue
                                            : activo
                                                ? _amberBorder
                                                : _border,
                                        width: 1.5),
                                  ),
                                  child: Icon(
                                    completo
                                        ? Icons.check_rounded
                                        : activo
                                            ? Icons.more_horiz_rounded
                                            : Icons.circle_outlined,
                                    size: 14,
                                    color: completo
                                        ? Colors.white
                                        : activo
                                            ? _amber
                                            : _textDim),
                                ),
                                if (!esUltimo)
                                  Container(
                                    width: 1.5,
                                    height: 34,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 3),
                                    color: completo
                                        ? _blueBorder
                                        : _border),
                              ]),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                    bottom: esUltimo ? 0 : 26),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 3),
                                    Text(paso.titulo,
                                        style: _tx(
                                          13,
                                          activo
                                              ? FontWeight.w500
                                              : FontWeight.w400,
                                          completo
                                              ? _textMid
                                              : activo
                                                  ? _textPri
                                                  : _textDim,
                                        )),
                                    const SizedBox(height: 2),
                                    Text(paso.subtitulo,
                                        style: _tx(11, FontWeight.w400,
                                            completo || activo
                                                ? _textMuted
                                                : _textDim)),
                                  ],
                                ),
                              ),
                            ),
                            // Badge "En curso"
                            if (activo)
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: _amberDim,
                                    borderRadius:
                                        BorderRadius.circular(999),
                                    border: Border.all(
                                        color: _amberBorder)),
                                child: Text('En curso',
                                    style: _tx(9, FontWeight.w500,
                                        _amber)),
                              ),
                          ],
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Info chips ───────────────────────────────────────
                  Row(children: [
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.mail_outline_rounded,
                        title: 'Por email',
                        subtitle: 'Recibirás la respuesta',
                        tx: _tx,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.schedule_rounded,
                        title: 'Máx. 48 h',
                        subtitle: 'Horas hábiles',
                        accent: true,
                        tx: _tx,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 28),

                  // ── Botón verificar ──────────────────────────────────
                  GestureDetector(
                    onTap: _verificando ? null : _refrescarManual,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                          color: _verificando
                              ? const Color(0x40FFFFFF)
                              : _blue,
                          borderRadius: BorderRadius.circular(14)),
                      child: Center(
                        child: _verificando
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2))
                            : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.refresh_rounded,
                                      size: 16, color: Colors.white),
                                  const SizedBox(width: 7),
                                  Text('Verificar estado',
                                      style: _tx(13, FontWeight.w500,
                                          Colors.white)),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Botón login ──────────────────────────────────────
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border)),
                      child: Center(
                        child: Text('Ir al inicio de sesión',
                            style: _tx(13, FontWeight.w400,
                                _textMuted)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Footer ───────────────────────────────────────────
                  Center(
                    child: Text('Tuki · Hecho en Lambayeque',
                        style: _tx(11, FontWeight.w400, _textDim)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Chip de info ──────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool accent;
  final TextStyle Function(double, FontWeight, Color,
      {double? ls, double? h}) tx;

  const _InfoChip({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tx,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
        color: accent ? _amberDim : _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: accent ? _amberBorder : const Color(0x14FFFFFF))),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
            color: accent
                ? _amber.withValues(alpha: 0.15)
                : const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, size: 15,
            color: accent ? _amber : const Color(0x61FFFFFF)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: tx(11, FontWeight.w500,
                    accent ? _amber : const Color(0x99FFFFFF))),
            const SizedBox(height: 1),
            Text(subtitle,
                style: tx(10, FontWeight.w400,
                    const Color(0x38FFFFFF))),
          ],
        ),
      ),
    ]),
  );
}