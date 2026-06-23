// registro_screen.dart — Rediseño dark (consistente con login)
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/auth_provider.dart';
import '../../../core/api_client.dart';

// ── Paleta (misma que login) ──────────────────────────────────────────────────
const _bg        = Color(0xFF0D0F14);
const _blue      = Color(0xFF2563EB);
const _blueDark  = Color(0xFF1D4ED8);
const _blueLight = Color(0xFF60A5FA);
const _green     = Color(0xFF34D399);
const _amber     = Color(0xFFFBBF24);
const _errorFg   = Color(0xFFF87171);
const _errorBg   = Color(0x14E24B4A);
const _errorBd   = Color(0x33E24B4A);
const _border    = Color(0x14FFFFFF);   // 8% white
const _surface   = Color(0x0AFFFFFF);   // 4% white
const _textPri   = Color(0xFFFFFFFF);
const _textMid   = Color(0x99FFFFFF);   // 60%
const _textMuted = Color(0x61FFFFFF);   // 38%
const _textDim   = Color(0x38FFFFFF);   // 22%

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});
  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen>
    with SingleTickerProviderStateMixin {
  final _pageCtrl     = PageController();
  int _paso           = 0;
  static const _total = 4;

  // Controladores (sin cambios)
  final _nombreCtrl   = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _dniCtrl      = TextEditingController();
  bool  _verPassword  = false;
  String _rol         = 'cliente';
  String? _fechaNacimiento;
  bool   _buscandoDni  = false;
  String? _nombreReniec;
  bool   _dniVerificado = false;
  String? _error;
  bool    _cargando = false;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;

  TextStyle _tx(double size, FontWeight w, Color c, {double? ls, double? h}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: w, color: c,
          letterSpacing: ls ?? 0, height: h);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500))..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _pageCtrl.dispose();
    _nombreCtrl.dispose(); _telefonoCtrl.dispose();
    _emailCtrl.dispose();  _passwordCtrl.dispose();
    _dniCtrl.dispose();
    super.dispose();
  }

  // ── Navegación ────────────────────────────────────────────────────────────
  void _siguiente() {
    setState(() => _error = null);
    if (_paso == 0 && !_validar1()) return;
    if (_paso == 1 && !_validar2()) return;
    if (_paso == 3) { _registrar(); return; }
    final n = _paso + 1;
    setState(() => _paso = n);
    _pageCtrl.animateToPage(n,
        duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
  }

  void _anterior() {
    setState(() => _error = null);
    if (_paso > 0) {
      final n = _paso - 1;
      setState(() => _paso = n);
      _pageCtrl.animateToPage(n,
          duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
    } else {
      context.go('/login');
    }
  }

  // ── Validaciones (idénticas) ───────────────────────────────────────────────
  bool _validar1() {
    if (_nombreCtrl.text.trim().length < 3) {
      setState(() => _error = 'Ingresa tu nombre completo'); return false; }
    if (_telefonoCtrl.text.trim().length < 9) {
      setState(() => _error = 'Ingresa un número de 9 dígitos'); return false; }
    return true;
  }
  bool _validar2() {
    if (!_emailCtrl.text.contains('@') || _emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Ingresa un email válido'); return false; }
    if (_passwordCtrl.text.length < 6) {
      setState(() => _error = 'La contraseña debe tener mínimo 6 caracteres');
      return false; }
    return true;
  }

  // ── RENIEC (lógica idéntica) ───────────────────────────────────────────────
  Future<void> _consultarDni(String dni) async {
    if (dni.length != 8) return;
    setState(() {
      _buscandoDni = true; _nombreReniec = null;
      _dniVerificado = false; _error = null;
    });
    try {
      final base = ApiClient.baseUrl.replaceAll(RegExp(r'/$'), '');
      final res  = await http.get(
        Uri.parse('$base/reniec/consultar/$dni'),
        headers: {'Authorization': 'Bearer ${ApiClient.getToken()}',
                  'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data    = jsonDecode(res.body);
        final nombre  = data['nombre_completo'] as String? ?? '';
        if (nombre.isNotEmpty) {
          setState(() { _nombreReniec = nombre; _dniVerificado = true; });
        } else {
          setState(() => _error = 'DNI no encontrado en RENIEC');
        }
      } else if (res.statusCode == 404) {
        setState(() => _error = 'DNI no encontrado en RENIEC');
      } else {
        setState(() => _error = _parsearError(res.body));
      }
    } on TimeoutException {
      setState(() => _error = 'La consulta tardó demasiado. Intenta de nuevo.');
    } catch (_) {
      setState(() => _error = 'Error de conexión. Verifica tu internet.');
    } finally {
      setState(() => _buscandoDni = false);
    }
  }

  String _parsearError(String body) {
    try {
      return jsonDecode(body)['detail'] as String? ?? 'Error al verificar el DNI';
    } catch (_) { return 'Error al verificar el DNI'; }
  }

  Future<void> _registrar() async {
    if (_dniCtrl.text.trim().length < 8) {
      setState(() => _error = 'Ingresa tu DNI (8 dígitos)'); return; }
    if (!_dniVerificado) {
      setState(() => _error = 'Verifica tu DNI antes de continuar'); return; }
    setState(() { _cargando = true; _error = null; });
    final datos = <String, dynamic>{
      'nombre'   : _nombreCtrl.text.trim(),
      'telefono' : _telefonoCtrl.text.trim(),
      'email'    : _emailCtrl.text.trim(),
      'password' : _passwordCtrl.text,
      'rol'      : _rol,
      'dni_numero': _dniCtrl.text.trim(),
      if (_fechaNacimiento != null) 'fecha_nacimiento': _fechaNacimiento,
    };
    final ok = await context.read<AuthProvider>().registrar(datos);
    if (!mounted) return;
    if (ok) { context.go('/onboarding'); }
    else { setState(() { _cargando = false; _error = 'Error al registrarse. Intenta de nuevo.'; }); }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [_paso1(), _paso2(), _paso3(), _paso4()],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top bar con progreso ──────────────────────────────────────────────────
  Widget _buildTopBar() {
    const labels = ['Nombre', 'Acceso', 'Rol', 'Identidad'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(children: [
        // Botón atrás
        GestureDetector(
          onTap: _anterior,
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border)),
            child: const Icon(Icons.arrow_back_rounded,
                size: 16, color: _textMid),
          ),
        ),
        const SizedBox(width: 14),

        // Barras + labels
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(_total, (i) => Expanded(
                  child: Text(labels[i],
                    overflow: TextOverflow.ellipsis,
                    style: _tx(9, FontWeight.w500,
                      i < _paso ? _green : i == _paso ? _textMid : _textDim,
                      ls: 0.02)),
                )),
              ),
              const SizedBox(height: 5),
              Row(
                children: List.generate(_total, (i) {
                  final color = i < _paso ? _green
                      : i == _paso ? _blue : _border;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < _total - 1 ? 4 : 0),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 2,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(99)),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _border)),
          child: Text('${_paso + 1}/$_total',
              style: _tx(11, FontWeight.w400, _textMuted)),
        ),
      ]),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (_error != null) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: _errorBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _errorBd)),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, size: 16, color: _errorFg),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!,
                  style: _tx(13, FontWeight.w400, _errorFg))),
            ]),
          ),
        ],
        Material(
          color: _cargando ? _blue.withValues(alpha: 0.35) : _blue,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _cargando ? null : _siguiente,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: double.infinity, height: 52,
              child: Center(
                child: _cargando
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(_paso == _total - 1 ? 'Crear cuenta' : 'Continuar',
                            style: _tx(14, FontWeight.w500, Colors.white)),
                        const SizedBox(width: 8),
                        Icon(
                          _paso == _total - 1
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          color: Colors.white, size: 16),
                      ]),
              ),
            ),
          ),
        ),
        if (_paso == 0) ...[
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Text('¿Ya tienes cuenta? Ingresa',
                style: _tx(13, FontWeight.w400, _textMuted)),
          ),
        ],
      ]),
    );
  }

  // ── PASO 1 ────────────────────────────────────────────────────────────────
  Widget _paso1() => _PageScroll(children: [
    _PageHeader(paso: '01', titulo: '¿Cómo te\nllamamos?',
        sub: 'Tu nombre y número para empezar.', tx: _tx),
    _DarkField(ctrl: _nombreCtrl, hint: 'Anderson Girón',
        icon: Icons.person_outline_rounded, label: 'Nombre completo', tx: _tx),
    const SizedBox(height: 14),
    Text('Número de celular', style: _tx(11, FontWeight.w400, _textDim, ls: 0.04)),
    const SizedBox(height: 7),
    _PhoneFieldDark(controller: _telefonoCtrl, tx: _tx),
  ]);

  // ── PASO 2 ────────────────────────────────────────────────────────────────
  Widget _paso2() => _PageScroll(children: [
    _PageHeader(paso: '02', titulo: 'Tu acceso\na Tuki',
        sub: 'Correo y contraseña para ingresar.', tx: _tx),
    _DarkField(ctrl: _emailCtrl, hint: 'juan@gmail.com',
        icon: Icons.mail_outline_rounded, label: 'Correo electrónico',
        keyboard: TextInputType.emailAddress, tx: _tx),
    const SizedBox(height: 14),
    Text('Contraseña', style: _tx(11, FontWeight.w400, _textDim, ls: 0.04)),
    const SizedBox(height: 7),
    _DarkFieldRaw(
      child: TextField(
        controller: _passwordCtrl,
        obscureText: !_verPassword,
        style: _tx(14, FontWeight.w400, _textPri),
        cursorColor: _blueLight,
        decoration: InputDecoration(
          hintText: 'Mínimo 6 caracteres',
          hintStyle: _tx(14, FontWeight.w400, _textDim),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.lock_outline_rounded,
              size: 17, color: _textDim),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 17),
          suffixIcon: IconButton(
            onPressed: () => setState(() => _verPassword = !_verPassword),
            icon: Icon(
              _verPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 17, color: _textDim),
          ),
        ),
      ),
    ),
    const SizedBox(height: 14),
    _InfoBox(
      icon: Icons.shield_outlined,
      text: 'Tu información está protegida. Solo tú puedes acceder a tu cuenta.',
      tx: _tx),
  ]);

  // ── PASO 3 ────────────────────────────────────────────────────────────────
  Widget _paso3() => _PageScroll(children: [
    _PageHeader(paso: '03', titulo: '¿Qué rol\njugarás?',
        sub: 'Puedes cambiar esto después.', tx: _tx),
    _RolCardDark(
      label: 'Cliente',
      desc: 'Busco servicios técnicos cerca de mí',
      icon: Icons.person_search_outlined,
      selected: _rol == 'cliente',
      onTap: () => setState(() => _rol = 'cliente'),
      tx: _tx,
    ),
    const SizedBox(height: 10),
    _RolCardDark(
      label: 'Técnico',
      desc: 'Ofrezco mis servicios profesionales',
      icon: Icons.build_outlined,
      selected: _rol == 'tecnico',
      onTap: () => setState(() => _rol = 'tecnico'),
      tx: _tx,
    ),
    if (_rol == 'tecnico') ...[
      const SizedBox(height: 16),
      _InfoBox(
        icon: Icons.info_outline_rounded,
        text: 'Como técnico podrás recibir solicitudes de clientes en Lambayeque.',
        tx: _tx, tint: _amber),
    ],
  ]);

  // ── PASO 4 ────────────────────────────────────────────────────────────────
  Widget _paso4() => _PageScroll(children: [
    _PageHeader(paso: '04', titulo: 'Verifica\ntu identidad',
        sub: 'Consultamos el RENIEC automáticamente.', tx: _tx),

    Text('Número de DNI', style: _tx(11, FontWeight.w400, _textDim, ls: 0.04)),
    const SizedBox(height: 7),
    AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _dniVerificado
              ? _green.withValues(alpha: 0.4)
              : _border),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _dniCtrl,
            keyboardType: TextInputType.number,
            maxLength: 8,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8)],
            style: _tx(16, FontWeight.w400, _textPri, ls: 3),
            cursorColor: _blueLight,
            onChanged: (v) {
              if (_dniVerificado) setState(() {
                _dniVerificado = false; _nombreReniec = null; });
              if (v.length == 8) _consultarDni(v);
            },
            decoration: InputDecoration(
              hintText: '12345678',
              hintStyle: _tx(14, FontWeight.w400, _textDim, ls: 1),
              counterText: '',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 17)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: _buscandoDni
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _blueLight))
              : _dniVerificado
                  ? const Icon(Icons.check_circle_outline_rounded,
                      color: _green, size: 20)
                  : Icon(Icons.badge_outlined,
                      size: 18, color: _textDim),
        ),
      ]),
    ),

    if (_nombreReniec != null) ...[
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _green.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _green.withValues(alpha: 0.25))),
        child: Row(children: [
          const Icon(Icons.verified_user_outlined, size: 16, color: _green),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verificado por RENIEC',
                  style: _tx(10, FontWeight.w400, _textDim, ls: 0.03)),
              const SizedBox(height: 2),
              Text(_nombreReniec!,
                  style: _tx(14, FontWeight.w500, _textPri)),
            ],
          )),
        ]),
      ),
    ],

    const SizedBox(height: 16),
    Text('Fecha de nacimiento (opcional)',
        style: _tx(11, FontWeight.w400, _textDim, ls: 0.04)),
    const SizedBox(height: 7),
    GestureDetector(
      onTap: () async {
        final fecha = await showDatePicker(
          context: context,
          initialDate: DateTime(1995),
          firstDate: DateTime(1940),
          lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: _blue)),
            child: child!),
        );
        if (fecha != null) {
          setState(() => _fechaNacimiento =
              '${fecha.day.toString().padLeft(2,'0')}/'
              '${fecha.month.toString().padLeft(2,'0')}/'
              '${fecha.year}');
        }
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          const Icon(Icons.calendar_today_outlined, size: 16, color: _textDim),
          const SizedBox(width: 10),
          Expanded(child: Text(
            _fechaNacimiento ?? 'DD/MM/AAAA',
            style: _tx(14, FontWeight.w400,
                _fechaNacimiento != null ? _textPri : _textDim))),
        ]),
      ),
    ),

    const SizedBox(height: 14),
    _InfoBox(
      icon: Icons.shield_outlined,
      text: 'Solo usamos tu DNI para verificar tu identidad. No compartimos tus datos.',
      tx: _tx),
  ]);
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _PageScroll extends StatelessWidget {
  final List<Widget> children;
  const _PageScroll({required this.children});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}

