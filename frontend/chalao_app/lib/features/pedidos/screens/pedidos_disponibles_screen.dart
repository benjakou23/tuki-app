import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/api_client.dart';
import 'package:go_router/go_router.dart';
import '../../home/widgets/bottom_nav.dart';

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
const _rose      = Color(0xFFF43F5E);
const _roseDim   = Color(0x14F43F5E);
const _roseBorder = Color(0x28F43F5E);
const _textPri   = Color(0xFFFFFFFF);
const _textMid   = Color(0x99FFFFFF);
const _textMuted = Color(0x61FFFFFF);
const _textDim   = Color(0x38FFFFFF);

class PedidosDisponiblesScreen extends StatefulWidget {
  const PedidosDisponiblesScreen({super.key});
  @override
  State<PedidosDisponiblesScreen> createState() =>
      _PedidosDisponiblesScreenState();
}

class _PedidosDisponiblesScreenState
    extends State<PedidosDisponiblesScreen> {
  int _tab = 1;
  List<dynamic> _pedidos   = [];
  bool _cargando           = true;
  String? _error;
  Timer? _timer;
  RealtimeChannel? _canal;
  bool _nuevoPedido        = false;

  TextStyle _tx(double s, FontWeight w, Color c, {double? ls, double? h}) =>
      GoogleFonts.inter(
          fontSize: s, fontWeight: w, color: c,
          letterSpacing: ls ?? 0, height: h);

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
    _timer = Timer.periodic(
        const Duration(seconds: 5), (_) { if (mounted) _cargarPedidos(); });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _canal?.unsubscribe();
    super.dispose();
  }

  Future<void> _cargarPedidos() async {
    if (!_cargando) setState(() => _cargando = true);
    setState(() { _error = null; _nuevoPedido = false; });
    try {
      final res = await ApiClient.get('/pedidos/disponibles', auth: true);
      if (mounted) setState(() {
        _pedidos  = res is List ? res : [];
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _error    = 'Error al cargar pedidos';
        _cargando = false;
      });
    }
  }

  Future<void> _aceptar(String pedidoId, String precio) async {
    try {
      final precioNum = double.tryParse(precio);
      final res = await ApiClient.post(
        '/pedidos/$pedidoId/accion',
        {
          'accion': 'aceptar',
          if (precioNum != null) 'precio_acordado': precioNum,
        },
        auth: true,
      );
      if (!mounted) return;
      if (res['id'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Pedido aceptado',
              style: _tx(13, FontWeight.w400, _textPri)),
          backgroundColor: const Color(0xFF1A1D24),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
        context.go('/pedido/${res['id']}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res['detail'] ?? 'Error al aceptar',
              style: _tx(13, FontWeight.w400, _textPri)),
          backgroundColor: const Color(0xFF1A1D24),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error de conexión')));
    }
  }

  void _mostrarDetalle(Map<String, dynamic> pedido) {
    final precioCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161920),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            22, 10, 22, MediaQuery.of(context).viewInsets.bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: const Color(0x28FFFFFF),
                    borderRadius: BorderRadius.circular(999)),
              ),
            ),
            const SizedBox(height: 20),

            // Badge categoría
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: _blueDim,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _blueBorder)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.category_rounded,
                    size: 11, color: _blueLight),
                const SizedBox(width: 5),
                Text(pedido['categoria'] ?? '',
                    style: _tx(11, FontWeight.w500, _blueLight)),
              ]),
            ),
            const SizedBox(height: 12),

            Text(pedido['descripcion'] ?? '',
                style: _tx(16, FontWeight.w500, _textPri,
                    ls: -0.3, h: 1.4)),
            const SizedBox(height: 12),

            // Dirección
            Row(children: [
              const Icon(Icons.location_on_rounded,
                  size: 14, color: _textDim),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${pedido['direccion'] ?? ''}, ${pedido['distrito'] ?? ''}',
                  style: _tx(12, FontWeight.w400, _textMuted)),
              ),
            ]),
            const SizedBox(height: 8),

            // Tiempo
            Row(children: [
              const Icon(Icons.access_time_rounded,
                  size: 13, color: _textDim),
              const SizedBox(width: 6),
              Text(_tiempoRelativo(pedido['creado_en']),
                  style: _tx(11, FontWeight.w400, _textDim)),
            ]),

            const SizedBox(height: 20),

            // Campo precio
            Text('Tu precio por este servicio',
                style: _tx(12, FontWeight.w400, _textMuted)),
            const SizedBox(height: 8),
            Container(
              height: 50,
              decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border)),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(children: [
                Text('S/ ',
                    style: _tx(15, FontWeight.w500, _blueLight)),
                Expanded(
                  child: TextField(
                    controller: precioCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: _tx(15, FontWeight.w400, _textPri),
                    cursorColor: _blueLight,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: '80',
                      hintStyle: _tx(15, FontWeight.w400, _textDim),
                    ),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 18),

            // Botones
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border)),
                    child: Center(
                      child: Text('Rechazar',
                          style: _tx(13, FontWeight.w500, _textMuted)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _aceptar(pedido['id'], precioCtrl.text);
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 7),
                        Text('Aceptar pedido',
                            style: _tx(13, FontWeight.w500,
                                Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          // ── Header ──────────────────────────────────────────────────
          Container(
            color: _bg,
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Pedidos disponibles',
                      style: _tx(18, FontWeight.w500, _textPri, ls: -0.4)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                            color: _green, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('En tiempo real',
                        style: _tx(11, FontWeight.w400, _textDim)),
                  ]),
                ]),
                GestureDetector(
                  onTap: _cargarPedidos,
                  child: Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: _border)),
                    child: const Icon(Icons.refresh_rounded,
                        size: 17, color: _textMuted),
                  ),
                ),
              ],
            ),
          ),

          // ── Banner nuevo pedido ──────────────────────────────────────
          if (_nuevoPedido)
            GestureDetector(
              onTap: _cargarPedidos,
              child: Container(
                margin: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                    color: _greenDim,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _greenBorder)),
                child: Row(children: [
                  const Icon(Icons.notifications_active_rounded,
                      color: _green, size: 16),
                  const SizedBox(width: 8),
                  Text('Nuevo pedido disponible — toca para ver',
                      style: _tx(12, FontWeight.w500, _green)),
                ]),
              ),
            ),

          // ── Contenido ────────────────────────────────────────────────
          Expanded(child: _buildBody()),
        ]),
      ),
      bottomNavigationBar: TukiBottomNav(
        index: _tab,
        onTap: (i) {
          setState(() => _tab = i);
          if (i == 0) context.go('/home');
           if (i == 2) context.go('/ganancias');
          if (i == 3) context.go('/perfil');
        },
        rol: 'tecnico',
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(
          child: CircularProgressIndicator(
              color: _blueLight, strokeWidth: 2));
    }

    if (_error != null) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
            children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
                color: _roseDim,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _roseBorder)),
            child: const Icon(Icons.wifi_off_rounded,
                size: 22, color: _rose)),
          const SizedBox(height: 14),
          Text(_error!,
              style: _tx(13, FontWeight.w400, _textMuted)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _cargarPedidos,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _border)),
              child: Text('Reintentar',
                  style: _tx(12, FontWeight.w500, _textMid)),
            ),
          ),
        ]),
      );
    }

    if (_pedidos.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
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
          Text('Sin pedidos disponibles',
              style: _tx(14, FontWeight.w500, _textMid)),
          const SizedBox(height: 4),
          Text('Los nuevos pedidos aparecerán aquí\nautomáticamente',
              style: _tx(12, FontWeight.w400, _textDim),
              textAlign: TextAlign.center),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarPedidos,
      color: _blueLight,
      backgroundColor: const Color(0xFF1A1D24),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        itemCount: _pedidos.length,
        itemBuilder: (_, i) {
          final p = _pedidos[i] as Map<String, dynamic>;
          return GestureDetector(
            onTap: () => _mostrarDetalle(p),
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
                  // Fila superior: badge + tiempo
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                          color: _blueDim,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _blueBorder)),
                      child: Text(p['categoria'] ?? '',
                          style:
                              _tx(10, FontWeight.w500, _blueLight)),
                    ),
                    const Spacer(),
                    Row(children: [
                      const Icon(Icons.access_time_rounded,
                          size: 11, color: _textDim),
                      const SizedBox(width: 3),
                      Text(_tiempoRelativo(p['creado_en']),
                          style: _tx(10, FontWeight.w400, _textDim)),
                    ]),
                  ]),
                  const SizedBox(height: 10),

                  // Descripción
                  Text(p['descripcion'] ?? '',
                      style: _tx(13, FontWeight.w500, _textMid,
                          h: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),

                  // Fila inferior: distrito + botón
                  Row(children: [
                    const Icon(Icons.location_on_rounded,
                        size: 12, color: _textDim),
                    const SizedBox(width: 4),
                    Text(p['distrito'] ?? '',
                        style: _tx(11, FontWeight.w400, _textMuted)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(999)),
                      child: Text('Ver y ofertar',
                          style: _tx(10, FontWeight.w500,
                              Colors.white)),
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _tiempoRelativo(String? fechaStr) {
    if (fechaStr == null) return '';
    try {
      final diff = DateTime.now()
          .difference(DateTime.parse(fechaStr).toLocal());
      if (diff.inSeconds < 60) return 'Ahora mismo';
      if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
      return 'Hace ${diff.inDays}d';
    } catch (_) { return ''; }
  }
}