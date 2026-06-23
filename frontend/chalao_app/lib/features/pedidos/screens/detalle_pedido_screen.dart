import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api_client.dart';
import '../../../core/auth_provider.dart';
import '../../../core/ubicacion_service.dart';

// ── Paleta dark (consistente con home_cliente_screen) ─────────────────────────
const _bg        = Color(0xFF0D0F14);
const _surface   = Color(0x0AFFFFFF);   // 4%
const _surfaceMd = Color(0x14FFFFFF);   // 8%
const _border    = Color(0x14FFFFFF);   // 8%
const _borderMd  = Color(0x1FFFFFFF);   // 12%
const _blue      = Color(0xFF2563EB);
const _blueLight = Color(0xFF60A5FA);
const _blueDim   = Color(0x1A2563EB);   // 10%
const _blueBorder = Color(0x332563EB);  // 20%
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
const _textMid   = Color(0x99FFFFFF);   // 60%
const _textMuted = Color(0x61FFFFFF);   // 38%
const _textDim   = Color(0x38FFFFFF);   // 22%

class DetallePedidoScreen extends StatefulWidget {
  final String pedidoId;
  const DetallePedidoScreen({super.key, required this.pedidoId});

  @override
  State<DetallePedidoScreen> createState() => _DetallePedidoScreenState();
}

class _DetallePedidoScreenState extends State<DetallePedidoScreen> {
  Map<String, dynamic>? _pedido;
  bool _cargando = true;

  Timer? _timer;
  Timer? _gpsTimer;
  RealtimeChannel? _canalUbicacion;

  LatLng? _posicionTecnico;
  LatLng? _posicionCliente;

  final _mapCtrl = MapController();

  TextStyle _tx(double s, FontWeight w, Color c, {double? ls, double? h}) =>
      GoogleFonts.inter(
          fontSize: s, fontWeight: w, color: c,
          letterSpacing: ls ?? 0, height: h);

  @override
  void initState() {
    super.initState();
    _cargar();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _cargar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gpsTimer?.cancel();
    _canalUbicacion?.unsubscribe();
    super.dispose();
  }

  Future<void> _cargar() async {
    try {
      final res = await ApiClient.get('/pedidos/${widget.pedidoId}', auth: true);
      if (!mounted) return;
      final estadoAnterior = _pedido?['estado'];
      setState(() {
        _pedido = res;
        _cargando = false;
      });
      if (res['lat'] != null && res['lng'] != null) {
        setState(() => _posicionCliente = LatLng(
            (res['lat'] as num).toDouble(),
            (res['lng'] as num).toDouble()));
      }
      if (res['estado'] == 'en_camino' &&
          (estadoAnterior != 'en_camino' || _canalUbicacion == null)) {
        _iniciarTracking();
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _iniciarTracking() {
    final rol = context.read<AuthProvider>().rol;
    final tecnicoId = _pedido?['tecnico_id'] as String?;
    if (tecnicoId == null) return;

    if (_canalUbicacion == null) {
      _canalUbicacion = Supabase.instance.client
          .channel('ubicacion_tecnico_$tecnicoId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'ubicaciones_tecnicos',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'tecnico_id',
              value: tecnicoId,
            ),
            callback: (payload) {
              final data = payload.newRecord;
              if (data['lat'] != null && data['lng'] != null && mounted) {
                setState(() => _posicionTecnico = LatLng(
                    (data['lat'] as num).toDouble(),
                    (data['lng'] as num).toDouble()));
              }
            },
          )
          .subscribe();
    }
    _cargarPosicionTecnico(tecnicoId);
    if (rol == 'tecnico' && _gpsTimer == null) _iniciarEnvioGPS();
  }

  Future<void> _cargarPosicionTecnico(String tecnicoId) async {
    try {
      final data = await Supabase.instance.client
          .from('ubicaciones_tecnicos')
          .select()
          .eq('tecnico_id', tecnicoId)
          .single();
      if (mounted && data['lat'] != null && data['lng'] != null) {
        setState(() => _posicionTecnico = LatLng(
            (data['lat'] as num).toDouble(),
            (data['lng'] as num).toDouble()));
      }
    } catch (e) {
      debugPrint('Error posición técnico: $e');
    }
  }

  void _iniciarEnvioGPS() {
    final usuarioId = context.read<AuthProvider>().usuarioId;
    if (usuarioId == null) return;
    _gpsTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final pos = await UbicacionService.obtenerUbicacion();
      if (pos != null) {
        await UbicacionService.actualizarPosicionTecnico(
          tecnicoId: usuarioId,
          lat: pos.latitude,
          lng: pos.longitude,
          disponible: true,
        );
      }
    });
  }

