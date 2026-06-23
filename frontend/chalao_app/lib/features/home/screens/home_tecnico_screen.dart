import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';
import '../../../core/api_client.dart';
import '../widgets/bottom_nav.dart';
import '../../../core/ubicacion_service.dart';

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
const _violet    = Color(0xFFA78BFA);
const _violetDim = Color(0x14A78BFA);
const _violetBorder = Color(0x28A78BFA);
const _textPri   = Color(0xFFFFFFFF);
const _textMid   = Color(0x99FFFFFF);
const _textMuted = Color(0x61FFFFFF);
const _textDim   = Color(0x38FFFFFF);

class HomeTecnicoScreen extends StatefulWidget {
  const HomeTecnicoScreen({super.key});
  @override
  State<HomeTecnicoScreen> createState() => _HomeTecnicoScreenState();
}

class _HomeTecnicoScreenState extends State<HomeTecnicoScreen> {
  int  _tab        = 0;
  bool _disponible = true;
  bool _cargando   = false;
  List<dynamic> _misPedidos   = [];
  List<dynamic> _disponibles  = [];
  Map<String, dynamic>? _perfil;

  TextStyle _tx(double s, FontWeight w, Color c, {double? ls, double? h}) =>
      GoogleFonts.inter(fontSize: s, fontWeight: w, color: c,
          letterSpacing: ls ?? 0, height: h);

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
    _cargarPerfil();
    _cargarDisponibles();
  }

  Future<void> _cargarPedidos() async {
    setState(() => _cargando = true);
    try {
      final res = await ApiClient.get('/pedidos/mis-pedidos', auth: true);
      if (mounted) setState(() => _misPedidos = res is List ? res : []);
    } catch (e) { debugPrint('Error pedidos: $e'); }
    finally { if (mounted) setState(() => _cargando = false); }
  }

  Future<void> _cargarPerfil() async {
    try {
      final res = await ApiClient.get('/perfil/tecnico', auth: true);
      if (mounted) setState(() => _perfil = res);
    } catch (e) { debugPrint('Error perfil: $e'); }
  }

  Future<void> _cargarDisponibles() async {
    try {
      final res = await ApiClient.get('/pedidos/disponibles', auth: true);
      if (mounted) setState(() =>
        _disponibles = res is List ? res : []);
    } catch (e) { debugPrint('Error disponibles: $e'); }
  }

  bool get _tieneEspecialidades {
    final esp = _perfil?['especialidades'] as List?;
    return esp != null && esp.isNotEmpty;
  }

  List<String> get _especialidades =>
      (_perfil?['especialidades'] as List?)
          ?.map((e) => e.toString()).toList() ?? [];

  Color _colorEstado(String e) => switch (e) {
    'aceptado'    => _blueLight,
    'confirmado'  => _violet,
    'en_camino'   => _amber,
    'en_progreso' => _green,
    _             => _textMuted,
  };

  Color _dimEstado(String e) => switch (e) {
    'aceptado'    => _blueDim,
    'confirmado'  => _violetDim,
    'en_camino'   => _amberDim,
    'en_progreso' => _greenDim,
    _             => _surface,
  };

  Color _borderEstado(String e) => switch (e) {
    'aceptado'    => _blueBorder,
    'confirmado'  => _violetBorder,
    'en_camino'   => _amberBorder,
    'en_progreso' => _greenBorder,
    _             => _border,
  };

  String _labelEstado(String e) => switch (e) {
    'aceptado'    => 'Aceptado',
    'confirmado'  => 'Confirmado',
    'en_camino'   => 'En camino',
    'en_progreso' => 'En progreso',
    _             => e,
  };

  Future<void> _toggleDisponible() async {
    final nueva = !_disponible;
    setState(() => _disponible = nueva);
    final uid = context.read<AuthProvider>().usuarioId;
    if (uid == null) return;
    if (nueva) {
      final pos = await UbicacionService.obtenerUbicacion();
      if (pos != null) {
        await UbicacionService.actualizarPosicionTecnico(
          tecnicoId: uid,
          lat: pos.latitude, lng: pos.longitude,
          disponible: true);
      }
    } else {
      await UbicacionService.actualizarPosicionTecnico(
        tecnicoId: uid, lat: 0, lng: 0, disponible: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final nombre = auth.usuario?['nombre']?.toString().split(' ').first ?? 'Técnico';
    final partes = (auth.usuario?['nombre'] ?? '').toString().trim().split(' ');
    final iniciales = partes.length >= 2
        ? '${partes[0][0]}${partes[1][0]}'.toUpperCase()
        : nombre.isNotEmpty ? nombre[0].toUpperCase() : 'T';

    final pedidosActivos = _misPedidos
        .where((p) => !['completado', 'cancelado', 'pendiente']
            .contains(p['estado']))
        .toList();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(nombre, iniciales, auth),
          Expanded(
            child: RefreshIndicator(
              color: _blueLight,
              backgroundColor: const Color(0xFF1A1D24),
              onRefresh: () async {
                await _cargarPedidos();
                await _cargarPerfil();
                await _cargarDisponibles();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // ── Stats ──────────────────────────────────────────
                    Row(children: [
                      _StatCard(
                        label: 'Ganancias',
                        valor: 'S/ 0',
                        icon: Icons.account_balance_wallet_outlined,
                        color: _amber, dim: _amberDim,
                        borderColor: _amberBorder,
                        tx: _tx),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: 'Rating',
                        valor: _perfil?['calificacion'] != null
                            ? _perfil!['calificacion'].toString() : '—',
                        icon: Icons.star_outline_rounded,
                        color: _amber, dim: _amberDim,
                        borderColor: _amberBorder,
                        tx: _tx),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: 'Trabajos',
                        valor: _perfil?['trabajos_completados']
                                ?.toString() ?? '0',
                        icon: Icons.check_circle_outline_rounded,
                        color: _green, dim: _greenDim,
                        borderColor: _greenBorder,
                        tx: _tx),
                    ]),

                    const SizedBox(height: 24),

                    // ── Pedidos disponibles ────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionHeader(
                          title: 'Pedidos disponibles',
                          subtitle: 'En tu zona sin técnico asignado',
                          tx: _tx),
                        GestureDetector(
                          onTap: _cargarDisponibles,
                          child: Row(mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.refresh_rounded,
                                size: 13, color: _blueLight),
                              const SizedBox(width: 4),
                              Text('Actualizar',
                                style: _tx(11, FontWeight.w400, _blueLight)),
                            ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (!_disponible)
                      _BannerInactivo(tx: _tx)
                    else if (_disponibles.isEmpty)
                      _EmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'Sin pedidos disponibles',
                        subtitle: 'Cuando lleguen aparecerán aquí',
                        tx: _tx)
                    else
                      Column(
                        children: _disponibles.take(3).map((p) =>
                          GestureDetector(
                            onTap: () => context.go('/pedido/${p['id']}'),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(13),
                              decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _amberBorder)),
                              child: Row(children: [
                                Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(
                                    color: _amberDim,
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(color: _amberBorder)),
                                  child: const Icon(
                                    Icons.notifications_active_rounded,
                                    size: 18, color: _amber)),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p['categoria'] ?? '',
                                      style: _tx(13, FontWeight.w500, _textMid)),
                                    const SizedBox(height: 2),
                                    Text('${p['distrito']} · ${p['descripcion'] ?? ''}',
                                      style: _tx(11, FontWeight.w400, _textDim),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  ],
                                )),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _amberDim,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: _amberBorder)),
                                  child: Text('Ver',
                                    style: _tx(10, FontWeight.w500, _amber))),
                              ]),
                            ),
                          )
                        ).toList(),
                      ),

                    const SizedBox(height: 24),

                    // ── Trabajos activos ───────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionHeader(title: 'Trabajos activos', tx: _tx),
                        GestureDetector(
                          onTap: _cargarPedidos,
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            _cargando
                              ? const SizedBox(
                                  width: 11, height: 11,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.8, color: _blueLight))
                              : const Icon(Icons.refresh_rounded,
                                  size: 13, color: _blueLight),
                            const SizedBox(width: 5),
                            Text('Actualizar',
                              style: _tx(11, FontWeight.w400, _blueLight)),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    pedidosActivos.isEmpty
                      ? _EmptyState(
                          icon: Icons.work_outline_rounded,
                          title: 'Sin trabajos activos',
                          subtitle: 'Los pedidos aceptados aparecen aquí',
                          tx: _tx)
                      : Column(
                          children: pedidosActivos.map((p) {
                            final estado = p['estado'] as String? ?? '';
                            return GestureDetector(
                              onTap: () => context.go('/pedido/${p['id']}'),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(13),
                                decoration: BoxDecoration(
                                  color: _surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _border)),
                                child: Row(children: [
                                  Container(
                                    width: 42, height: 42,
                                    decoration: BoxDecoration(
                                      color: _blueDim,
                                      borderRadius: BorderRadius.circular(11)),
                                    child: const Icon(Icons.build_outlined,
                                      size: 18, color: _blueLight)),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p['categoria'] ?? '',
                                        style: _tx(13, FontWeight.w500, _textMid)),
                                      const SizedBox(height: 2),
                                      Text(p['distrito'] ?? '',
                                        style: _tx(11, FontWeight.w400, _textDim)),
                                    ],
                                  )),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _dimEstado(estado),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: _borderEstado(estado))),
                                    child: Text(_labelEstado(estado),
                                      style: _tx(10, FontWeight.w500,
                                        _colorEstado(estado)))),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded,
                                    size: 14, color: _textDim),
                                ]),
                              ),
                            );
                          }).toList(),
                        ),

                    const SizedBox(height: 24),

                    // ── Reputación ─────────────────────────────────────
                    _SectionHeader(title: 'Tu reputación', tx: _tx),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => context.go('/perfil'),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _border)),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: _amberDim,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _amberBorder)),
                            child: const Icon(Icons.star_outline_rounded,
                              size: 20, color: _amber)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _perfil?['calificacion'] != null &&
                                  (_perfil!['calificacion'] as num) > 0
                                  ? '${_perfil!['calificacion']} ★'
                                  : 'Sin reseñas aún',
                                style: _tx(13, FontWeight.w500, _textMid)),
                              const SizedBox(height: 2),
                              Text(
                                '${_perfil?['trabajos_completados'] ?? 0} trabajos completados',
                                style: _tx(11, FontWeight.w400, _textDim)),
                            ],
                          )),
                          const Icon(Icons.arrow_forward_rounded,
                            size: 14, color: _textDim),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── CTA perfil ─────────────────────────────────────
                    if (!_tieneEspecialidades)
                      GestureDetector(
                        onTap: () => context.go('/completar-perfil'),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _blueBorder)),
                          child: Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: _blueDim,
                                borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.person_outline_rounded,
                                size: 20, color: _blueLight)),
                            const SizedBox(width: 13),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Completa tu perfil',
                                  style: _tx(13, FontWeight.w500, _textPri)),
                                const SizedBox(height: 2),
                                Text('Agrega especialidades para recibir pedidos',
                                  style: _tx(11, FontWeight.w400, _textDim)),
                              ],
                            )),
                            const Icon(Icons.arrow_forward_rounded,
                              size: 15, color: _blueLight),
                          ]),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => context.go('/perfil'),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: _greenDim,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _greenBorder)),
                          child: Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: _green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.verified_rounded,
                                size: 20, color: _green)),
                            const SizedBox(width: 13),
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Perfil verificado',
                                  style: _tx(13, FontWeight.w500, _textPri)),
                                const SizedBox(height: 2),
                                Text(_especialidades.join(', '),
                                  style: _tx(11, FontWeight.w400, _textDim),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              ],
                            )),
                            const Icon(Icons.edit_outlined,
                              size: 14, color: _green),
                          ]),
                        ),
                      ),

                    const SizedBox(height: 30),
                    Center(child: Text('Tuki · Hecho en Lambayeque',
                        style: _tx(11, FontWeight.w400, _textDim))),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: TukiBottomNav(
        index: _tab,
        onTap: (i) {
          setState(() => _tab = i);
          if (i == 1) context.go('/trabajos');
          if (i == 2) context.go('/ganancias');
          if (i == 3) context.go('/perfil');
        },
        rol: 'tecnico',
      ),
    );
  }

  Widget _buildHeader(String nombre, String iniciales, AuthProvider auth) =>
      Container(
        color: _bg,
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: _blue,
              borderRadius: BorderRadius.circular(11)),
            child: Center(child: Text(iniciales,
                style: _tx(13, FontWeight.w500, Colors.white))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hola, $nombre',
                style: _tx(18, FontWeight.w500, _textPri, ls: -0.4)),
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.build_outlined, size: 11, color: _textDim),
                const SizedBox(width: 4),
                Text('Panel de técnico',
                  style: _tx(11, FontWeight.w400, _textDim)),
              ]),
            ],
          )),
          GestureDetector(
            onTap: _toggleDisponible,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: _disponible ? _greenDim : _surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: _disponible ? _greenBorder : _border)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _disponible ? _green : _textDim)),
                const SizedBox(width: 5),
                Text(_disponible ? 'Disponible' : 'Inactivo',
                  style: _tx(10, FontWeight.w500,
                    _disponible ? _green : _textMuted)),
              ]),
            ),
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: Icons.logout_rounded,
            onTap: () async {
              await auth.cerrarSesion();
              if (mounted) context.go('/login');
            },
          ),
        ]),
      );
}

