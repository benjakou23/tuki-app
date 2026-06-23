import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api_client.dart';
import '../../home/widgets/bottom_nav.dart';

const _bg        = Color(0xFF0D0F14);
const _surface   = Color(0x0AFFFFFF);
const _surfaceHi = Color(0x14FFFFFF);
const _border    = Color(0x14FFFFFF);
const _blue      = Color(0xFF2563EB);
const _blueLight = Color(0xFF60A5FA);
const _blueDim   = Color(0x1A2563EB);
const _blueBorder = Color(0x332563EB);
const _green     = Color(0xFF34D399);
const _greenDim  = Color(0x1434D399);
const _greenBorder = Color(0x2834D399);
const _amber     = Color(0xFFFBBF24);
const _textPri   = Color(0xFFFFFFFF);
const _textMid   = Color(0x99FFFFFF);
const _textDim   = Color(0x38FFFFFF);

const _distritos = [
  'Todos', 'Chiclayo', 'José Leonardo Ortiz', 'La Victoria',
  'Lambayeque', 'Ferreñafe', 'Monsefú', 'Reque', 'Tumán',
  'Pomalca', 'Pucalá', 'Cayaltí', 'Pátapo',
];

const _especialidades = [
  'Todas', 'Gasfitería', 'Electricidad', 'Pintura', 'Celulares',
  'Refrigeración', 'Carpintería', 'Cerrajería', 'Limpieza',
  'Albañilería', 'Jardinería', 'Fumigación',
];

class BuscarScreen extends StatefulWidget {
  const BuscarScreen({super.key});
  @override
  State<BuscarScreen> createState() => _BuscarScreenState();
}

class _BuscarScreenState extends State<BuscarScreen> {
  final _searchCtrl = TextEditingController();
  final _focusNode  = FocusNode();
  Timer? _debounce;

  List<dynamic> _resultados = [];
  bool _cargando = false;
  bool _buscado  = false;

  String _distritoSel    = 'Todos';
  String _especialidadSel = 'Todas';

  TextStyle _tx(double s, FontWeight w, Color c, {double? ls, double? h}) =>
      GoogleFonts.inter(fontSize: s, fontWeight: w, color: c,
          letterSpacing: ls ?? 0, height: h);

