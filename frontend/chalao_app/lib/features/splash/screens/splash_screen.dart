// splash_screen.dart — Pantalla de carga inicial con identidad Tuki
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  static const _bg = Color(0xFF0B0D12);
  static const _blue = Color(0xFF3B82F6);
  static const _dim = Color(0x66FFFFFF);

  TextStyle _tx(double size, FontWeight w, Color c, {double? ls}) =>
      GoogleFonts.inter(
          fontSize: size, fontWeight: w, color: c, letterSpacing: ls ?? 0);

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );

    _resolverDestino();
  }

  Future<void> _resolverDestino() async {
    // Tiempo mínimo para mostrar el splash y permitir
    // que cargarSesion() termine de resolver el estado.
    final inicio = DateTime.now();

    final auth = context.read<AuthProvider>();
    // Espera a que termine de cargar la sesión si aún no lo hizo
    while (auth.cargando) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    final transcurrido = DateTime.now().difference(inicio);
    const minimo = Duration(milliseconds: 1400);
    if (transcurrido < minimo) {
      await Future.delayed(minimo - transcurrido);
    }

    if (!mounted) return;

    if (!auth.autenticado) {
      context.go('/login');
      return;
    }

    final estado = auth.estadoVerificacion;
    if (estado == 'verificado') {
      context.go('/home');
    } else if (estado == 'docs_enviados' || estado == 'en_revision') {
      context.go('/en-revision');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Glows de fondo (consistente con login)
          const Positioned(
            top: -160, right: -140,
            child: _Glow(size: 320, color: Color(0x263B82F6))),
          const Positioned(
            bottom: -180, left: -160,
            child: _Glow(size: 360, color: Color(0x1434D399))),

          // Contenido central
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Imagen splash (van Tuki)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/img/splash.png',
                        width: 280,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: _blue.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer
          Positioned(
            left: 0, right: 0, bottom: 36,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(children: [
                Text('Tuki.pe',
                  style: _tx(13, FontWeight.w500, _dim, ls: 0.5)),
                const SizedBox(height: 4),
                Text('Servicios locales en Lambayeque',
                  style: _tx(11, FontWeight.w400, const Color(0x38FFFFFF))),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}