class _StatCard extends StatelessWidget {
  final String label, valor;
  final IconData icon;
  final Color color, dim, borderColor;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;

  const _StatCard({required this.label, required this.valor,
    required this.icon, required this.color, required this.dim,
    required this.borderColor, required this.tx});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14FFFFFF))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: dim,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: borderColor)),
          child: Icon(icon, size: 15, color: color)),
        const SizedBox(height: 10),
        Text(valor, style: tx(18, FontWeight.w500,
            const Color(0xFFFFFFFF), ls: -0.5)),
        const SizedBox(height: 1),
        Text(label, style: tx(10, FontWeight.w400,
            const Color(0x38FFFFFF)),
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _SectionHeader({required this.title, this.subtitle, required this.tx});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: tx(14, FontWeight.w500, const Color(0x99FFFFFF))),
      if (subtitle != null) ...[
        const SizedBox(height: 2),
        Text(subtitle!, style: tx(11, FontWeight.w400, const Color(0x38FFFFFF))),
      ],
    ],
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _EmptyState({required this.icon, required this.title,
    required this.subtitle, required this.tx});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 22),
    decoration: BoxDecoration(
      color: const Color(0x0AFFFFFF),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x14FFFFFF))),
    child: Column(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x14FFFFFF))),
        child: Icon(icon, size: 20, color: const Color(0x38FFFFFF))),
      const SizedBox(height: 10),
      Text(title, style: tx(13, FontWeight.w500, const Color(0x99FFFFFF))),
      const SizedBox(height: 3),
      Text(subtitle, style: tx(11, FontWeight.w400, const Color(0x38FFFFFF)),
        textAlign: TextAlign.center),
    ]),
  );
}

class _BannerInactivo extends StatelessWidget {
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _BannerInactivo({required this.tx});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0x14F43F5E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x28F43F5E))),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: const Color(0x14F43F5E),
          borderRadius: BorderRadius.circular(11)),
        child: const Icon(Icons.wifi_off_rounded,
          size: 18, color: Color(0xFFF43F5E))),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estás inactivo',
            style: tx(13, FontWeight.w500, const Color(0xFFF43F5E))),
          const SizedBox(height: 2),
          Text('Activa tu disponibilidad para recibir pedidos',
            style: tx(11, FontWeight.w400, const Color(0x99F43F5E))),
        ],
      )),
    ]),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x14FFFFFF))),
      child: Icon(icon, size: 16, color: const Color(0x61FFFFFF)),
    ),
  );
}