  Future<void> _accion(String accion, {double? precioFinal}) async {
    try {
      final body = <String, dynamic>{'accion': accion};
      if (precioFinal != null) body['precio_final'] = precioFinal;
      final res = await ApiClient.post(
          '/pedidos/${widget.pedidoId}/accion', body, auth: true);
      if (!mounted) return;
      if (res['id'] != null) {
        setState(() => _pedido = res);
        if (accion == 'en_camino') _iniciarTracking();
        if (accion == 'llegar') {
          _gpsTimer?.cancel();
          _gpsTimer = null;
          _canalUbicacion?.unsubscribe();
          _canalUbicacion = null;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_mensajeAccion(accion),
              style: _tx(13, FontWeight.w500, _textPri)),
          backgroundColor: const Color(0xFF1A1D24),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Error. Intenta de nuevo.')));
      }
    }
  }

  String _mensajeAccion(String accion) => switch (accion) {
        'confirmar'  => 'Técnico confirmado',
        'en_camino'  => 'En camino al cliente',
        'llegar'     => 'Llegada confirmada',
        'completar'  => 'Trabajo completado',
        'cancelar'   => 'Pedido cancelado',
        _            => 'Acción realizada',
      };

  // ── Colores por estado ────────────────────────────────────────────────────
  Color _colorEstado(String estado) => switch (estado) {
        'pendiente' || 'en_camino' => _amber,
        'aceptado'                 => _blueLight,
        'confirmado'               => _violet,
        'en_progreso' || 'completado' => _green,
        'cancelado'                => _rose,
        _                          => _textMuted,
      };

  Color _dimEstado(String estado) => switch (estado) {
        'pendiente' || 'en_camino' => _amberDim,
        'aceptado'                 => _blueDim,
        'confirmado'               => _violetDim,
        'en_progreso' || 'completado' => _greenDim,
        'cancelado'                => _roseDim,
        _                          => _surface,
      };

  Color _borderEstado(String estado) => switch (estado) {
        'pendiente' || 'en_camino' => _amberBorder,
        'aceptado'                 => _blueBorder,
        'confirmado'               => _violetBorder,
        'en_progreso' || 'completado' => _greenBorder,
        'cancelado'                => _roseBorder,
        _                          => _border,
      };

  IconData _iconoEstado(String estado) => switch (estado) {
        'pendiente'   => Icons.schedule_rounded,
        'aceptado'    => Icons.engineering_rounded,
        'confirmado'  => Icons.verified_rounded,
        'en_camino'   => Icons.near_me_rounded,
        'en_progreso' => Icons.handyman_rounded,
        'completado'  => Icons.check_circle_rounded,
        'cancelado'   => Icons.cancel_rounded,
        _             => Icons.info_rounded,
      };

  String _labelEstado(String estado) => switch (estado) {
        'pendiente'   => 'Esperando técnico',
        'aceptado'    => 'Técnico asignado',
        'confirmado'  => 'Confirmado',
        'en_camino'   => 'Técnico en camino',
        'en_progreso' => 'En progreso',
        'completado'  => 'Completado',
        'cancelado'   => 'Cancelado',
        _             => estado,
      };

  void _abrirChat() {
    final rol = context.read<AuthProvider>().rol ?? '';
    final nombre = rol == 'cliente'
        ? (_pedido?['tecnico_nombre'] ?? 'Técnico')
        : (_pedido?['cliente_nombre'] ?? 'Cliente');
    context.push('/chat/${widget.pedidoId}/$nombre');
  }

