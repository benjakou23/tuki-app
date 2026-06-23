// bottom_nav.dart — Rediseño dark
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _bg        = Color(0xFF0D0F14);
const _border    = Color(0x14FFFFFF);
const _blue      = Color(0xFF2563EB);
const _blueLight = Color(0xFF60A5FA);
const _textDim   = Color(0x38FFFFFF);

class TukiBottomNav extends StatelessWidget {
  final int index;
  final Function(int) onTap;
  final String rol;

  const TukiBottomNav({
    super.key,
    required this.index,
    required this.onTap,
    required this.rol,
  });

  @override
  Widget build(BuildContext context) {
    final items = rol == 'cliente'
        ? [
            {'icon': Icons.home_rounded,         'label': 'Inicio'},
            {'icon': Icons.search_rounded,        'label': 'Buscar'},
            {'icon': Icons.receipt_long_rounded,  'label': 'Pedidos'},
            {'icon': Icons.person_rounded,        'label': 'Perfil'},
          ]
        : [
            {'icon': Icons.home_rounded,          'label': 'Inicio'},
            {'icon': Icons.work_rounded,          'label': 'Trabajos'},
            {'icon': Icons.bar_chart_rounded,     'label': 'Ganancias'},
            {'icon': Icons.person_rounded,        'label': 'Perfil'},
          ];

    return Container(
      decoration: BoxDecoration(
        color: _bg,
        border: Border(
          top: BorderSide(color: _border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: List.generate(items.length, (i) {
              final activo = i == index;
              final icon   = items[i]['icon'] as IconData;
              final label  = items[i]['label'] as String;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: activo ? 36 : 0,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: activo ? _blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      Icon(
                        icon,
                        size: 22,
                        color: activo ? _blueLight : _textDim,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: activo ? _blueLight : _textDim,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}