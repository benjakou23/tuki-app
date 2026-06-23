import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api_client.dart';
import '../../home/widgets/bottom_nav.dart';

const _bg        = Color(0xFF0D0F14);
const _surface   = Color(0x0AFFFFFF);
const _border    = Color(0x14FFFFFF);
const _blue      = Color(0xFF2563EB);
const _blueLight = Color(0xFF60A5FA);
const _blueDim   = Color(0x1A2563EB);
const _blueBorder = Color(0x332563EB);
const _green     = Color(0xFF34D399);
const _greenDim  = Color(0x1434D399);
const _greenBorder = Color(0x2834D399);
const _amber     = Color(0xFFFBBF24);
const _amberDim  = Color(0x14FBBF24);
const _amberBorder = Color(0x28FBBF24);
const _rose      = Color(0xFFF43F5E);
const _roseDim   = Color(0x14F43F5E);
const _roseBorder = Color(0x28F43F5E);
const _violet    = Color(0xFFA78BFA);
const _violetDim = Color(0x14A78BFA);
const _violetBorder = Color(0x28A78BFA);
const _textPri   = Color(0xFFFFFFFF);
const _textMid   = Color(0x99FFFFFF);
const _textDim   = Color(0x38FFFFFF);

class TrabajosScreen extends StatefulWidget {
  const TrabajosScreen({super.key});
  @override
  State<TrabajosScreen> createState() => _TrabajosScreenState();
}

