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
const _textPri   = Color(0xFFFFFFFF);
const _textMid   = Color(0x99FFFFFF);
const _textDim   = Color(0x38FFFFFF);

class GananciasScreen extends StatefulWidget {
  const GananciasScreen({super.key});
  @override
  State<GananciasScreen> createState() => _GananciasScreenState();
}

class _GananciasScreenState extends State<GananciasScreen> {
  Map<String, dynamic>? _data;
  bool _cargando = true;
  String? _error;

  TextStyle _tx(double s, FontWeight w, Color c, {double? ls, double? h}) =>
      GoogleFonts.inter(fontSize: s, fontWeight: w, color: c,
          letterSpacing: ls ?? 0, height: h);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final res = await ApiClient.get('/pedidos/mis-ganancias', auth: true);
      if (mounted) setState(() { _data = res; _cargando = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Error al cargar'; _cargando = false; });
    }
  }

  String _formatFecha(String? ts) {
    if (ts == null) return '';
    try {
      final d = DateTime.parse(ts).toLocal();
      final meses = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return '${d.day} ${meses[d.month]} ${d.year}';
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
              Expanded(child: Text('Ganancias',
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

          Expanded(
            child: _cargando
              ? const Center(child: CircularProgressIndicator(
                  color: _blueLight, strokeWidth: 2))
              : _error != null
                ? Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                        size: 36, color: _textDim),
                      const SizedBox(height: 12),
                      Text(_error!, style: _tx(14, FontWeight.w400, _textDim)),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _cargar,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: _blue,
                            borderRadius: BorderRadius.circular(10)),
                          child: Text('Reintentar',
                            style: _tx(13, FontWeight.w500, Colors.white)),
                        ),
                      ),
                    ],
                  ))
                : RefreshIndicator(
                    onRefresh: _cargar,
                    color: _blueLight,
                    backgroundColor: _bg,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // ── Card principal neto del mes ──────────────
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E3A5F), Color(0xFF0D1F35)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _blueBorder)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Neto este mes',
                                  style: _tx(12, FontWeight.w400, _textDim,
                                    ls: 0.04)),
                                const SizedBox(height: 6),
                                Text(
                                  'S/ ${(_data!['neto_mes'] as num).toStringAsFixed(2)}',
                                  style: _tx(36, FontWeight.w600, _textPri,
                                    ls: -1.0)),
                                const SizedBox(height: 4),
                                Text(
                                  '${_data!['trabajos_mes']} trabajo${_data!['trabajos_mes'] == 1 ? '' : 's'} completado${_data!['trabajos_mes'] == 1 ? '' : 's'}',
                                  style: _tx(12, FontWeight.w400, _textMid)),
                                const SizedBox(height: 16),
                                Container(
                                  height: 1,
                                  color: _blueBorder),
                                const SizedBox(height: 16),
                                Row(children: [
                                  Expanded(child: _MiniStat(
                                    label: 'Facturado',
                                    valor: 'S/ ${(_data!['total_mes'] as num).toStringAsFixed(2)}',
                                    color: _textMid,
                                    tx: _tx)),
                                  Container(width: 1, height: 32, color: _border),
                                  Expanded(child: _MiniStat(
                                    label: 'Comisión Tuki',
                                    valor: '-S/ ${(_data!['comision_mes'] as num).toStringAsFixed(2)}',
                                    color: _rose,
                                    tx: _tx)),
                                ]),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── Stats secundarios ────────────────────────
                          Row(children: [
                            Expanded(child: _StatCard(
                              label: 'Total histórico',
                              valor: 'S/ ${(_data!['total_historico'] as num).toStringAsFixed(0)}',
                              icon: Icons.account_balance_wallet_rounded,
                              color: _green,
                              dim: _greenDim,
                              borderColor: _greenBorder,
                              tx: _tx)),
                            const SizedBox(width: 10),
                            Expanded(child: _StatCard(
                              label: 'Trabajos totales',
                              valor: '${_data!['trabajos_total']}',
                              icon: Icons.check_circle_rounded,
                              color: _amber,
                              dim: _amberDim,
                              borderColor: _amberBorder,
                              tx: _tx)),
                          ]),

                          const SizedBox(height: 20),

                          // ── Info comisión ────────────────────────────
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _amberDim,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _amberBorder)),
                            child: Row(children: [
                              const Icon(Icons.info_outline_rounded,
                                size: 16, color: _amber),
                              const SizedBox(width: 10),
                              Expanded(child: Text(
                                'Tuki retiene el 8% de comisión por cada servicio completado.',
                                style: _tx(12, FontWeight.w400, _amber, h: 1.4))),
                            ]),
                          ),

                          const SizedBox(height: 24),

                          // ── Historial ────────────────────────────────
                          Row(children: [
                            Text('Historial de pagos',
                              style: _tx(14, FontWeight.w500, _textMid)),
                            const Spacer(),
                            Text(
                              '${(_data!['pedidos'] as List).length} servicios',
                              style: _tx(12, FontWeight.w400, _textDim)),
                          ]),

                          const SizedBox(height: 12),

                          if ((_data!['pedidos'] as List).isEmpty)
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _border)),
                              child: Center(child: Column(children: [
                                const Icon(Icons.receipt_long_rounded,
                                  size: 28, color: _textDim),
                                const SizedBox(height: 8),
                                Text('Sin servicios completados aún',
                                  style: _tx(13, FontWeight.w400, _textDim)),
                              ])),
                            )
                          else
                            ...(_data!['pedidos'] as List).map((p) {
                              final neto = (p['neto'] as num).toDouble();
                              final comision = (p['comision_tuki'] as num?)?.toDouble() ?? 0;
                              final total = (p['precio_final'] as num?)?.toDouble() ?? 0;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _border)),
                                child: Row(children: [
                                  Container(
                                    width: 42, height: 42,
                                    decoration: BoxDecoration(
                                      color: _greenDim,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _greenBorder)),
                                    child: const Icon(Icons.build_rounded,
                                      size: 18, color: _green)),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p['categoria'] ?? '',
                                        style: _tx(13, FontWeight.w500, _textMid)),
                                      const SizedBox(height: 2),
                                      Row(children: [
                                        Text(p['distrito'] ?? '',
                                          style: _tx(11, FontWeight.w400, _textDim)),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 3, height: 3,
                                          decoration: const BoxDecoration(
                                            color: _textDim,
                                            shape: BoxShape.circle)),
                                        const SizedBox(width: 6),
                                        Text(_formatFecha(p['completado_en']),
                                          style: _tx(11, FontWeight.w400, _textDim)),
                                      ]),
                                    ],
                                  )),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('S/ ${neto.toStringAsFixed(2)}',
                                        style: _tx(14, FontWeight.w600, _green)),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Total S/${total.toStringAsFixed(0)} · -${(comision * 100 / (total == 0 ? 1 : total)).toStringAsFixed(0)}%',
                                        style: _tx(10, FontWeight.w400, _textDim)),
                                    ],
                                  ),
                                ]),
                              );
                            }),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
          ),

          TukiBottomNav(
            index: 2,
            onTap: (i) {
              if (i == 0) context.go('/home');
              if (i == 1) context.go('/pedidos-disponibles');
              if (i == 3) context.go('/perfil');
            },
            rol: 'tecnico',
          ),
        ]),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label, valor;
  final Color color;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _MiniStat({required this.label, required this.valor,
    required this.color, required this.tx});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(valor, style: tx(15, FontWeight.w600, color)),
    const SizedBox(height: 3),
    Text(label, style: tx(11, FontWeight.w400, const Color(0x38FFFFFF))),
  ]);
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
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0x0AFFFFFF),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0x14FFFFFF))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: dim,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor)),
        child: Icon(icon, size: 17, color: color)),
      const SizedBox(height: 10),
      Text(valor, style: tx(20, FontWeight.w600, Colors.white, ls: -0.5)),
      const SizedBox(height: 2),
      Text(label, style: tx(11, FontWeight.w400,
        const Color(0x38FFFFFF)),
        maxLines: 1, overflow: TextOverflow.ellipsis),
    ]),
  );
}