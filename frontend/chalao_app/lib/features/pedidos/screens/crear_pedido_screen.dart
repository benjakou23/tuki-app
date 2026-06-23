// crear_pedido_screen.dart — Rediseño dark
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/api_client.dart';
import '../../../core/ubicacion_service.dart';

// ── Paleta ────────────────────────────────────────────────────────────────────
const _bg        = Color(0xFF0D0F14);
const _surface   = Color(0x0AFFFFFF);
const _border    = Color(0x14FFFFFF);
const _blue      = Color(0xFF2563EB);
const _blueLight = Color(0xFF60A5FA);
const _green     = Color(0xFF34D399);
const _errorFg   = Color(0xFFF87171);
const _errorBg   = Color(0x14E24B4A);
const _errorBd   = Color(0x33E24B4A);
const _textPri   = Color(0xFFFFFFFF);
const _textMid   = Color(0x99FFFFFF);
const _textMuted = Color(0x61FFFFFF);
const _textDim   = Color(0x38FFFFFF);

class CrearPedidoScreen extends StatefulWidget {
  const CrearPedidoScreen({super.key});
  @override
  State<CrearPedidoScreen> createState() => _CrearPedidoScreenState();
}

class _CrearPedidoScreenState extends State<CrearPedidoScreen> {
  final _descripcionCtrl = TextEditingController();
  final _direccionCtrl   = TextEditingController();
  final _distritoCtrl    = TextEditingController();

  String?   _categoriaSeleccionada;
  bool      _enviando      = false;
  String?   _error;
  Position? _miPosicion;
  bool      _obteniendoGPS = false;

  static const _categorias = [
    {'icon': Icons.water_drop_outlined,        'label': 'Gasfitería'},
    {'icon': Icons.bolt_outlined,              'label': 'Electricidad'},
    {'icon': Icons.format_paint_outlined,      'label': 'Pintura'},
    {'icon': Icons.phone_android_outlined,     'label': 'Celulares'},
    {'icon': Icons.ac_unit_outlined,           'label': 'Refrigeración'},
    {'icon': Icons.carpenter_outlined,         'label': 'Carpintería'},
    {'icon': Icons.lock_outline_rounded,       'label': 'Cerrajería'},
    {'icon': Icons.cleaning_services_outlined, 'label': 'Limpieza'},
    {'icon': Icons.foundation_outlined,        'label': 'Albañilería'},
    {'icon': Icons.grass_outlined,             'label': 'Jardinería'},
  ];

  static const _distritos = [
    'Chiclayo', 'José Leonardo Ortiz', 'La Victoria',
    'Pimentel', 'San José', 'Monsefú', 'Reque',
    'Eten', 'Tumán', 'Pomalca', 'Lambayeque',
  ];

  TextStyle _tx(double s, FontWeight w, Color c, {double? ls, double? h}) =>
      GoogleFonts.inter(fontSize: s, fontWeight: w, color: c,
          letterSpacing: ls ?? 0, height: h);

