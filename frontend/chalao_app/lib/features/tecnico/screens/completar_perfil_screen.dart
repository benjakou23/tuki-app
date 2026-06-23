import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';
import '../../../core/api_client.dart';

// ── Paleta dark (consistente con el sistema) ──────────────────────────────────
const _bg        = Color(0xFF0D0F14);
const _surface   = Color(0x0AFFFFFF);   // 4%
const _surfaceHi = Color(0x14FFFFFF);   // 8%
const _border    = Color(0x14FFFFFF);
const _borderMd  = Color(0x1FFFFFFF);   // 12%
const _blue      = Color(0xFF2563EB);
const _blueLight = Color(0xFF60A5FA);
const _blueDim   = Color(0x1A60A5FA);
const _blueBorder = Color(0x3360A5FA);
const _amber     = Color(0xFFFBBF24);
const _amberDim  = Color(0x14FBBF24);
const _amberBorder = Color(0x28FBBF24);
const _rose      = Color(0xFFF43F5E);
const _roseDim   = Color(0x14F43F5E);
const _roseBorder = Color(0x28F43F5E);
const _textPri   = Color(0xFFFFFFFF);
const _textMid   = Color(0x99FFFFFF);   // 60%
const _textMuted = Color(0x61FFFFFF);   // 38%
const _textDim   = Color(0x38FFFFFF);   // 22%

class CompletarPerfilScreen extends StatefulWidget {
  const CompletarPerfilScreen({super.key});
  @override
  State<CompletarPerfilScreen> createState() =>
      _CompletarPerfilScreenState();
}

class _CompletarPerfilScreenState extends State<CompletarPerfilScreen> {
  final _bioCtrl      = TextEditingController();
  final _precioCtrl   = TextEditingController();
  final _distritoCtrl = TextEditingController();
  final List<String> _especialidades = [];
  bool _enviando = false;
  bool _cargando = true;
  String? _error;

  static const _categorias = [
    'Gasfitería', 'Electricidad', 'Pintura', 'Celulares',
    'Refrigeración', 'Carpintería', 'Cerrajería', 'Limpieza',
    'Albañilería', 'Jardinería',
  ];

  static const _distritos = [
    'Chiclayo', 'José Leonardo Ortiz', 'La Victoria',
    'Pimentel', 'San José', 'Monsefú', 'Reque',
    'Eten', 'Tumán', 'Pomalca', 'Lambayeque',
  ];

