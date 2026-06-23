import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/auth_provider.dart';
import '../../../core/api_client.dart';
import '../widgets/bottom_nav.dart';

const _bg        = Color(0xFF0D0F14);
const _surface   = Color(0x0AFFFFFF);
const _border    = Color(0x14FFFFFF);
const _blue      = Color(0xFF2563EB);
const _blueLight = Color(0xFF60A5FA);
const _green     = Color(0xFF34D399);
const _amber     = Color(0xFFFBBF24);
const _textPri   = Color(0xFFFFFFFF);
const _textMid   = Color(0x99FFFFFF);
const _textMuted = Color(0x61FFFFFF);
const _textDim   = Color(0x38FFFFFF);

class HomeClienteScreen extends StatefulWidget {
  const HomeClienteScreen({super.key});
  @override
  State<HomeClienteScreen> createState() => _HomeClienteScreenState();
}

class _HomeClienteScreenState extends State<HomeClienteScreen> {
  int _tab = 0;
  List<dynamic> _misPedidos = [];
  List<Map<String, dynamic>> _tecnicosReales = [];

  static const _categorias = [
    {'icon': Icons.water_drop_outlined,        'label': 'Gasfitería'},
    {'icon': Icons.bolt_outlined,              'label': 'Electricidad'},
    {'icon': Icons.format_paint_outlined,      'label': 'Pintura'},
    {'icon': Icons.phone_android_outlined,     'label': 'Celulares'},
    {'icon': Icons.ac_unit_outlined,           'label': 'Refrigeración'},
    {'icon': Icons.carpenter_outlined,         'label': 'Carpintería'},
    {'icon': Icons.lock_outline_rounded,       'label': 'Cerrajería'},
    {'icon': Icons.cleaning_services_outlined, 'label': 'Limpieza'},
  ];

