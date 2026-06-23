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
const _green     = Color(0xFF34D399);
const _amber     = Color(0xFFFBBF24);
const _red       = Color(0xFFFC6B6B);
const _textPri   = Color(0xFFFFFFFF);
const _textMid   = Color(0x99FFFFFF);
const _textDim   = Color(0x38FFFFFF);

class MisPedidosScreen extends StatefulWidget {
  const MisPedidosScreen({super.key});
  @override
  State<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends State<MisPedidosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _pedidos = [];
  bool _cargando = true;

  TextStyle _tx(double s, FontWeight w, Color c, {double? ls}) =>
      GoogleFonts.inter(fontSize: s, fontWeight: w, color: c,
          letterSpacing: ls ?? 0);

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

  List<dynamic> get _activos => _pedidos.where((p) {
    final e = p['estado'] as String? ?? '';
    return !['completado', 'cancelado'].contains(e);
  }).toList();

  List<dynamic> get _historial => _pedidos.where((p) {
    final e = p['estado'] as String? ?? '';
    return ['completado', 'cancelado'].contains(e);
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
            child: Row(children: [
              Expanded(
                child: Text('Mis pedidos',
                  style: _tx(20, FontWeight.w500, _textPri, ls: -0.4))),
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

          const SizedBox(height: 16),

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
                tabs: const [
                  Tab(text: 'Activos'),
                  Tab(text: 'Historial'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Contenido
          Expanded(
            child: _cargando
              ? const Center(child: CircularProgressIndicator(
                  color: _blueLight, strokeWidth: 2))
              : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _ListaPedidos(
                      pedidos: _activos,
                      vacio: 'Sin pedidos activos',
                      vaciSub: 'Crea una solicitud desde el inicio',
                     onTap: (id) => context.push('/pedido/$id'),
                      onRefresh: _cargar,
                    ),
                    _ListaPedidos(
                      pedidos: _historial,
                      vacio: 'Sin historial aún',
                      vaciSub: 'Tus pedidos completados aparecerán aquí',
                     onTap: (id) => context.push('/pedido/$id'),
                      onRefresh: _cargar,
                    ),
                  ],
                ),
          ),
        ]),
      ),
      bottomNavigationBar: TukiBottomNav(
        index: 2,
        onTap: (i) {
          if (i == 0) context.go('/home');
          if (i == 3) context.go('/perfil');
        },
        rol: 'cliente',
      ),
    );
  }
}

class _ListaPedidos extends StatelessWidget {
  final List<dynamic> pedidos;
  final String vacio;
  final String vaciSub;
  final Function(String) onTap;
  final Future<void> Function() onRefresh;

  const _ListaPedidos({
    required this.pedidos,
    required this.vacio,
    required this.vaciSub,
    required this.onTap,
    required this.onRefresh,
  });

  static const _bg        = Color(0xFF0D0F14);
  static const _surface   = Color(0x0AFFFFFF);
  static const _border    = Color(0x14FFFFFF);
  static const _blue      = Color(0xFF2563EB);
  static const _blueLight = Color(0xFF60A5FA);
  static const _green     = Color(0xFF34D399);
  static const _amber     = Color(0xFFFBBF24);
  static const _red       = Color(0xFFFC6B6B);
  static const _textMid   = Color(0x99FFFFFF);
  static const _textDim   = Color(0x38FFFFFF);

  TextStyle _tx(double s, FontWeight w, Color c) =>
      GoogleFonts.inter(fontSize: s, fontWeight: w, color: c);

  Color _colorEstado(String e) {
    switch (e) {
      case 'pendiente':   return _amber;
      case 'aceptado':    return _blueLight;
      case 'confirmado':  return const Color(0xFFA78BFA);
      case 'en_camino':   return _amber;
      case 'en_progreso': return _green;
      case 'completado':  return _green;
      case 'cancelado':   return _red;
      default: return _textDim;
    }
  }

  String _labelEstado(String e) {
    switch (e) {
      case 'pendiente':   return 'Pendiente';
      case 'aceptado':    return 'Técnico asignado';
      case 'confirmado':  return 'Confirmado';
      case 'en_camino':   return 'En camino';
      case 'en_progreso': return 'En progreso';
      case 'completado':  return 'Completado';
      case 'cancelado':   return 'Cancelado';
      default: return e;
    }
  }

  String _tiempoRelativo(String? ts) {
    if (ts == null) return '';
    try {
      final d = DateTime.parse(ts).toLocal();
      final diff = DateTime.now().difference(d);
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
      if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
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
              child: const Icon(Icons.inbox_outlined,
                size: 24, color: _textDim)),
            const SizedBox(height: 14),
            Text(vacio,
              style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w500,
                color: _textMid)),
            const SizedBox(height: 4),
            Text(vaciSub,
              style: GoogleFonts.inter(fontSize: 12, color: _textDim),
              textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: _blueLight,
      backgroundColor: _bg,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        itemCount: pedidos.length,
        itemBuilder: (_, i) {
          final p = pedidos[i] as Map<String, dynamic>;
          final estado = p['estado'] as String? ?? '';
          final color = _colorEstado(estado);
          final calificacion = p['calificacion'];

          return GestureDetector(
            onTap: () => onTap(p['id']),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6)),
                      child: Text(p['categoria'] ?? '',
                        style: _tx(10, FontWeight.w500, _blueLight))),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: color.withValues(alpha: 0.20))),
                      child: Text(_labelEstado(estado),
                        style: _tx(10, FontWeight.w500, color))),
                  ]),

                  const SizedBox(height: 10),

                  Text(p['descripcion'] ?? '',
                    style: _tx(13, FontWeight.w400, _textMid),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),

                  const SizedBox(height: 8),

                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                      size: 12, color: _textDim),
                    const SizedBox(width: 4),
                    Text(p['distrito'] ?? '',
                      style: _tx(11, FontWeight.w400, _textDim)),
                    const Spacer(),
                    if (p['precio_acordado'] != null) ...[
                      const Icon(Icons.attach_money_rounded,
                        size: 12, color: _textDim),
                      Text('S/ ${p['precio_acordado']}',
                        style: _tx(11, FontWeight.w500, _textMid)),
                      const SizedBox(width: 8),
                    ],
                    Text(_tiempoRelativo(p['creado_en']),
                      style: _tx(11, FontWeight.w400, _textDim)),
                  ]),

                  if (estado == 'completado' && calificacion != null) ...[
                    const SizedBox(height: 8),
                    Container(height: 1, color: _border),
                    const SizedBox(height: 8),
                    Row(children: [
                      ...List.generate(5, (i) => Icon(
                        i < (calificacion as num).round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                        size: 14, color: _amber)),
                      const SizedBox(width: 6),
                      Text('Tu calificación',
                        style: _tx(11, FontWeight.w400, _textDim)),
                    ]),
                  ],

                  if (estado == 'completado' && calificacion == null) ...[
                    const SizedBox(height: 8),
                    Container(height: 1, color: _border),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.star_outline_rounded,
                        size: 14, color: _amber),
                      const SizedBox(width: 6),
                      Text('Pendiente de calificar',
                        style: _tx(11, FontWeight.w400, _amber)),
                      const Spacer(),
                      Text('Toca para calificar →',
                        style: _tx(11, FontWeight.w500, _blueLight)),
                    ]),
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