  TextStyle _tx(double s, FontWeight w, Color c, {double? ls, double? h}) =>
      GoogleFonts.inter(
          fontSize: s, fontWeight: w, color: c,
          letterSpacing: ls ?? 0, height: h);

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _precioCtrl.dispose();
    _distritoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    try {
      final res = await ApiClient.get('/perfil/tecnico', auth: true);
      setState(() {
        _bioCtrl.text    = res['bio'] ?? '';
        _precioCtrl.text = res['precio_minimo']?.toString() ?? '';
        _distritoCtrl.text = res['distrito'] ?? '';
        if (res['especialidades'] != null) {
          _especialidades.addAll(List<String>.from(res['especialidades']));
        }
        _cargando = false;
      });
    } catch (_) { setState(() => _cargando = false); }
  }

  Future<void> _guardar() async {
    if (_especialidades.isEmpty) {
      setState(() => _error = 'Selecciona al menos una especialidad');
      return;
    }
    setState(() { _enviando = true; _error = null; });
    try {
      await ApiClient.patch('/perfil/tecnico', {
        if (_bioCtrl.text.trim().isNotEmpty)    'bio': _bioCtrl.text.trim(),
        if (_precioCtrl.text.trim().isNotEmpty)
          'precio_minimo': double.tryParse(_precioCtrl.text.trim()),
        if (_distritoCtrl.text.trim().isNotEmpty)
          'distrito': _distritoCtrl.text.trim(),
      }, auth: true);

      await ApiClient.post('/perfil/tecnico/solicitar-especialidades',
          {'especialidades': _especialidades}, auth: true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Perfil enviado. Las especialidades serán revisadas en 24-48h.',
          style: _tx(13, FontWeight.w400, _textPri)),
        backgroundColor: const Color(0xFF1A1D24),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ));
      context.go('/home');
    } catch (_) {
      setState(() => _error = 'Error al guardar. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(
            color: _blueLight, strokeWidth: 2)));
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 18),

                  // ── Info banner ──────────────────────────────────────
                  _InfoBanner(tx: _tx),
                  const SizedBox(height: 26),

                  // ── Especialidades ───────────────────────────────────
                  _SectionLabel(
                      title: 'Especialidades',
                      subtitle: 'Selecciona los servicios que ofreces',
                      tx: _tx),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _categorias.map((cat) {
                      final sel = _especialidades.contains(cat);
                      return GestureDetector(
                        onTap: () => setState(() {
                          sel
                              ? _especialidades.remove(cat)
                              : _especialidades.add(cat);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel ? _blue : _surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: sel
                                    ? _blue
                                    : _border),
                          ),
                          child: Text(cat,
                              style: _tx(12, FontWeight.w500,
                                  sel ? Colors.white : _textMuted)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 26),

                  // ── Bio ──────────────────────────────────────────────
                  _SectionLabel(
                      title: 'Descripción profesional',
                      tx: _tx),
                  const SizedBox(height: 10),
                  _DarkTextField(
                    controller: _bioCtrl,
                    hint: 'Cuéntanos tu experiencia, especialización...',
                    maxLines: 3,
                    tx: _tx,
                  ),
                  const SizedBox(height: 20),

                  // ── Precio ───────────────────────────────────────────
                  _SectionLabel(
                      title: 'Precio mínimo por servicio',
                      tx: _tx),
                  const SizedBox(height: 10),
                  _DarkTextField(
                    controller: _precioCtrl,
                    hint: '50',
                    keyboardType: TextInputType.number,
                    prefix: 'S/ ',
                    tx: _tx,
                  ),
                  const SizedBox(height: 20),

                  // ── Distrito ─────────────────────────────────────────
                  _SectionLabel(
                      title: 'Distrito donde trabajas',
                      tx: _tx),
                  const SizedBox(height: 10),
                  _DarkDropdown(
                    value: _distritoCtrl.text.isEmpty
                        ? null
                        : _distritoCtrl.text,
                    items: _distritos,
                    hint: 'Selecciona tu distrito',
                    onChanged: (v) =>
                        setState(() => _distritoCtrl.text = v ?? ''),
                    tx: _tx,
                  ),

                  // ── Error ────────────────────────────────────────────
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
                        Expanded(
                          child: Text(_error!,
                              style: _tx(12, FontWeight.w400, _rose)),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── Botón guardar ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
            child: GestureDetector(
              onTap: _enviando ? null : _guardar,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                    color: _enviando
                        ? const Color(0x40FFFFFF)
                        : _blue,
                    borderRadius: BorderRadius.circular(16)),
                child: Center(
                  child: _enviando
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.send_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text('Guardar y enviar a revisión',
                                style: _tx(14, FontWeight.w500,
                                    Colors.white)),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Container(
    color: _bg,
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
    child: Row(children: [
      _IconBtn(onTap: () => context.go('/home')),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Completa tu perfil',
            style: _tx(17, FontWeight.w500, _textPri, ls: -0.3)),
        const SizedBox(height: 2),
        Text('Técnico · Tuki',
            style: _tx(12, FontWeight.w400, _textDim)),
      ]),
    ]),
  );
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _InfoBanner({required this.tx});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: const Color(0x14FBBF24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x28FBBF24))),
    child: Row(children: [
      const Icon(Icons.schedule_rounded, color: Color(0xFFFBBF24), size: 18),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          'Las especialidades requieren aprobación del equipo Tuki en 24-48 horas.',
          style: tx(12, FontWeight.w400, const Color(0xFFFBBF24), h: 1.4),
        ),
      ),
    ]),
  );
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _SectionLabel(
      {required this.title, this.subtitle, required this.tx});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title,
          style: tx(13, FontWeight.w500, const Color(0x99FFFFFF))),
      if (subtitle != null) ...[
        const SizedBox(height: 2),
        Text(subtitle!,
            style: tx(11, FontWeight.w400, const Color(0x38FFFFFF))),
      ],
    ],
  );
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
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x14FFFFFF))),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        if (prefix != null)
          Text(prefix!,
              style: tx(14, FontWeight.w500, const Color(0xFF60A5FA))),
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
                  vertical: maxLines > 1 ? 14 : 13),
            ),
          ),
        ),
      ]),
    );
  }
}

class _DarkDropdown extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String hint;
  final ValueChanged<String?> onChanged;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;

  const _DarkDropdown({
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
    required this.tx,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14FFFFFF))),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        dropdownColor: const Color(0xFF161920),
        borderRadius: BorderRadius.circular(14),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Color(0x38FFFFFF), size: 20),
        hint: Text(hint,
            style: tx(14, FontWeight.w400, const Color(0x38FFFFFF))),
        items: items.map((d) => DropdownMenuItem(
          value: d,
          child: Text(d,
              style: tx(14, FontWeight.w400, const Color(0xFFFFFFFF))),
        )).toList(),
        onChanged: onChanged,
        style: tx(14, FontWeight.w400, const Color(0xFFFFFFFF)),
      ),
    ),
  );
}

class _IconBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _IconBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0x14FFFFFF))),
      child: const Icon(Icons.arrow_back_ios_new_rounded,
          size: 15, color: Color(0x61FFFFFF)),
    ),
  );
}