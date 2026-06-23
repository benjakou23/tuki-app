// login_screen.dart — Dark iOS refinado
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _showPass = false;
  String? _error;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  static const _bg = Color(0xFF0B0D12);
  static const _blue = Color(0xFF3B82F6);
  static const _blueSoft = Color(0xFF60A5FA);
  static const _green = Color(0xFF34D399);

  static const _text = Color(0xFFFFFFFF);
  static const _dim = Color(0x66FFFFFF);
  static const _faint = Color(0x38FFFFFF);

  @override
  void initState() {
    super.initState();

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    )..forward();

    _fadeAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.035),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );

    _phoneFocus.addListener(_refresh);
    _passFocus.addListener(_refresh);
    _phoneCtrl.addListener(_refresh);
    _passCtrl.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _animCtrl.dispose();

    _phoneFocus.removeListener(_refresh);
    _passFocus.removeListener(_refresh);
    _phoneCtrl.removeListener(_refresh);
    _passCtrl.removeListener(_refresh);

    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _phoneFocus.dispose();
    _passFocus.dispose();

    super.dispose();
  }

  TextStyle _tx(
    double size,
    FontWeight weight,
    Color color, {
    double? height,
    double ls = 0,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: ls,
    );
  }

  Widget _floatingField({
    required TextEditingController ctrl,
    required FocusNode focus,
    required String label,
    required IconData prefixIcon,
    bool obscure = false,
    TextInputType keyboard = TextInputType.text,
    Widget? suffix,
    Widget? prefix,
  }) {
    final active = focus.hasFocus || ctrl.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: 60,
      decoration: BoxDecoration(
        color: focus.hasFocus
            ? _blue.withValues(alpha: 0.075)
            : Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: focus.hasFocus
              ? _blue.withValues(alpha: 0.42)
              : Colors.white.withValues(alpha: 0.075),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Icon(prefixIcon, size: 19, color: active ? _dim : _faint),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            left: 48,
            top: active ? 9 : 20,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              style: _tx(
                active ? 11 : 14,
                FontWeight.w400,
                active ? _faint : _dim,
                ls: active ? 0.1 : 0,
              ),
              child: Text(label),
            ),
          ),
          if (prefix != null && active)
            Positioned(
              left: 48,
              bottom: 10,
              child: prefix,
            ),
          Positioned.fill(
            child: TextField(
              controller: ctrl,
              focusNode: focus,
              obscureText: obscure,
              keyboardType: keyboard,
              cursorColor: _blueSoft,
              style: _tx(15, FontWeight.w400, _text),
              decoration: InputDecoration(
                border: InputBorder.none,
                suffixIcon: suffix,
                contentPadding: EdgeInsets.only(
                  left: prefix != null && active ? 91 : 48,
                  right: suffix != null ? 48 : 16,
                  top: active ? 23 : 15,
                  bottom: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          const Positioned(
            top: -160,
            right: -140,
            child: _Glow(size: 320, color: Color(0x263B82F6)),
          ),
          const Positioned(
            bottom: -180,
            left: -160,
            child: _Glow(size: 360, color: Color(0x1434D399)),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _NoiseDots(color: Colors.white24),
            ),
          ),
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TopBar(textStyle: _tx),
                      const SizedBox(height: 54),

                      Text(
                        'Bienvenido de vuelta',
                        style: _tx(13, FontWeight.w400, _blueSoft),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Inicia sesión\nen tu cuenta',
                        style: _tx(
                          36,
                          FontWeight.w500,
                          _text,
                          height: 1.08,
                          ls: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Servicios locales, rápidos y confiables.',
                        style: _tx(15, FontWeight.w400, _dim, height: 1.35),
                      ),

                      const SizedBox(height: 34),

                      Container(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.055),
                      ),

                      const SizedBox(height: 26),

                      _floatingField(
                        ctrl: _phoneCtrl,
                        focus: _phoneFocus,
                        label: 'Número de celular',
                        prefixIcon: Icons.phone_iphone_outlined,
                        keyboard: TextInputType.phone,
                        prefix: Text(
                          '+51',
                          style: _tx(15, FontWeight.w500, _blueSoft),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _floatingField(
                        ctrl: _passCtrl,
                        focus: _passFocus,
                        label: 'Contraseña',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscure: !_showPass,
                        suffix: IconButton(
                          splashRadius: 20,
                          onPressed: () {
                            setState(() => _showPass = !_showPass);
                          },
                          icon: Icon(
                            _showPass
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 19,
                            color: _faint,
                          ),
                        ),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        _ErrorBar(
                          message: _error!,
                          textStyle: _tx,
                        ),
                      ],

                      const SizedBox(height: 24),

                      _PrimaryBtn(
                        label: 'Ingresar',
                        loading: auth.cargando,
                        onTap: auth.cargando ? null : _login,
                        textStyle: _tx,
                      ),

                      const SizedBox(height: 10),

                      _SecondaryBtn(
                        label: 'Crear cuenta nueva',
                        onTap: () => context.go('/registro'),
                        textStyle: _tx,
                      ),

                      const SizedBox(height: 34),

                      _Footer(textStyle: _tx),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    setState(() => _error = null);

    if (_phoneCtrl.text.trim().isEmpty || _passCtrl.text.isEmpty) {
      setState(() => _error = 'Completa todos los campos');
      return;
    }

    final ok = await context.read<AuthProvider>().login(
          _phoneCtrl.text.trim(),
          _passCtrl.text,
        );

    if (!ok && mounted) {
      setState(() => _error = 'Teléfono o contraseña incorrectos');
    }
  }
}

class _TopBar extends StatelessWidget {
  final TextStyle Function(
    double,
    FontWeight,
    Color, {
    double? height,
    double ls,
  }) textStyle;

  const _TopBar({required this.textStyle});

  static const _text = Color(0xFFFFFFFF);
  static const _dim = Color(0x66FFFFFF);
  static const _blueSoft = Color(0xFF60A5FA);
  static const _green = Color(0xFF34D399);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Tuki',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: _text,
                  letterSpacing: -0.2,
                ),
              ),
              TextSpan(
                text: '.pe',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: _blueSoft,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.045),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.075)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Lambayeque',
                style: textStyle(12, FontWeight.w400, _dim),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  final TextStyle Function(
    double,
    FontWeight,
    Color, {
    double? height,
    double ls,
  }) textStyle;

  const _PrimaryBtn({
    required this.label,
    required this.loading,
    required this.onTap,
    required this.textStyle,
  });

  static const _blue = Color(0xFF2563EB);
  static const _blueLight = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? _blue.withValues(alpha: 0.35) : _blue,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: onTap == null
                ? null
                : const LinearGradient(
                    colors: [_blueLight, _blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            boxShadow: onTap == null
                ? null
                : [
                    BoxShadow(
                      color: _blue.withValues(alpha: 0.26),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: textStyle(15, FontWeight.w500, Colors.white),
                      ),
                      const SizedBox(width: 9),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final TextStyle Function(
    double,
    FontWeight,
    Color, {
    double? height,
    double ls,
  }) textStyle;

  const _SecondaryBtn({
    required this.label,
    required this.onTap,
    required this.textStyle,
  });

  static const _dim = Color(0x66FFFFFF);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.035),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.075)),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.person_add_alt_1_outlined,
                  size: 17,
                  color: _dim,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: textStyle(14, FontWeight.w400, _dim),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBar extends StatelessWidget {
  final String message;
  final TextStyle Function(
    double,
    FontWeight,
    Color, {
    double? height,
    double ls,
  }) textStyle;

  const _ErrorBar({
    required this.message,
    required this.textStyle,
  });

  static const _errorFg = Color(0xFFFCA5A5);
  static const _errorBg = Color(0x18EF4444);
  static const _errorBd = Color(0x33EF4444);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _errorBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _errorBd),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 17, color: _errorFg),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: textStyle(13, FontWeight.w400, _errorFg),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final TextStyle Function(
    double,
    FontWeight,
    Color, {
    double? height,
    double ls,
  }) textStyle;

  const _Footer({required this.textStyle});

  static const _faint = Color(0x38FFFFFF);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Pill(
          icon: Icons.handyman_outlined,
          label: 'Técnicos',
          textStyle: textStyle,
        ),
        const SizedBox(width: 6),
        _Pill(
          icon: Icons.local_shipping_outlined,
          label: 'Delivery',
          textStyle: textStyle,
        ),
        const SizedBox(width: 6),
        _Pill(
          icon: Icons.home_outlined,
          label: 'Hogar',
          textStyle: textStyle,
        ),
        const Spacer(),
        Text(
          'v2.0',
          style: textStyle(11, FontWeight.w400, _faint),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextStyle Function(
    double,
    FontWeight,
    Color, {
    double? height,
    double ls,
  }) textStyle;

  const _Pill({
    required this.icon,
    required this.label,
    required this.textStyle,
  });

  static const _faint = Color(0x38FFFFFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _faint),
          const SizedBox(width: 5),
          Text(
            label,
            style: textStyle(11, FontWeight.w400, _faint),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _NoiseDots extends CustomPainter {
  final Color color;

  const _NoiseDots({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.025);
    const gap = 30.0;

    for (double x = 0; x < size.width; x += gap) {
      for (double y = 0; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_NoiseDots oldDelegate) {
    return oldDelegate.color != color;
  }
}