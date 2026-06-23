// onboarding_cliente_screen.dart — Rediseño dark
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';
import '../../../core/api_client.dart';

// ── Paleta (consistente con login/registro) ───────────────────────────────────
const _bg        = Color(0xFF0D0F14);
const _blue      = Color(0xFF2563EB);
const _blueDark  = Color(0xFF1D4ED8);
const _blueLight = Color(0xFF60A5FA);
const _green     = Color(0xFF34D399);
const _errorFg   = Color(0xFFF87171);
const _border    = Color(0x14FFFFFF);
const _surface   = Color(0x0AFFFFFF);
const _textPri   = Color(0xFFFFFFFF);
const _textMid   = Color(0x99FFFFFF);
const _textMuted = Color(0x61FFFFFF);
const _textDim   = Color(0x38FFFFFF);

class OnboardingClienteScreen extends StatefulWidget {
  const OnboardingClienteScreen({super.key});
  @override
  State<OnboardingClienteScreen> createState() =>
      _OnboardingClienteScreenState();
}

class _OnboardingClienteScreenState extends State<OnboardingClienteScreen>
    with TickerProviderStateMixin {
  final _picker = ImagePicker();
  int   _paso   = 0;
  bool  _subiendo = false;

  File? _dniFrontal;
  File? _dniReverso;
  File? _selfie;

  // Un solo AnimationController de entrada
  late final AnimationController _entradaCtrl;
  late final Animation<double>   _fadeAnim;

  // Fade por paso (igual que antes)
  late final AnimationController _pasoCtrl;
  late final Animation<double>   _pasoFade;

  TextStyle _tx(double size, FontWeight w, Color c, {double? ls, double? h}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: w, color: c,
          letterSpacing: ls ?? 0, height: h);

  @override
  void initState() {
    super.initState();
    _entradaCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _fadeAnim = CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOut);

    _pasoCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 260));
    _pasoFade = CurvedAnimation(parent: _pasoCtrl, curve: Curves.easeOut);
    _pasoCtrl.value = 1.0;
  }

  @override
  void dispose() {
    _entradaCtrl.dispose();
    _pasoCtrl.dispose();
    super.dispose();
  }

  static const _pasos = [
    _PasoInfo(numero: '01', titulo: 'Frente\ndel DNI',
      sub: 'Coloca tu DNI sobre una superficie plana y bien iluminada.',
      icono: Icons.credit_card_outlined,
      guia: 'Asegúrate que los 4 datos principales sean legibles'),
    _PasoInfo(numero: '02', titulo: 'Reverso\ndel DNI',
      sub: 'Voltea tu DNI y captura la parte trasera.',
      icono: Icons.flip_outlined,
      guia: 'El código de barras debe ser visible y sin reflejos'),
    _PasoInfo(numero: '03', titulo: 'Selfie con\ntu DNI',
      sub: 'Sostén tu DNI junto a tu rostro mirando a la cámara.',
      icono: Icons.face_outlined,
      guia: 'Ambos deben verse con claridad — sin gorra ni lentes'),
    _PasoInfo(numero: '04', titulo: 'Todo\nlisto',
      sub: 'Revisa tus documentos antes de enviar.',
      icono: Icons.check_circle_outline_rounded,
      guia: ''),
  ];

  File? get _archivoActual => switch (_paso) {
    0 => _dniFrontal, 1 => _dniReverso, 2 => _selfie, _ => null };

  void _setArchivo(File f) => setState(() {
    switch (_paso) {
      case 0: _dniFrontal = f;
      case 1: _dniReverso = f;
      case 2: _selfie     = f;
    }
  });

  int get _completados =>
      [_dniFrontal, _dniReverso, _selfie].where((f) => f != null).length;

  Future<void> _pickFoto(ImageSource src) async {
    final picked = await _picker.pickImage(source: src, imageQuality: 88);
    if (picked != null) _setArchivo(File(picked.path));
  }

  Future<void> _irSiguiente() async {
    if (_paso < 3) {
      await _pasoCtrl.reverse();
      setState(() => _paso++);
      _pasoCtrl.forward();
    } else {
      _enviar();
    }
  }

  Future<void> _irAnterior() async {
    if (_paso > 0) {
      await _pasoCtrl.reverse();
      setState(() => _paso--);
      _pasoCtrl.forward();
    }
  }

  Future<void> _irAPaso(int n) async {
    await _pasoCtrl.reverse();
    setState(() => _paso = n);
    _pasoCtrl.forward();
  }

  Future<void> _enviar() async {
    setState(() => _subiendo = true);
    final uid = context.read<AuthProvider>().usuarioId;
    try {
      await ApiClient.subirDocumento(uid!, _dniFrontal!, 'dni_anverso');
      await ApiClient.subirDocumento(uid,  _dniReverso!, 'dni_reverso');
      await ApiClient.subirDocumento(uid,  _selfie!,     'selfie_dni');
      await context.read<AuthProvider>().refrescarUsuario();
      if (mounted) context.go('/en-revision');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al subir. Intenta de nuevo.',
              style: _tx(13, FontWeight.w400, _textPri)),
          backgroundColor: const Color(0xFF1C1F28),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info         = _pasos[_paso];
    final esFoto       = _paso < 3;
    final esConfirm    = _paso == 3;
    final tieneFoto    = _archivoActual != null;
    final puedeAvanzar = esConfirm ? _completados == 3 : tieneFoto;

    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _pasoFade,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PageHeader(paso: info.numero, titulo: info.titulo,
                            sub: info.sub, tx: _tx),
                        if (esFoto) ...[
                          _ZonaFotoDark(
                            archivo: _archivoActual,
                            icono: info.icono,
                            onGaleria: () => _pickFoto(ImageSource.gallery),
                            onCamara: () => _pickFoto(ImageSource.camera),
                            tx: _tx,
                          ),
                          if (info.guia.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _TipBox(text: info.guia, tx: _tx),
                          ],
                          if (tieneFoto) ...[
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () => _pickFoto(ImageSource.camera),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.refresh_rounded,
                                      size: 14, color: _textDim),
                                  const SizedBox(width: 5),
                                  Text('Tomar de nuevo',
                                      style: _tx(12, FontWeight.w400, _textDim)),
                                ],
                              ),
                            ),
                          ],
                        ],
                        if (esConfirm) ...[
                          _ConfirmCard(label: 'Frente del DNI', numero: '01',
                            archivo: _dniFrontal,
                            onRetomar: () => _irAPaso(0), tx: _tx),
                          const SizedBox(height: 10),
                          _ConfirmCard(label: 'Reverso del DNI', numero: '02',
                            archivo: _dniReverso,
                            onRetomar: () => _irAPaso(1), tx: _tx),
                          const SizedBox(height: 10),
                          _ConfirmCard(label: 'Selfie con DNI', numero: '03',
                            archivo: _selfie,
                            onRetomar: () => _irAPaso(2), tx: _tx),
                          const SizedBox(height: 14),
                          _SecurityBox(tx: _tx),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              _buildFooter(esFoto: esFoto, esConfirm: esConfirm,
                  tieneFoto: tieneFoto, puedeAvanzar: puedeAvanzar),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    const labels = ['Frontal', 'Reverso', 'Selfie', 'Enviar'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(children: [
        AnimatedOpacity(
          opacity: _paso > 0 ? 1.0 : 0.25,
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            onTap: _paso > 0 ? _irAnterior : null,
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border)),
              child: const Icon(Icons.arrow_back_rounded,
                  size: 16, color: _textMid),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: List.generate(4, (i) => Expanded(
                child: Text(labels[i],
                  overflow: TextOverflow.ellipsis,
                  style: _tx(9, FontWeight.w500,
                    i < _paso ? _green : i == _paso ? _textMid : _textDim,
                    ls: 0.02)),
              ))),
              const SizedBox(height: 5),
              Row(children: List.generate(4, (i) {
                final color = i < _paso ? _green
                    : i == _paso ? _blue : _border;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 4 : 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 2,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                );
              })),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _border)),
          child: Text('${_paso + 1}/4',
              style: _tx(11, FontWeight.w400, _textMuted)),
        ),
      ]),
    );
  }

  Widget _buildFooter({required bool esFoto, required bool esConfirm,
      required bool tieneFoto, required bool puedeAvanzar}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (esFoto) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final cargado = [_dniFrontal, _dniReverso, _selfie][i] != null;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: cargado ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: cargado ? _green : _border,
                  borderRadius: BorderRadius.circular(99)),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text('$_completados de 3 documentos cargados',
              style: _tx(12, FontWeight.w400,
                  _completados > 0 ? _green : _textMuted)),
          const SizedBox(height: 12),
        ],
        Material(
          color: puedeAvanzar && !_subiendo
              ? _blue
              : _blue.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: (puedeAvanzar && !_subiendo) ? _irSiguiente : null,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: double.infinity, height: 52,
              child: Center(
                child: _subiendo
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(
                          esConfirm
                              ? 'Enviar documentos'
                              : tieneFoto ? 'Continuar' : 'Sube una foto primero',
                          style: _tx(14, FontWeight.w500,
                              puedeAvanzar ? _textPri : _textMuted)),
                        if (puedeAvanzar) ...[
                          const SizedBox(width: 8),
                          Icon(
                            esConfirm
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            color: _textPri, size: 16),
                        ],
                      ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final String paso, titulo, sub;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _PageHeader({required this.paso, required this.titulo,
      required this.sub, required this.tx});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF60A5FA).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: const Color(0xFF60A5FA).withValues(alpha: 0.2))),
        child: Text('Paso $paso',
            style: tx(10, FontWeight.w500, const Color(0xFF60A5FA),
                ls: 0.06)),
      ),
      const SizedBox(height: 10),
      Text(titulo,
          style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w500,
              color: _textPri, height: 1.1, letterSpacing: -0.5)),
      const SizedBox(height: 5),
      Text(sub, style: tx(13, FontWeight.w400, _textMuted)),
      const SizedBox(height: 20),
    ],
  );
}