  @override
  void initState() {
    super.initState();
    _buscar(); // cargar todos al inicio
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() => _cargando = true);
    try {
      final params = <String, String>{};
      final q = _searchCtrl.text.trim();
      if (q.isNotEmpty) params['q'] = q;
      if (_especialidadSel != 'Todas') params['especialidad'] = _especialidadSel;
      if (_distritoSel != 'Todos') params['distrito'] = _distritoSel;

      final uri = Uri.parse('${ApiClient.baseUrl}/tecnicos/buscar')
          .replace(queryParameters: params.isEmpty ? null : params);

      final res = await ApiClient.getUri(uri.toString(), auth: true);
      if (mounted) setState(() {
        _resultados = res is List ? res : [];
        _cargando = false;
        _buscado = true;
      });
    } catch (e) {
      if (mounted) setState(() { _cargando = false; _buscado = true; });
    }
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _buscar);
  }

  void _setDistrito(String d) {
    setState(() => _distritoSel = d);
    _buscar();
  }

  void _setEspecialidad(String e) {
    setState(() => _especialidadSel = e);
    _buscar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          // Header + buscador
          Container(
            color: _bg,
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 12),
            child: Column(children: [
              Row(children: [
                Expanded(child: Text('Buscar técnicos',
                  style: _tx(20, FontWeight.w500, _textPri, ls: -0.4))),
              ]),
              const SizedBox(height: 14),
              // Barra búsqueda
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border)),
                child: Row(children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search_rounded, size: 18, color: _textDim),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _focusNode,
                      style: _tx(14, FontWeight.w400, _textPri),
                      cursorColor: _blueLight,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'Nombre o especialidad...',
                        hintStyle: _tx(14, FontWeight.w400, _textDim)),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        _buscar();
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.close_rounded,
                          size: 16, color: _textDim)),
                    ),
                ]),
              ),
            ]),
          ),

          // Filtros
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              children: [
                // Filtro especialidad
                _FiltroChip(
                  label: _especialidadSel == 'Todas'
                    ? 'Especialidad' : _especialidadSel,
                  activo: _especialidadSel != 'Todas',
                  icon: Icons.build_outlined,
                  onTap: () => _mostrarFiltroSheet(
                    titulo: 'Especialidad',
                    opciones: _especialidades,
                    seleccionado: _especialidadSel,
                    onSelect: _setEspecialidad),
                  tx: _tx),
                const SizedBox(width: 8),
                // Filtro distrito
                _FiltroChip(
                  label: _distritoSel == 'Todos'
                    ? 'Distrito' : _distritoSel,
                  activo: _distritoSel != 'Todos',
                  icon: Icons.location_on_outlined,
                  onTap: () => _mostrarFiltroSheet(
                    titulo: 'Distrito',
                    opciones: _distritos,
                    seleccionado: _distritoSel,
                    onSelect: _setDistrito),
                  tx: _tx),
                const SizedBox(width: 8),
                // Reset filtros
                if (_especialidadSel != 'Todas' || _distritoSel != 'Todos')
                  _FiltroChip(
                    label: 'Limpiar',
                    activo: false,
                    icon: Icons.refresh_rounded,
                    onTap: () {
                      setState(() {
                        _especialidadSel = 'Todas';
                        _distritoSel = 'Todos';
                        _searchCtrl.clear();
                      });
                      _buscar();
                    },
                    tx: _tx),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Resultados
          Expanded(
            child: _cargando
              ? const Center(child: CircularProgressIndicator(
                  color: _blueLight, strokeWidth: 2))
              : !_buscado || _resultados.isEmpty
                ? Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _border)),
                        child: const Icon(Icons.search_off_rounded,
                          size: 24, color: _textDim)),
                      const SizedBox(height: 14),
                      Text(
                        _buscado ? 'Sin resultados' : 'Busca un técnico',
                        style: _tx(15, FontWeight.w500, _textMid)),
                      const SizedBox(height: 4),
                      Text(
                        _buscado
                          ? 'Prueba con otros filtros'
                          : 'Por nombre, especialidad o distrito',
                        style: _tx(12, FontWeight.w400, _textDim)),
                    ],
                  ))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                    itemCount: _resultados.length,
                    itemBuilder: (_, i) {
                      final t = _resultados[i] as Map<String, dynamic>;
                      return _TecnicoCard(
                        tecnico: t,
                        onSolicitar: () => context.go(
                          '/crear-pedido?tecnico_id=${t['usuario_id']}'),
                        tx: _tx);
                    },
                  ),
          ),

          TukiBottomNav(
            index: 1,
            onTap: (i) {
              if (i == 0) context.go('/home');
              if (i == 2) context.go('/mis-pedidos');
              if (i == 3) context.go('/perfil');
            },
            rol: 'cliente',
          ),
        ]),
      ),
    );
  }

  void _mostrarFiltroSheet({
    required String titulo,
    required List<String> opciones,
    required String seleccionado,
    required Function(String) onSelect,
  }) {
    showModalBottomSheet(
  context: context,
  backgroundColor: Colors.transparent,
  isScrollControlled: true,
  builder: (_) => DraggableScrollableSheet(
    initialChildSize: 0.5,
    minChildSize: 0.3,
    maxChildSize: 0.8,
    expand: false,
    builder: (_, scrollCtrl) => Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161920),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(
          width: 36, height: 4,
          decoration: BoxDecoration(
            color: _surfaceHi,
            borderRadius: BorderRadius.circular(99))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Row(children: [
            Text(titulo,
              style: _tx(16, FontWeight.w500, _textPri, ls: -0.3)),
          ]),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            controller: scrollCtrl,
            children: opciones.map((op) {
              final sel = op == seleccionado;
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onSelect(op);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22, vertical: 14),
                  color: Colors.transparent,
                  child: Row(children: [
                    Expanded(child: Text(op,
                      style: _tx(14, FontWeight.w400,
                        sel ? _textPri : _textMid))),
                    if (sel)
                      const Icon(Icons.check_rounded,
                        size: 16, color: _blueLight),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ]),
    ),
  ),
);
  }
}

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool activo;
  final IconData icon;
  final VoidCallback onTap;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;

  const _FiltroChip({required this.label, required this.activo,
    required this.icon, required this.onTap, required this.tx});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: activo ? _blueDim : _surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: activo ? _blueBorder : _border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13,
          color: activo ? _blueLight : _textDim),
        const SizedBox(width: 5),
        Text(label,
          style: tx(12, FontWeight.w400,
            activo ? _blueLight : _textDim)),
        const SizedBox(width: 3),
        Icon(Icons.keyboard_arrow_down_rounded, size: 14,
          color: activo ? _blueLight : _textDim),
      ]),
    ),
  );
}