  void _pedirPrecioFinal() {
    final ctrl = TextEditingController();
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
            Center(child: _SheetHandle()),
            const SizedBox(height: 20),
            Text('Precio final', style: _tx(20, FontWeight.w500, _textPri, ls: -0.4)),
            const SizedBox(height: 4),
            Text('Ingresa el monto total cobrado.',
                style: _tx(13, FontWeight.w400, _textDim)),
            const SizedBox(height: 18),
            Container(
              height: 52,
              decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Text('S/ ', style: _tx(16, FontWeight.w500, _blueLight)),
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    style: _tx(16, FontWeight.w400, _textPri),
                    cursorColor: _blueLight,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: '0.00',
                      hintStyle: _tx(16, FontWeight.w400, _textDim),
                      isDense: true,
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            _DarkActionButton(
              label: 'Confirmar completado',
              icon: Icons.check_rounded,
              color: _blue,
              onTap: () {
                final precio = double.tryParse(ctrl.text);
                Navigator.pop(context);
                _accion('completar', precioFinal: precio);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rol = context.read<AuthProvider>().rol ?? '';

    if (_cargando) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
            child: CircularProgressIndicator(
                color: _blueLight, strokeWidth: 2)),
    );
    }

    if (_pedido == null) {
      return Scaffold(
        backgroundColor: _bg,
        body: Center(
            child: Text('Pedido no encontrado',
                style: _tx(15, FontWeight.w400, _textMuted))),
      );
    }

    final estado = _pedido!['estado'] as String? ?? '';
    final mostrarMapa = estado == 'en_camino' &&
        (_posicionTecnico != null || _posicionCliente != null);
    final centroMapa = _posicionTecnico ??
        _posicionCliente ??
        const LatLng(-6.7714, -79.8409);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(estado),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Estado ─────────────────────────────────────────────
                  _DarkCard(
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                            color: _dimEstado(estado),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                                color: _borderEstado(estado))),
                        child: Icon(_iconoEstado(estado),
                            color: _colorEstado(estado), size: 20),
                      ),
                      const SizedBox(width: 13),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Estado actual',
                                style: _tx(11, FontWeight.w400, _textDim,
                                    ls: 0.02)),
                            const SizedBox(height: 3),
                            Text(_labelEstado(estado),
                                style: _tx(15, FontWeight.w500, _textPri,
                                    ls: -0.2)),
                          ])),
                      if (estado == 'en_camino')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                              color: _amberDim,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: _amberBorder)),
                          child: Row(children: [
                            Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(
                                    color: _amber,
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text('En vivo',
                                style: _tx(10, FontWeight.w500, _amber)),
                          ]),
                        ),
                    ]),
                  ),

                  // ── Mapa ───────────────────────────────────────────────
                  if (mostrarMapa) ...[
                    const SizedBox(height: 12),
                    _DarkCard(
                      padding: EdgeInsets.zero,
                      child: Column(children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: SizedBox(
                            height: 210,
                            child: FlutterMap(
                              mapController: _mapCtrl,
                              options: MapOptions(
                                  initialCenter: centroMapa,
                                  initialZoom: 15),
                              children: [
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'pe.tuki.app',
                                ),
                                MarkerLayer(markers: [
                                  if (_posicionTecnico != null)
                                    Marker(
                                      point: _posicionTecnico!,
                                      width: 44, height: 44,
                                      child: _MapPin(
                                          color: _textPri,
                                          icon: Icons.build_rounded),
                                    ),
                                  if (_posicionCliente != null)
                                    Marker(
                                      point: _posicionCliente!,
                                      width: 44, height: 44,
                                      child: _MapPin(
                                          color: _blue,
                                          icon: Icons.home_rounded),
                                    ),
                                ]),
                              ],
                            ),
                          ),
                        ),
                        if (_posicionTecnico != null &&
                            _posicionCliente != null)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(
                                  color: _amberDim,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: _amberBorder)),
                              child: Row(children: [
                                const Icon(Icons.route_rounded,
                                    size: 16, color: _amber),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Técnico a ${UbicacionService.calcularDistancia(
                                      _posicionTecnico!.latitude,
                                      _posicionTecnico!.longitude,
                                      _posicionCliente!.latitude,
                                      _posicionCliente!.longitude,
                                    ).toStringAsFixed(1)} km del cliente',
                                    style: _tx(12, FontWeight.w500,
                                        _amber),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                      ]),
                    ),
                  ],

                  // ── Info pedido ────────────────────────────────────────
                  const SizedBox(height: 12),
                  _DarkCard(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Badge categoría
                          Container(
                            constraints:
                                const BoxConstraints(maxWidth: 240),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                                color: _blueDim,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: _blueBorder)),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.category_rounded,
                                      size: 12, color: _blueLight),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      _pedido!['categoria'] ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      style: _tx(11, FontWeight.w500,
                                          _blueLight),
                                    ),
                                  ),
                                ]),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _pedido!['descripcion'] ?? '',
                            style: _tx(16, FontWeight.w500, _textPri,
                                ls: -0.3, h: 1.4),
                          ),
                          const SizedBox(height: 14),
                          _InfoRowDark(
                            icon: Icons.location_on_rounded,
                            texto:
                                '${_pedido!['direccion']}, ${_pedido!['distrito']}',
                          ),
                          if (_pedido!['precio_acordado'] != null) ...[
                            const SizedBox(height: 10),
                            _InfoRowDark(
                              icon: Icons.sell_rounded,
                              texto:
                                  'Precio acordado: S/ ${_pedido!['precio_acordado']}',
                            ),
                          ],
                          if (_pedido!['precio_final'] != null) ...[
                            const SizedBox(height: 10),
                            _InfoRowDark(
                              icon: Icons.payments_rounded,
                              texto:
                                  'Precio final: S/ ${_pedido!['precio_final']}',
                              color: _green,
                            ),
                          ],
                        ]),
                  ),

                  // ── Timeline ───────────────────────────────────────────
                  const SizedBox(height: 12),
                  _TimelineDark(estado: estado, tx: _tx),

                  // ── Acciones ───────────────────────────────────────────
                  const SizedBox(height: 18),
                  if (rol == 'cliente') ...[
                    if (estado == 'aceptado')
                      _DarkActionButton(
                        label: 'Confirmar técnico',
                        icon: Icons.verified_rounded,
                        color: _blue,
                        onTap: () => _accion('confirmar'),
                      ),
                    if (estado == 'completado' &&
                        _pedido!['calificacion'] == null)
                      _DarkActionButton(
                        label: 'Calificar servicio',
                        icon: Icons.star_rounded,
                        color: _amber,
                        onTap: _mostrarCalificacion,
                        textColor: const Color(0xFF1A0F00),
                      ),
                    if (estado == 'pendiente' || estado == 'aceptado')
                      _DarkActionButton(
                        label: 'Cancelar pedido',
                        icon: Icons.close_rounded,
                        color: _rose,
                        onTap: () => _accion('cancelar'),
                      ),
                  ],
                  if (rol == 'tecnico') ...[
                    if (estado == 'confirmado')
                      _DarkActionButton(
                        label: 'Salir en camino',
                        icon: Icons.near_me_rounded,
                        color: _amber,
                        onTap: () => _accion('en_camino'),
                        textColor: const Color(0xFF1A0F00),
                      ),
                    if (estado == 'en_camino')
                      _DarkActionButton(
                        label: 'Confirmar llegada',
                        icon: Icons.location_on_rounded,
                        color: _green,
                        onTap: () => _accion('llegar'),
                        textColor: const Color(0xFF001A0F),
                      ),
                    if (estado == 'en_progreso')
                      _DarkActionButton(
                        label: 'Marcar completado',
                        icon: Icons.check_rounded,
                        color: _blue,
                        onTap: _pedirPrecioFinal,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(String estado) {
    final showChat = estado != 'pendiente' && estado != 'cancelado';
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Row(children: [
       _IconBtn(
  icon: Icons.arrow_back_ios_new_rounded,
  onTap: () {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  },
),
        const SizedBox(width: 12),
        Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pedido',
                  style: _tx(18, FontWeight.w500, _textPri, ls: -0.4)),
              const SizedBox(height: 2),
              Text('#${widget.pedidoId}',
                  style: _tx(12, FontWeight.w400, _textDim),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ])),
        if (showChat)
          _IconBtn(
            icon: Icons.chat_bubble_rounded,
            onTap: _abrirChat,
            accent: _blueLight,
          ),
      ]),
    );
  }

  void _mostrarCalificacion() {
    int estrellas = 5;
    final ctrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161920),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              22, 10, 22, MediaQuery.of(context).viewInsets.bottom + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 20),
              Text('Califica el servicio',
                  style: _tx(20, FontWeight.w500, _textPri, ls: -0.4)),
              const SizedBox(height: 6),
              Text('Tu opinión ayuda a mantener la calidad.',
                  textAlign: TextAlign.center,
                  style: _tx(13, FontWeight.w400, _textDim)),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setModal(() => estrellas = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      i < estrellas
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 38,
                      color: i < estrellas ? _amber : _textDim,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 18),
              Container(
                decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border)),
                child: TextField(
                  controller: ctrl,
                  maxLines: 3,
                  style: _tx(14, FontWeight.w400, _textMid),
                  cursorColor: _blueLight,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Comentario opcional...',
                    hintStyle: _tx(14, FontWeight.w400, _textDim),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _DarkActionButton(
                label: 'Enviar calificación',
                icon: Icons.send_rounded,
                color: _blue,
                onTap: () async {
                  Navigator.pop(ctx);
                  final res = await ApiClient.post(
                    '/pedidos/${widget.pedidoId}/calificar',
                    {
                      'calificacion': estrellas.toDouble(),
                      'comentario': ctrl.text.trim(),
                    },
                    auth: true,
                  );
                  if (mounted && res['id'] != null) {
                    setState(() => _pedido = res);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Calificación enviada',
                          style: _tx(13, FontWeight.w500, _textPri)),
                      backgroundColor: const Color(0xFF1A1D24),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      margin: const EdgeInsets.all(16),
                    ));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _DarkCard({required this.child,
      this.padding = const EdgeInsets.all(15)});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14FFFFFF))),
    child: child,
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;
  const _IconBtn(
      {required this.icon,
      required this.onTap,
      this.accent = const Color(0x99FFFFFF)});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0x14FFFFFF))),
      child: Icon(icon, size: 17, color: accent),
    ),
  );
}