class _PageHeader extends StatelessWidget {
  final String paso, titulo, sub;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _PageHeader({required this.paso, required this.titulo,
      required this.sub, required this.tx});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF60A5FA).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.2))),
        child: Text('Paso $paso',
            style: tx(10, FontWeight.w500, const Color(0xFF60A5FA), ls: 0.06)),
      ),
      const SizedBox(height: 10),
      Text(titulo,
          style: GoogleFonts.inter(
            fontSize: 28, fontWeight: FontWeight.w500,
            color: _textPri, height: 1.1, letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text(sub, style: tx(13, FontWeight.w400, _textMuted)),
      const SizedBox(height: 26),
    ],
  );
}

class _DarkField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint, label;
  final IconData icon;
  final TextInputType keyboard;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;

  const _DarkField({required this.ctrl, required this.hint,
      required this.icon, required this.label, required this.tx,
      this.keyboard = TextInputType.text});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: tx(11, FontWeight.w400, _textDim, ls: 0.04)),
      const SizedBox(height: 7),
      _DarkFieldRaw(child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        style: tx(14, FontWeight.w400, _textPri),
        cursorColor: _blueLight,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: tx(14, FontWeight.w400, _textDim),
          border: InputBorder.none,
          prefixIcon: Icon(icon, size: 17, color: _textDim),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 17)),
      )),
    ],
  );
}