  // Campo oscuro reutilizable
  InputDecoration _campo({required String hint, Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: _tx(14, FontWeight.w400, _textDim),
        suffixIcon: suffix,
        filled: true,
        fillColor: _surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: _blueLight.withValues(alpha: 0.4), width: 1),
        ),
      );

  @override
  void initState() {
    super.initState();
    _obtenerUbicacion();
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    _direccionCtrl.dispose();
    _distritoCtrl.dispose();
    super.dispose();
  }

  Future<void> _obtenerUbicacion() async {
    setState(() => _obteniendoGPS = true);
    final pos = await UbicacionService.obtenerUbicacion();
    if (mounted) setState(() {
      _miPosicion    = pos;
      _obteniendoGPS = false;
    });
  }

  Future<void> _enviar() async {
    if (_categoriaSeleccionada == null) {
      setState(() => _error = 'Selecciona una categoría'); return; }
    if (_descripcionCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Describe el problema'); return; }
    if (_direccionCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Ingresa tu dirección'); return; }
    if (_distritoCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Selecciona tu distrito'); return; }

    setState(() { _enviando = true; _error = null; });

    try {
      final res = await ApiClient.post(
        '/pedidos/',
        {
          'categoria':   _categoriaSeleccionada,
          'descripcion': _descripcionCtrl.text.trim(),
          'direccion':   _direccionCtrl.text.trim(),
          'distrito':    _distritoCtrl.text.trim(),
          if (_miPosicion != null) 'lat': _miPosicion!.latitude,
          if (_miPosicion != null) 'lng': _miPosicion!.longitude,
        },
        auth: true,
      );

      if (!mounted) return;

      if (res['id'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Solicitud enviada. Los técnicos serán notificados.',
            style: _tx(13, FontWeight.w400, _textPri)),
          backgroundColor: const Color(0xFF1C1F28),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
        context.go('/home');
      } else {
        setState(() => _error = res['detail'] ?? 'Error al crear solicitud');
      }
    } catch (_) {
      setState(() => _error = 'Error de conexión. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          const _Divider(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategorias(),
                  _buildDescripcion(),
                  _buildUbicacion(),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _ErrorBar(message: _error!, tx: _tx),
                  ],
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ]),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
    child: Row(children: [
      GestureDetector(
        onTap: () => context.go('/home'),
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
      const SizedBox(width: 14),
      Text('Nueva solicitud',
          style: _tx(17, FontWeight.w500, _textMid, ls: -0.3)),
    ]),
  );

  // ── Grid de categorías ────────────────────────────────────────────────────
  Widget _buildCategorias() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('¿Qué tipo de servicio necesitas?',
          style: _tx(14, FontWeight.w500, _textMid)),
      const SizedBox(height: 3),
      Text('Selecciona una categoría',
          style: _tx(12, FontWeight.w400, _textDim)),
      const SizedBox(height: 14),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.88,
        ),
        itemCount: _categorias.length,
        itemBuilder: (_, i) {
          final cat   = _categorias[i];
          final label = cat['label'] as String;
          final icon  = cat['icon']  as IconData;
          final sel   = _categoriaSeleccionada == label;
          return GestureDetector(
            onTap: () => setState(() {
              _categoriaSeleccionada = label;
              _error = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: sel
                    ? _blue.withValues(alpha: 0.12)
                    : _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: sel
                      ? _blue.withValues(alpha: 0.40)
                      : _border)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 19,
                      color: sel ? _blueLight : _textDim),
                  const SizedBox(height: 6),
                  Text(label,
                    style: _tx(9, FontWeight.w400,
                        sel ? _blueLight : _textDim),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 24),
    ],
  );

  // ── Descripción ───────────────────────────────────────────────────────────
  Widget _buildDescripcion() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Describe el problema',
          style: _tx(14, FontWeight.w500, _textMid)),
      const SizedBox(height: 3),
      Text('Cuanto más detallado, mejor cotización recibirás',
          style: _tx(12, FontWeight.w400, _textDim)),
      const SizedBox(height: 10),
      TextField(
        controller: _descripcionCtrl,
        maxLines: 4,
        style: _tx(14, FontWeight.w400, _textPri),
        cursorColor: _blueLight,
        decoration: _campo(
          hint: 'Ej: El caño de la cocina tiene una fuga desde hace 2 días...',
        ).copyWith(contentPadding: const EdgeInsets.all(16)),
      ),
      const SizedBox(height: 22),
    ],
  );

  // ── Ubicación ─────────────────────────────────────────────────────────────
  Widget _buildUbicacion() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('¿Dónde necesitas el servicio?',
          style: _tx(14, FontWeight.w500, _textMid)),
      const SizedBox(height: 12),

      // Indicador GPS
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _miPosicion != null
              ? _green.withValues(alpha: 0.06)
              : _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _miPosicion != null
                ? _green.withValues(alpha: 0.20)
                : _border)),
        child: Row(children: [
          Icon(
            _miPosicion != null
                ? Icons.location_on_outlined
                : Icons.location_searching_rounded,
            size: 17,
            color: _miPosicion != null ? _green : _textDim,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _obteniendoGPS
                  ? 'Obteniendo tu ubicación...'
                  : _miPosicion != null
                      ? 'Ubicación obtenida (lat: ${_miPosicion!.latitude.toStringAsFixed(4)})'
                      : 'No se pudo obtener ubicación GPS',
              style: _tx(12, FontWeight.w400,
                  _miPosicion != null ? _green : _textDim),
            ),
          ),
          if (_miPosicion == null && !_obteniendoGPS)
            GestureDetector(
              onTap: _obtenerUbicacion,
              child: Text('Reintentar',
                  style: _tx(12, FontWeight.w400, _blueLight)),
            ),
        ]),
      ),

      // Dirección
      TextField(
        controller: _direccionCtrl,
        style: _tx(14, FontWeight.w400, _textPri),
        cursorColor: _blueLight,
        decoration: _campo(
          hint: 'Calle, número, referencia...',
          suffix: const Icon(Icons.location_on_outlined,
              size: 18, color: _textDim),
        ),
      ),

      const SizedBox(height: 12),

      // Etiqueta distrito
      Text('Distrito',
          style: _tx(11, FontWeight.w400, _textDim, ls: 0.04)),
      const SizedBox(height: 7),

      // Dropdown
      Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _distritoCtrl.text.isEmpty ? null : _distritoCtrl.text,
            dropdownColor: const Color(0xFF1A1D24),
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: _textDim),
            hint: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Selecciona tu distrito',
                  style: _tx(14, FontWeight.w400, _textDim)),
            ),
            isExpanded: true,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            borderRadius: BorderRadius.circular(14),
            items: _distritos.map((d) => DropdownMenuItem(
              value: d,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(d,
                    style: _tx(14, FontWeight.w400, _textPri)),
              ),
            )).toList(),
            onChanged: (v) => setState(() => _distritoCtrl.text = v ?? ''),
          ),
        ),
      ),
    ],
  );

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() => Padding(
    padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
    child: Material(
      color: _enviando ? _blue.withValues(alpha: 0.35) : _blue,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: _enviando ? null : _enviar,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: double.infinity, height: 52,
          child: Center(
            child: _enviando
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Enviar solicitud',
                        style: _tx(15, FontWeight.w500, Colors.white)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 16),
                  ]),
          ),
        ),
      ),
    ),
  );
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Container(
    height: 0.5,
    margin: const EdgeInsets.symmetric(horizontal: 22),
    color: const Color(0x0FFFFFFF),
  );
}

class _ErrorBar extends StatelessWidget {
  final String message;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _ErrorBar({required this.message, required this.tx});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: _errorBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _errorBd)),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, size: 16, color: _errorFg),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: tx(12, FontWeight.w400, _errorFg))),
    ]),
  );
}