class _InfoRowDark extends StatelessWidget {
  final IconData icon;
  final String texto;
  final Color color;
  const _InfoRowDark(
      {required this.icon,
      required this.texto,
      this.color = const Color(0x61FFFFFF)});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 16, color: color),
    const SizedBox(width: 8),
    Expanded(
      child: Text(texto,
          style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: color,
              height: 1.35)),
    ),
  ]);
}

class _TimelineDark extends StatelessWidget {
  final String estado;
  final TextStyle Function(double, FontWeight, Color,
      {double? ls, double? h}) tx;
  const _TimelineDark({required this.estado, required this.tx});

  static const _pasos = [
    {'key': 'pendiente',   'label': 'Pedido creado',     'icon': Icons.receipt_long_rounded},
    {'key': 'aceptado',    'label': 'Técnico asignado',  'icon': Icons.engineering_rounded},
    {'key': 'confirmado',  'label': 'Confirmado',        'icon': Icons.verified_rounded},
    {'key': 'en_camino',   'label': 'En camino',         'icon': Icons.near_me_rounded},
    {'key': 'en_progreso', 'label': 'En progreso',       'icon': Icons.handyman_rounded},
    {'key': 'completado',  'label': 'Completado',        'icon': Icons.check_rounded},
  ];

  static const _orden = [
    'pendiente', 'aceptado', 'confirmado',
    'en_camino', 'en_progreso', 'completado',
  ];