class _DarkFieldRaw extends StatelessWidget {
  final Widget child;
  const _DarkFieldRaw({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _border)),
    child: child,
  );
}

class _PhoneFieldDark extends StatelessWidget {
  final TextEditingController controller;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _PhoneFieldDark({required this.controller, required this.tx});

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _border)),
    child: Row(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text('+51', style: tx(14, FontWeight.w500, _blueLight)),
      ),
      Container(width: 0.5, height: 18,
          color: Colors.white.withValues(alpha: 0.12)),
      Expanded(
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9)],
          style: tx(14, FontWeight.w400, _textPri),
          cursorColor: _blueLight,
          decoration: InputDecoration(
            hintText: '987 654 321',
            hintStyle: tx(14, FontWeight.w400, _textDim),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.only(left: 12, right: 14)),
        ),
      ),
      const Padding(
        padding: EdgeInsets.only(right: 14),
        child: Icon(Icons.phone_iphone_outlined, size: 17, color: _textDim),
      ),
    ]),
  );
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? tint;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _InfoBox({required this.icon, required this.text,
      required this.tx, this.tint});

  @override
  Widget build(BuildContext context) {
    final c = tint ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.10))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 15, color: c.withValues(alpha: 0.4)),
        const SizedBox(width: 10),
        Expanded(child: Text(text,
            style: tx(12, FontWeight.w400, c.withValues(alpha: 0.45),
                h: 1.5))),
      ]),
    );
  }
}

class _RolCardDark extends StatelessWidget {
  final String label, desc;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle Function(double, FontWeight, Color, {double? ls, double? h}) tx;
  const _RolCardDark({required this.label, required this.desc,
      required this.icon, required this.selected,
      required this.onTap, required this.tx});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected
            ? _blue.withValues(alpha: 0.12)
            : _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? _blue.withValues(alpha: 0.4)
              : _border)),
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: selected
                ? _blue.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20,
              color: selected ? _blueLight : _textDim),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: tx(14, FontWeight.w500,
                    selected ? _textPri : _textMid)),
            const SizedBox(height: 2),
            Text(desc,
                style: tx(12, FontWeight.w400,
                    selected ? _textMuted : _textDim)),
          ],
        )),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: selected ? 1 : 0,
          child: const Icon(Icons.check_circle_outline_rounded,
              color: _green, size: 20),
        ),
      ]),
    ),
  );
}