class _TrabajosScreenState extends State<TrabajosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _pedidos = [];
  bool _cargando = true;

  TextStyle _tx(double s, FontWeight w, Color c, {double? ls, double? h}) =>
      GoogleFonts.inter(fontSize: s, fontWeight: w, color: c,
          letterSpacing: ls ?? 0, height: h);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final res = await ApiClient.get('/pedidos/mis-pedidos', auth: true);
      if (mounted) setState(() {
        _pedidos = res is List ? res : [];
        _cargando = false;
      });
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // Pedidos activos del técnico (aceptados, en progreso, etc.)
  List<dynamic> get _activos => _pedidos.where((p) {
    final e = p['estado'] as String? ?? '';
    return ['aceptado', 'confirmado', 'en_camino', 'en_progreso'].contains(e);
  }).toList();

  // Historial completado/cancelado
  List<dynamic> get _historial => _pedidos.where((p) {
    final e = p['estado'] as String? ?? '';
    return ['completado', 'cancelado'].contains(e);
  }).toList();

  Color _colorEstado(String e) => switch (e) {
    'aceptado'    => _blueLight,
    'confirmado'  => _violet,
    'en_camino'   => _amber,
    'en_progreso' => _green,
    'completado'  => _green,
    'cancelado'   => _rose,
    _             => _textMid,
  };

  Color _dimEstado(String e) => switch (e) {
    'aceptado'    => _blueDim,
    'confirmado'  => _violetDim,
    'en_camino'   => _amberDim,
    'en_progreso' => _greenDim,
    'completado'  => _greenDim,
    'cancelado'   => _roseDim,
    _             => _surface,
  };

  Color _borderEstado(String e) => switch (e) {
    'aceptado'    => _blueBorder,
    'confirmado'  => _violetBorder,
    'en_camino'   => _amberBorder,
    'en_progreso' => _greenBorder,
    'completado'  => _greenBorder,
    'cancelado'   => _roseBorder,
    _             => _border,
  };

  String _labelEstado(String e) => switch (e) {
    'aceptado'    => 'Aceptado',
    'confirmado'  => 'Confirmado',
    'en_camino'   => 'En camino',
    'en_progreso' => 'En progreso',
    'completado'  => 'Completado',
    'cancelado'   => 'Cancelado',
    _             => e,
  };

  String _tiempoRelativo(String? ts) {
    if (ts == null) return '';
    try {
      final d = DateTime.parse(ts).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
      if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
      final meses = ['','Ene','Feb','Mar','Abr','May','Jun',
        'Jul','Ago','Sep','Oct','Nov','Dic'];
      return '${d.day} ${meses[d.month]}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Container(
            color: _bg,
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
            child: Row(children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mis trabajos',
                    style: _tx(20, FontWeight.w500, _textPri, ls: -0.4)),
                  const SizedBox(height: 2),
                  Text('${_activos.length} activo${_activos.length == 1 ? '' : 's'} · ${_historial.length} completado${_historial.length == 1 ? '' : 's'}',
                    style: _tx(12, FontWeight.w400, _textDim)),
                ],
              )),
              GestureDetector(
                onTap: _cargar,
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border)),
                  child: const Icon(Icons.refresh_rounded,
                    size: 17, color: _textDim)),
              ),
            ]),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border)),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(10)),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: _tx(12, FontWeight.w500, _textPri),
                unselectedLabelStyle: _tx(12, FontWeight.w400, _textDim),
                labelColor: Colors.white,
                unselectedLabelColor: _textDim,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Activos (${_activos.length})'),
                  Tab(text: 'Historial (${_historial.length})'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Contenido
          Expanded(
            child: _cargando
              ? const Center(child: CircularProgressIndicator(
                  color: _blueLight, strokeWidth: 2))
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildLista(_activos, esActivo: true),
                    _buildLista(_historial, esActivo: false),
                  ],
                ),
          ),

          TukiBottomNav(
            index: 1,
            onTap: (i) {
              if (i == 0) context.go('/home');
              if (i == 2) context.go('/ganancias');
              if (i == 3) context.go('/perfil');
            },
            rol: 'tecnico',
          ),
        ]),
      ),
    );
  }

  Widget _buildLista(List<dynamic> pedidos, {required bool esActivo}) {
    if (pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border)),
              child: Icon(
                esActivo
                  ? Icons.work_outline_rounded
                  : Icons.history_rounded,
                size: 24, color: _textDim)),
            const SizedBox(height: 14),
            Text(
              esActivo ? 'Sin trabajos activos' : 'Sin historial aún',
              style: _tx(15, FontWeight.w500, _textMid)),
            const SizedBox(height: 4),
            Text(
              esActivo
                ? 'Acepta pedidos disponibles para empezar'
                : 'Tus trabajos completados aparecerán aquí',
              style: _tx(12, FontWeight.w400, _textDim),
              textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      color: _blueLight,
      backgroundColor: _bg,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        itemCount: pedidos.length,
        itemBuilder: (_, i) {
          final p = pedidos[i] as Map<String, dynamic>;
          final estado = p['estado'] as String? ?? '';
          final colorE = _colorEstado(estado);

          return GestureDetector(
            onTap: () => context.push('/pedido/${p['id']}'),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    // Ícono estado
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: _dimEstado(estado),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _borderEstado(estado))),
                      child: Icon(
                        esActivo
                          ? Icons.build_rounded
                          : Icons.check_circle_rounded,
                        size: 18, color: colorE)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['categoria'] ?? '',
                          style: _tx(14, FontWeight.w500, _textPri)),
                        const SizedBox(height: 2),
                        Text(p['distrito'] ?? '',
                          style: _tx(11, FontWeight.w400, _textDim)),
                      ],
                    )),
                    // Badge estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _dimEstado(estado),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _borderEstado(estado))),
                      child: Text(_labelEstado(estado),
                        style: _tx(10, FontWeight.w500, colorE))),
                  ]),

                  const SizedBox(height: 10),
                  Container(height: 1, color: _border),
                  const SizedBox(height: 10),

                  Row(children: [
                    // Descripción truncada
                    Expanded(
                      child: Text(p['descripcion'] ?? '',
                        style: _tx(12, FontWeight.w400, _textDim, h: 1.4),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 12),
                    // Precio
                    if (p['precio_acordado'] != null || p['precio_final'] != null)
                      Text(
                        'S/ ${p['precio_final'] ?? p['precio_acordado']}',
                        style: _tx(13, FontWeight.w600,
                          estado == 'completado' ? _green : _textMid)),
                    const SizedBox(width: 8),
                    Text(_tiempoRelativo(
                      p['completado_en'] ?? p['creado_en']),
                      style: _tx(11, FontWeight.w400, _textDim)),
                  ]),

                  // Si está activo muestra botón de ir al detalle
                  if (esActivo) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _dimEstado(estado),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _borderEstado(estado))),
                      child: Center(child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Ver detalle y continuar',
                            style: _tx(12, FontWeight.w500, colorE)),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded,
                            size: 13, color: colorE),
                        ],
                      )),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}