  TextStyle _tx(double s, FontWeight w, Color c, {double? ls, double? h}) =>
      GoogleFonts.inter(fontSize: s, fontWeight: w, color: c,
          letterSpacing: ls ?? 0, height: h);

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
    _cargarTecnicos();
  }

  Future<void> _cargarTecnicos() async {
    try {
      final data = await Supabase.instance.client
        .from('ubicaciones_tecnicos')
        .select()
        .eq('disponible', true)
        .limit(5);
      if (mounted) setState(() =>
        _tecnicosReales = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Error cargando técnicos: $e');
    }
  }

  Future<void> _cargarPedidos() async {
    try {
      final res = await ApiClient.get('/pedidos/mis-pedidos', auth: true);
      if (mounted) setState(() => _misPedidos = res is List ? res : []);
    } catch (e) {
      debugPrint('Error cargando pedidos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth   = context.watch<AuthProvider>();
    final nombre = auth.usuario?['nombre']?.toString().split(' ').first ?? '';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(nombre),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCta(),
                  _buildPromo(),
                  _buildCategorias(),
                  _buildPedidos(),
                  _buildTecnicos(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: TukiBottomNav(
        index: _tab,
        onTap: (i) {
          setState(() => _tab = i);
           if (i == 1) context.go('/buscar');
    if (i == 2) context.go('/mis-pedidos');
    if (i == 3) context.go('/perfil');
        },
        rol: 'cliente',
      ),
    );
  }

  Widget _buildHeader(String nombre) {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hola, $nombre',
                style: _tx(22, FontWeight.w500, _textPri, ls: -0.4)),
              const SizedBox(height: 3),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                  size: 13, color: _blueLight),
                const SizedBox(width: 3),
                Text('Chiclayo, Lambayeque',
                  style: _tx(12, FontWeight.w400, _textDim)),
              ]),
            ]),
            Row(children: [
              _IconBtn(icon: Icons.notifications_outlined, onTap: () {}),
              const SizedBox(width: 8),
              _IconBtn(
                icon: Icons.logout_rounded,
                onTap: () async {
                  await context.read<AuthProvider>().cerrarSesion();
                  if (context.mounted) context.go('/login');
                },
              ),
              const SizedBox(width: 8),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : 'T',
                    style: _tx(14, FontWeight.w500, Colors.white)),
                ),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _border)),
          child: Row(children: [
            const SizedBox(width: 18),
            const Icon(Icons.search_rounded, size: 18, color: _textDim),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
  style: _tx(14, FontWeight.w400, _textPri),
  cursorColor: _blueLight,
  readOnly: true,
  onTap: () => context.go('/buscar'),
  decoration: InputDecoration(
    border: InputBorder.none,
    isDense: true,
    hintText: 'Busca un servicio o técnico...',
    hintStyle: _tx(14, FontWeight.w400, _textDim)),
),
            ),
            Container(
              margin: const EdgeInsets.only(right: 6),
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(999)),
              child: const Icon(Icons.tune_rounded,
                size: 16, color: Colors.white),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildCta() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 0),
      child: GestureDetector(
        onTap: () => context.go('/crear-pedido'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _border)),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.add_rounded,
                color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Solicitar un servicio',
                  style: _tx(14, FontWeight.w500, _textPri)),
                const SizedBox(height: 2),
                Text('Gasfitería, electricidad, pintura...',
                  style: _tx(12, FontWeight.w400, _textDim)),
              ],
            )),
            const Icon(Icons.arrow_forward_rounded,
              size: 18, color: _blueLight),
          ]),
        ),
      ),
    );
  }

  Widget _buildPromo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _blue.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _blue.withValues(alpha: 0.25))),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(6)),
                child: Text('PRIMER SERVICIO',
                  style: _tx(9, FontWeight.w500, Colors.white, ls: 0.06)),
              ),
              const SizedBox(height: 7),
              Text('20% off',
                style: _tx(28, FontWeight.w500, _textPri, ls: -0.5)),
              const SizedBox(height: 2),
              Text('Usa el código TUKI20',
                style: _tx(12, FontWeight.w400, _textMuted)),
            ],
          )),
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.local_offer_outlined,
              size: 24, color: _blueLight),
          ),
        ]),
      ),
    );
  }

  Widget _buildCategorias() {
    return _Section(
      title: 'Categorías',
      action: 'Ver todo',
      onAction: () {},
      child: SizedBox(
        height: 82,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          itemCount: _categorias.length,
          itemBuilder: (_, i) {
            final cat = _categorias[i];
            return GestureDetector(
              onTap: () => context.go('/crear-pedido'),
              child: Container(
                width: 66,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(cat['icon'] as IconData,
                      size: 20, color: _textDim),
                    const SizedBox(height: 7),
                    Text(cat['label'] as String,
                      style: _tx(9, FontWeight.w400, _textDim),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPedidos() {
    final activos = _misPedidos.where((p) {
      final estado = p['estado'] as String? ?? '';
      if (estado == 'cancelado') return false;
      if (estado == 'completado' && p['calificacion'] != null) return false;
      return true;
    }).take(3).toList();

    return _Section(
      title: 'Pedidos activos',
      action: 'Actualizar',
      onAction: _cargarPedidos,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: activos.isEmpty
          ? Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border)),
              child: Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: _border)),
                  child: const Icon(Icons.receipt_long_outlined,
                    size: 18, color: _textDim),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sin pedidos activos',
                      style: _tx(13, FontWeight.w500, _textMuted)),
                    const SizedBox(height: 2),
                    Text('Solicita un servicio arriba',
                      style: _tx(12, FontWeight.w400, _textDim)),
                  ]),
              ]),
            )
          : Column(
              children: activos.map((p) {
                final estado = p['estado'] as String? ?? '';
                final isAceptado = estado == 'aceptado';
                return GestureDetector(
                  onTap: () => context.go('/pedido/${p['id']}'),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border)),
                    child: Row(children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: _blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11)),
                        child: const Icon(Icons.build_outlined,
                          size: 18, color: _blueLight),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['categoria'] ?? '',
                            style: _tx(13, FontWeight.w500, _textMid)),
                          const SizedBox(height: 2),
                          Text(p['distrito'] ?? '',
                            style: _tx(12, FontWeight.w400, _textDim)),
                        ],
                      )),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAceptado
                            ? _blue.withValues(alpha: 0.10)
                            : _amber.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isAceptado
                              ? _blue.withValues(alpha: 0.20)
                              : _amber.withValues(alpha: 0.20))),
                        child: Text(
                          switch (estado) {
                            'pendiente'   => 'Pendiente',
                            'aceptado'    => 'Técnico asignado',
                            'confirmado'  => 'Confirmado',
                            'en_camino'   => 'En camino',
                            'en_progreso' => 'En progreso',
                            _             => estado,
                          },
                          style: _tx(10, FontWeight.w500,
                            isAceptado ? _blueLight : _amber)),
                      ),
                    ]),
                  ),
                );
              }).toList(),
            ),
      ),
    );
  }

  Widget _buildTecnicos() {
    return _Section(
      title: 'Técnicos cerca de ti',
      action: 'Ver mapa',
      onAction: () => context.go('/mapa'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: _tecnicosReales.isEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border)),
              child: Row(children: [
                const Icon(Icons.location_off_outlined,
                  size: 18, color: _textDim),
                const SizedBox(width: 12),
                Text('Sin técnicos disponibles ahora',
                  style: _tx(13, FontWeight.w400, _textDim)),
              ]),
            )
          : Column(
              children: _tecnicosReales.map((t) {
                final tecnicoId = t['tecnico_id'] as String? ?? '';
                return FutureBuilder(
                  future: ApiClient.get(
                    '/perfil/tecnico-publico/$tecnicoId', auth: false),
                  builder: (_, snap) {
                    final nombre = snap.data?['nombre'] ?? 'Técnico';
                    final especialidades = (snap.data?['especialidades']
                      as List?)?.join(', ') ?? '';
                    final inicial = nombre.isNotEmpty
                      ? nombre[0].toUpperCase() : 'T';
                    return GestureDetector(
                      onTap: () => context.go('/mapa'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _border)),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: _blue.withValues(alpha: 0.12),
                              shape: BoxShape.circle),
                            child: Center(child: Text(inicial,
                              style: _tx(14, FontWeight.w600, _blueLight))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Flexible(
                                  child: Text(nombre,
                                    style: _tx(13, FontWeight.w500, _textMid),
                                    overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _green.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: _green.withValues(alpha: 0.20))),
                                  child: Row(mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded,
                                        size: 9, color: _green),
                                      const SizedBox(width: 2),
                                      Text('Verificado',
                                        style: _tx(8, FontWeight.w400, _green)),
                                    ]),
                                ),
                              ]),
                              const SizedBox(height: 2),
                              Text(
                                especialidades.isEmpty
                                  ? 'Técnico disponible'
                                  : especialidades,
                                style: _tx(12, FontWeight.w400, _textDim),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            ],
                          )),
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: _border)),
                            child: const Icon(Icons.arrow_forward_rounded,
                              size: 15, color: _textDim),
                          ),
                        ]),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title, action;
  final VoidCallback onAction;
  final Widget child;
  const _Section({required this.title, required this.action,
      required this.onAction, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
              style: GoogleFonts.inter(
                fontSize: 15, fontWeight: FontWeight.w500,
                color: const Color(0x99FFFFFF))),
            GestureDetector(
              onTap: onAction,
              child: Text(action,
                style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w400,
                  color: const Color(0xFF60A5FA))),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      child,
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
      child: Icon(icon, size: 17, color: const Color(0x99FFFFFF)),
    ),
  );
}