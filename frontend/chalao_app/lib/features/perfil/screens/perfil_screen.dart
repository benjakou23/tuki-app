import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';
import '../../../core/api_client.dart';
import '../../home/widgets/bottom_nav.dart';

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
const _rose      = Color(0xFFF43F5E);
const _roseDim   = Color(0x14F43F5E);
const _roseBorder = Color(0x28F43F5E);
const _textPri   = Color(0xFFFFFFFF);
const _textMid   = Color(0x99FFFFFF);
const _textMuted = Color(0x61FFFFFF);
const _textDim   = Color(0x38FFFFFF);

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _nombreCtrl   = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _bioCtrl      = TextEditingController();
  final _precioCtrl   = TextEditingController();
  File? _foto;
  bool _guardando = false;
  String? _error;
  Map<String, dynamic>? _perfil;

  TextStyle _tx(double s, FontWeight w, Color c, {double? ls, double? h}) =>
      GoogleFonts.inter(
          fontSize: s, fontWeight: w, color: c,
          letterSpacing: ls ?? 0, height: h);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _bioCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    final auth = context.read<AuthProvider>();
    final usuario = auth.usuario;
    if (usuario != null) {
      _nombreCtrl.text   = usuario['nombre'] ?? '';
      _telefonoCtrl.text = usuario['telefono'] ?? '';
    }
    if (auth.rol == 'tecnico') {
      try {
        final res = await ApiClient.get('/perfil/tecnico', auth: true);
        setState(() {
          _perfil = res;
          _bioCtrl.text    = res['bio'] ?? '';
          _precioCtrl.text = res['precio_minimo']?.toString() ?? '';
        });
      } catch (e) { debugPrint('Error perfil: $e'); }
    }
  }

  Future<void> _seleccionarFoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _foto = File(picked.path));
  }

  Future<void> _guardar() async {
    setState(() { _guardando = true; _error = null; });
    final auth = context.read<AuthProvider>();
    try {
      await ApiClient.patch('/usuarios/actualizar', {
        if (_nombreCtrl.text.trim().isNotEmpty)
          'nombre': _nombreCtrl.text.trim(),
      }, auth: true);

      if (auth.rol == 'tecnico') {
        await ApiClient.patch('/perfil/tecnico', {
          if (_bioCtrl.text.trim().isNotEmpty)
            'bio': _bioCtrl.text.trim(),
          if (_precioCtrl.text.trim().isNotEmpty)
            'precio_minimo': double.tryParse(_precioCtrl.text.trim()),
        }, auth: true);
      }

      await auth.refrescarUsuario();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Perfil actualizado',
            style: _tx(13, FontWeight.w400, _textPri)),
        backgroundColor: const Color(0xFF1A1D24),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
    } catch (_) {
      setState(() => _error = 'Error al guardar. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth         = context.watch<AuthProvider>();
    final nombre       = auth.usuario?['nombre'] ?? '';
    final rol          = auth.rol ?? '';
    final esTecnico    = rol == 'tecnico';
    final especialidades = (_perfil?['especialidades'] as List?)
        ?.map((e) => e.toString()).toList() ?? [];

    final partes   = nombre.trim().split(' ');
    final iniciales = partes.length >= 2
        ? '${partes[0][0]}${partes[1][0]}'.toUpperCase()
        : nombre.isNotEmpty ? nombre[0].toUpperCase() : 'T';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          // Header sin botón back
          Container(
            color: _bg,
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
            child: Row(children: [
              Expanded(
                child: Text('Mi perfil',
                  style: _tx(20, FontWeight.w500, _textPri, ls: -0.4))),
              // Botón cerrar sesión
              GestureDetector(
                onTap: () async {
                  await auth.cerrarSesion();
                  if (context.mounted) context.go('/login');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _roseDim,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _roseBorder)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.logout_rounded,
                      size: 14, color: _rose),
                    const SizedBox(width: 5),
                    Text('Salir',
                      style: _tx(12, FontWeight.w500, _rose)),
                  ]),
                ),
              ),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Avatar
                  Center(
                    child: Stack(children: [
                      GestureDetector(
                        onTap: _seleccionarFoto,
                        child: Container(
                          width: 84, height: 84,
                          decoration: BoxDecoration(
                              color: _blue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _surfaceHi, width: 2.5)),
                          child: _foto != null
                              ? ClipOval(child: Image.file(
                                  _foto!, fit: BoxFit.cover))
                              : Center(
                                  child: Text(iniciales,
                                      style: _tx(28, FontWeight.w500,
                                          Colors.white))),
                        ),
                      ),
                      Positioned(
                        bottom: 0, right: 0,
                        child: Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                              color: const Color(0xFF1A1D24),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: _border, width: 1.5)),
                          child: const Icon(Icons.camera_alt_outlined,
                              size: 13, color: _textMuted),
                        ),
                      ),
                    ]),
                  ),

                  const SizedBox(height: 10),

                  Center(child: Text(nombre,
                      style: _tx(15, FontWeight.w500, _textPri, ls: -0.2))),
                  const SizedBox(height: 4),
                  Center(child: Text(
                    esTecnico ? 'Técnico · Tuki' : 'Cliente · Tuki',
                    style: _tx(12, FontWeight.w400, _textDim))),

                  if (esTecnico && especialidades.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                            color: _greenDim,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _greenBorder)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.verified_rounded,
                              size: 12, color: _green),
                          const SizedBox(width: 5),
                          Text('Técnico verificado',
                              style: _tx(11, FontWeight.w500, _green)),
                        ]),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  _SectionDivider(label: 'Datos personales', tx: _tx),
                  const SizedBox(height: 14),

                  _FieldLabel(label: 'Nombre completo', tx: _tx),
                  const SizedBox(height: 8),
                  _DarkTextField(
                    controller: _nombreCtrl,
                    hint: 'Tu nombre completo',
                    tx: _tx),
                  const SizedBox(height: 16),

                  _FieldLabel(label: 'Número de celular', tx: _tx),
                  const SizedBox(height: 8),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        color: const Color(0x07FFFFFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border)),
                    child: Row(children: [
                      Text('+51 ',
                          style: _tx(14, FontWeight.w500, _blueLight)),
                      Text(_telefonoCtrl.text,
                          style: _tx(14, FontWeight.w400, _textMuted)),
                      const Spacer(),
                      const Icon(Icons.lock_outline_rounded,
                          size: 14, color: _textDim),
                    ]),
                  ),

                  if (esTecnico) ...[
                    const SizedBox(height: 28),
                    _SectionDivider(label: 'Perfil profesional', tx: _tx),
                    const SizedBox(height: 14),

                    _FieldLabel(label: 'Descripción', tx: _tx),
                    const SizedBox(height: 8),
                    _DarkTextField(
                      controller: _bioCtrl,
                      hint: 'Tu experiencia y especialización...',
                      maxLines: 3,
                      tx: _tx),
                    const SizedBox(height: 16),

                    _FieldLabel(label: 'Precio mínimo por servicio', tx: _tx),
                    const SizedBox(height: 8),
                    _DarkTextField(
                      controller: _precioCtrl,
                      hint: '50',
                      keyboardType: TextInputType.number,
                      prefix: 'S/ ',
                      tx: _tx),

                    if (especialidades.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      _SectionDivider(
                          label: 'Especialidades aprobadas', tx: _tx),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: especialidades.map((e) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                              color: _greenDim,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: _greenBorder)),
                          child: Row(mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    size: 11, color: _green),
                                const SizedBox(width: 5),
                                Text(e, style: _tx(12, FontWeight.w500, _green)),
                              ]),
                        )).toList(),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => context.go('/completar-perfil'),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text('Solicitar más especialidades',
                              style: _tx(12, FontWeight.w500, _blueLight)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 13, color: _blueLight),
                        ]),
                      ),
                    ],
                  ],

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                          color: _roseDim,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _roseBorder)),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 15, color: _rose),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!,
                            style: _tx(12, FontWeight.w400, _rose))),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Botón guardar
                  GestureDetector(
                    onTap: _guardando ? null : _guardar,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                          color: _guardando
                              ? const Color(0x40FFFFFF)
                              : _blue,
                          borderRadius: BorderRadius.circular(16)),
                      child: Center(
                        child: _guardando
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 17),
                                  const SizedBox(width: 8),
                                  Text('Guardar cambios',
                                      style: _tx(14, FontWeight.w500,
                                          Colors.white)),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Bottom nav
          TukiBottomNav(
            index: 3,
            onTap: (i) {
              if (i == 0) context.go('/home');
              if (i == 2 && auth.rol == 'cliente') context.go('/mis-pedidos');
              if (i == 1 && auth.rol == 'tecnico') context.go('/pedidos-disponibles');
              if (i == 2 && auth.rol == 'tecnico') context.go('/ganancias');
            },
            rol: rol.isEmpty ? 'cliente' : rol,
          ),
        ]),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _SectionDivider({required this.label, required this.tx});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: tx(11, FontWeight.w500,
        const Color(0x61FFFFFF), ls: 0.04)),
    const SizedBox(width: 10),
    Expanded(child: Container(height: 1, color: const Color(0x0AFFFFFF))),
  ]);
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _FieldLabel({required this.label, required this.tx});

  @override
  Widget build(BuildContext context) =>
      Text(label, style: tx(12, FontWeight.w400, const Color(0x61FFFFFF)));
}

class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;
  final String? prefix;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;

  const _DarkTextField({
    required this.controller,
    required this.hint,
    required this.tx,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF))),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(children: [
      if (prefix != null)
        Text(prefix!, style: tx(14, FontWeight.w500,
            const Color(0xFF60A5FA))),
      Expanded(
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: tx(14, FontWeight.w400, const Color(0xFFFFFFFF)),
          cursorColor: const Color(0xFF60A5FA),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            hintText: hint,
            hintStyle: tx(14, FontWeight.w400, const Color(0x38FFFFFF)),
            contentPadding: EdgeInsets.symmetric(
                vertical: maxLines > 1 ? 14 : 13)),
        ),
      ),
    ]),
  );
}