  @override
  Widget build(BuildContext context) {
    final idxActual = _orden.indexOf(estado);
    return _DarkCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progreso',
              style: tx(14, FontWeight.w500,
                  const Color(0x99FFFFFF), ls: 0)),
          const SizedBox(height: 16),
          ...List.generate(_pasos.length, (i) {
            final completado = idxActual >= 0 && i <= idxActual;
            final activo     = idxActual >= 0 && i == idxActual;
            final icon       = _pasos[i]['icon'] as IconData;
            final isLast     = i == _pasos.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: completado
                          ? const Color(0xFF2563EB)
                          : const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(9),
                      border: activo
                          ? Border.all(
                              color: const Color(0x4060A5FA), width: 2)
                          : null,
                    ),
                    child: Icon(
                      completado ? icon : Icons.circle_rounded,
                      size: completado ? 14 : 7,
                      color: completado
                          ? Colors.white
                          : const Color(0x38FFFFFF),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 1.5,
                      height: 28,
                      color: completado && i < idxActual
                          ? const Color(0x402563EB)
                          : const Color(0x14FFFFFF),
                    ),
                ]),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        top: 4, bottom: isLast ? 0 : 2),
                    child: Text(
                      _pasos[i]['label'] as String,
                      style: tx(
                        13,
                        activo ? FontWeight.w500 : FontWeight.w400,
                        completado
                            ? (activo
                                ? const Color(0xFFFFFFFF)
                                : const Color(0x99FFFFFF))
                            : const Color(0x38FFFFFF),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _DarkActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  const _DarkActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor)),
          ],
        ),
      ),
    ),
  );
}

class _MapPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _MapPin({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: const Color(0xFF0D0F14), width: 2.5),
    ),
    child: Icon(icon, color: Colors.white, size: 18),
  );
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) => Container(
    width: 40, height: 4,
    decoration: BoxDecoration(
        color: const Color(0x28FFFFFF),
        borderRadius: BorderRadius.circular(999)),
  );
}