class _ZonaFotoDark extends StatelessWidget {
  final File? archivo;
  final IconData icono;
  final VoidCallback onGaleria, onCamara;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _ZonaFotoDark({required this.archivo, required this.icono,
      required this.onGaleria, required this.onCamara, required this.tx});

  @override
  Widget build(BuildContext context) {
    final ok = archivo != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: ok
            ? _green.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ok ? _green.withValues(alpha: 0.35) : _border)),
      child: Column(children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
          child: ok
              ? Image.file(archivo!,
                  width: double.infinity, height: 190, fit: BoxFit.cover)
              : SizedBox(
                  width: double.infinity, height: 150,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14)),
                        child: Icon(icono, size: 24, color: _textDim),
                      ),
                      const SizedBox(height: 12),
                      Text('Aún no hay foto',
                          style: tx(13, FontWeight.w400, _textMuted)),
                      const SizedBox(height: 2),
                      Text('Usa la cámara o galería',
                          style: tx(11, FontWeight.w400, _textDim)),
                    ],
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: onGaleria,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo_library_outlined,
                            size: 16, color: _textMid),
                        const SizedBox(width: 7),
                        Text('Galería',
                            style: tx(13, FontWeight.w400, _textMid)),
                      ]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: onCamara,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.camera_alt_outlined,
                            size: 16, color: Colors.white),
                        const SizedBox(width: 7),
                        Text('Cámara',
                            style: tx(13, FontWeight.w400, Colors.white)),
                      ]),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _TipBox extends StatelessWidget {
  final String text;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _TipBox({required this.text, required this.tx});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.tips_and_updates_outlined, size: 15, color: _textDim),
      const SizedBox(width: 10),
      Expanded(child: Text(text,
          style: tx(12, FontWeight.w400, _textDim, h: 1.5))),
    ]),
  );
}