class _TecnicoCard extends StatelessWidget {
  final Map<String, dynamic> tecnico;
  final VoidCallback onSolicitar;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;

  const _TecnicoCard({required this.tecnico,
    required this.onSolicitar, required this.tx});

  @override
  Widget build(BuildContext context) {
    final nombre = tecnico['nombre'] as String? ?? 'Técnico';
    final especialidades = (tecnico['especialidades'] as List?)
      ?.map((e) => e.toString()).toList() ?? [];
    final calificacion = (tecnico['calificacion'] as num?)?.toDouble() ?? 0;
    final trabajos = tecnico['trabajos_completados'] as int? ?? 0;
    final precio = tecnico['precio_minimo'];
    final bio = tecnico['bio'] as String?;
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'T';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14FFFFFF))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            // Avatar
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: _blueDim,
                shape: BoxShape.circle,
                border: Border.all(color: _blueBorder)),
              child: Center(child: Text(inicial,
                style: tx(18, FontWeight.w500, _blueLight)))),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(child: Text(nombre,
                    style: tx(14, FontWeight.w500, _textPri),
                    overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _greenDim,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _greenBorder)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.verified_rounded,
                        size: 9, color: _green),
                      const SizedBox(width: 3),
                      Text('Verificado',
                        style: tx(8, FontWeight.w500, _green)),
                    ])),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Text(tecnico['distrito'] ?? '',
                    style: tx(11, FontWeight.w400, _textDim)),
                  if (trabajos > 0) ...[
                    const SizedBox(width: 8),
                    Container(width: 3, height: 3,
                      decoration: const BoxDecoration(
                        color: _textDim, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('$trabajos trabajos',
                      style: tx(11, FontWeight.w400, _textDim)),
                  ],
                ]),
              ],
            )),
            // Rating
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              if (calificacion > 0) Row(children: [
                const Icon(Icons.star_rounded, size: 13, color: _amber),
                const SizedBox(width: 3),
                Text(calificacion.toStringAsFixed(1),
                  style: tx(13, FontWeight.w500, _textMid)),
              ]),
              if (precio != null) ...[
                const SizedBox(height: 3),
                Text('Desde S/ $precio',
                  style: tx(11, FontWeight.w400, _textDim)),
              ],
            ]),
          ]),

          // Especialidades
          if (especialidades.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6, runSpacing: 6,
              children: especialidades.take(4).map((e) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _blueDim,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _blueBorder)),
                child: Text(e,
                  style: tx(10, FontWeight.w500, _blueLight)),
              )).toList(),
            ),
          ],

          // Bio
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(bio,
              style: tx(12, FontWeight.w400, _textDim, h: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          ],

          const SizedBox(height: 12),

          // Botón solicitar
          GestureDetector(
            onTap: onSolicitar,
            child: Container(
              width: double.infinity,
              height: 42,
              decoration: BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.circular(12)),
              child: Center(child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_rounded,
                    color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text('Solicitar servicio',
                    style: tx(13, FontWeight.w500, Colors.white)),
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }
}