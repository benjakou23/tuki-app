import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/auth_provider.dart';
import '../../../core/ubicacion_service.dart';

// ── Paleta dark (consistente con el sistema) ──────────────────────────────────
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
const _textPri   = Color(0xFFFFFFFF);
const _textMid   = Color(0x99FFFFFF);
const _textDim   = Color(0x38FFFFFF);

const _tileUrl =
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

class MapaClienteScreen extends StatefulWidget {
  const MapaClienteScreen({super.key});
  @override
  State<MapaClienteScreen> createState() => _MapaClienteScreenState();
}

class _MapaClienteScreenState extends State<MapaClienteScreen> {
  final _mapCtrl = MapController();
  Position? _miPosicion;
  List<Map<String, dynamic>> _tecnicos = [];
  dynamic _canalTecnicos;
  bool _cargando = true;

  static const _chiclayo = LatLng(-6.7714, -79.8409);

  TextStyle _tx(double s, FontWeight w, Color c, {double? ls, double? h}) =>
      GoogleFonts.inter(
          fontSize: s, fontWeight: w, color: c,
          letterSpacing: ls ?? 0, height: h);

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  @override
  void dispose() {
    _canalTecnicos?.unsubscribe();
    super.dispose();
  }

  Future<void> _inicializar() async {
    final pos = await UbicacionService.obtenerUbicacion();
    if (mounted) setState(() { _miPosicion = pos; _cargando = false; });

    _canalTecnicos = UbicacionService.escucharTecnicos(
      onUpdate: (tecnicos) {
        if (mounted) setState(() => _tecnicos = tecnicos);
      },
    );

    try {
      final data = await UbicacionService.supabase
          .from('ubicaciones_tecnicos')
          .select()
          .eq('disponible', true);
      if (mounted) {
        setState(() =>
            _tecnicos = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) { debugPrint('Error técnicos: $e'); }
  }

  LatLng get _miPos => _miPosicion != null
      ? LatLng(_miPosicion!.latitude, _miPosicion!.longitude)
      : _chiclayo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Mapa ──────────────────────────────────────────────────────
            // Un solo FlutterMap. El ColorFilter solo envuelve el TileLayer.
            FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                  initialCenter: _miPos,
                  initialZoom: 14),
              children: [
                // Tiles con filtro oscuro (solo el tile, no los marcadores)
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    -0.8,  0,    0,    0, 230,
                     0,   -0.8,  0,    0, 230,
                     0,    0,   -0.8,  0, 230,
                     0,    0,    0,    1,   0,
                  ]),
                  child: TileLayer(
                    urlTemplate: _tileUrl,
                    userAgentPackageName: 'pe.tuki.app',
                  ),
                ),
                // Marcadores fuera del filtro — colores reales
                MarkerLayer(markers: [
                  // Mi posición
                  Marker(
                    point: _miPos,
                    width: 44, height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _blue,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF0D0F14), width: 2.5),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  // Técnicos disponibles
                  ..._tecnicos.map((t) {
                    final lat = (t['lat'] as num).toDouble();
                    final lng = (t['lng'] as num).toDouble();
                    return Marker(
                      point: LatLng(lat, lng),
                      width: 44, height: 44,
                      child: GestureDetector(
                        onTap: () => _mostrarTecnico(t),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1D24),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: _blueLight.withValues(alpha: 0.5),
                                width: 1.5),
                          ),
                          child: const Icon(Icons.build_rounded,
                              color: _blueLight, size: 18),
                        ),
                      ),
                    );
                  }),
                ]),
              ],
            ),



            // ── Header flotante ───────────────────────────────────────────
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0D0F14), Color(0x000D0F14)],
                    stops: [0.55, 1.0],
                  ),
                ),
                child: Row(children: [
                  _IconBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.go('/home'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                          color: const Color(0xD00D0F14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: _border)),
                      child: Row(children: [
                        const SizedBox(width: 14),
                        const Icon(Icons.search_rounded,
                            size: 16, color: _textDim),
                        const SizedBox(width: 8),
                        Text('Busca un servicio...',
                            style: _tx(13, FontWeight.w400, _textDim)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),

            // ── Botón mi ubicación ────────────────────────────────────────
            Positioned(
              bottom: 118, right: 18,
              child: GestureDetector(
                onTap: () => _mapCtrl.move(_miPos, 15),
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                      color: const Color(0xD00D0F14),
                      shape: BoxShape.circle,
                      border: Border.all(color: _border)),
                  child: const Icon(Icons.my_location_rounded,
                      color: _blueLight, size: 19),
                ),
              ),
            ),

            // ── Card inferior ─────────────────────────────────────────────
            Positioned(
              bottom: 20, left: 18, right: 18,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xF00D0F14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _border)),
                child: Row(children: [
                  // Icono técnicos
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                        color: _blueDim,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: _blueBorder)),
                    child: const Icon(Icons.build_rounded,
                        color: _blueLight, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(
                            '${_tecnicos.length}',
                            style: _tx(15, FontWeight.w500, _textPri,
                                ls: -0.3),
                          ),
                          const SizedBox(width: 4),
                          Text('técnicos cerca',
                              style: _tx(14, FontWeight.w400, _textMid)),
                        ]),
                        const SizedBox(height: 2),
                        Row(children: [
                          Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                  color: _green,
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text('Disponibles ahora',
                              style: _tx(11, FontWeight.w400, _textDim)),
                        ]),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/crear-pedido'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(999)),
                      child: Text('Solicitar',
                          style: _tx(13, FontWeight.w500, Colors.white)),
                    ),
                  ),
                ]),
              ),
            ),

            // ── Loading ───────────────────────────────────────────────────
            if (_cargando)
              const Center(
                child: CircularProgressIndicator(
                    color: _blueLight, strokeWidth: 2)),
          ],
        ),
      ),
    );
  }

  // ── Bottom sheet técnico ──────────────────────────────────────────────────
  void _mostrarTecnico(Map<String, dynamic> tecnico) {
    final dist = UbicacionService.calcularDistancia(
      _miPosicion?.latitude  ?? _chiclayo.latitude,
      _miPosicion?.longitude ?? _chiclayo.longitude,
      (tecnico['lat'] as num).toDouble(),
      (tecnico['lng'] as num).toDouble(),
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161920),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: const Color(0x28FFFFFF),
                  borderRadius: BorderRadius.circular(999)),
            ),
            const SizedBox(height: 22),

            // Info técnico
            Row(children: [
              Container(
                width: 50, height: 50,
                decoration: const BoxDecoration(
                    color: _blueDim, shape: BoxShape.circle),
                child: const Icon(Icons.build_rounded,
                    color: _blueLight, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Técnico disponible',
                        style: _tx(15, FontWeight.w500, _textPri, ls: -0.2)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.near_me_rounded,
                          size: 13, color: _blueLight),
                      const SizedBox(width: 4),
                      Text('${dist.toStringAsFixed(1)} km de distancia',
                          style: _tx(12, FontWeight.w400, _textDim)),
                    ]),
                  ],
                ),
              ),
              // Badge disponible
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: _greenDim,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: _green.withValues(alpha: 0.25))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.circle,
                      size: 6, color: _green),
                  const SizedBox(width: 4),
                  Text('Libre',
                      style: _tx(10, FontWeight.w500, _green)),
                ]),
              ),
            ]),

            const SizedBox(height: 22),

            // Botón solicitar
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                context.go('/crear-pedido');
              },
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('Solicitar servicio',
                        style: _tx(14, FontWeight.w500, Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Botón icono ───────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
          color: const Color(0xD00D0F14),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0x14FFFFFF))),
      child: const Icon(Icons.arrow_back_ios_new_rounded,
          size: 15, color: Color(0x99FFFFFF)),
    ),
  );
}