class _ConfirmCard extends StatelessWidget {
  final String label, numero;
  final File?  archivo;
  final VoidCallback onRetomar;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _ConfirmCard({required this.label, required this.numero,
      required this.archivo, required this.onRetomar, required this.tx});

  @override
  Widget build(BuildContext context) {
    final ok = archivo != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: ok
            ? _green.withValues(alpha: 0.05)
            : _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ok ? _green.withValues(alpha: 0.28) : _border)),
      child: Row(children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(13),
            bottomLeft: Radius.circular(13)),
          child: ok
              ? Image.file(archivo!,
                  width: 68, height: 68, fit: BoxFit.cover)
              : Container(
                  width: 68, height: 68,
                  color: Colors.white.withValues(alpha: 0.03),
                  child: Icon(Icons.image_outlined,
                      size: 22, color: _textDim)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: tx(13, FontWeight.w500,
                ok ? _textPri : _textMuted)),
            const SizedBox(height: 2),
            Text(ok ? 'Cargado ✓' : 'Sin foto',
                style: tx(11, FontWeight.w400,
                    ok ? _green : _errorFg)),
          ],
        )),
        GestureDetector(
          onTap: onRetomar,
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _border)),
            child: Text(ok ? 'Cambiar' : 'Subir',
                style: tx(11, FontWeight.w400, _textMuted)),
          ),
        ),
      ]),
    );
  }
}

class _SecurityBox extends StatelessWidget {
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _SecurityBox({required this.tx});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: _green.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _green.withValues(alpha: 0.18))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.shield_outlined, size: 15,
          color: _green.withValues(alpha: 0.6)),
      const SizedBox(width: 10),
      Expanded(child: Text(
        'Tus documentos se usan solo para verificar tu identidad en Tuki.pe. No los compartimos con terceros.',
        style: tx(12, FontWeight.w400,
            _green.withValues(alpha: 0.6), h: 1.5))),
    ]),
  );
}

// ── Modelo ────────────────────────────────────────────────────────────────────
class _PasoInfo {
  final String   numero, titulo, sub, guia;
  final IconData icono;
  const _PasoInfo({required this.numero, required this.titulo,
      required this.sub, required this.icono, required this.guia});
}