import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/auth_provider.dart';

// ── Paleta dark (consistente con el sistema) ──────────────────────────────────
const _bg        = Color(0xFF0D0F14);
const _surface   = Color(0x0AFFFFFF);   // 4%
const _surfaceHi = Color(0x14FFFFFF);   // 8%
const _border    = Color(0x14FFFFFF);
const _blue      = Color(0xFF2563EB);
const _blueLight = Color(0xFF60A5FA);
const _blueDim   = Color(0x1A60A5FA);
const _textPri   = Color(0xFFFFFFFF);
const _textMid   = Color(0x99FFFFFF);   // 60%
const _textDim   = Color(0x38FFFFFF);   // 22%

// Burbuja propia: azul sólido. Burbuja ajena: superficie oscura.
const _bubbleMine  = Color(0xFF1D4ED8);  // blue-700 — sólido, legible
const _bubbleOther = Color(0xFF161920);  // superficie elevada

class ChatScreen extends StatefulWidget {
  final String pedidoId;
  final String otroNombre;
  const ChatScreen({
    super.key,
    required this.pedidoId,
    required this.otroNombre,
  });
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabase      = Supabase.instance.client;
  final _textoCtrl     = TextEditingController();
  final _scrollCtrl    = ScrollController();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer   = AudioPlayer();

  List<Map<String, dynamic>> _mensajes = [];
  RealtimeChannel? _canal;
  bool _grabando  = false;
  bool _enviando  = false;
  String? _rutaAudio;
  String? _reproduciendo;
  Map<String, Duration> _duraciones = {};
  Map<String, Duration> _posiciones = {};

  TextStyle _tx(double s, FontWeight w, Color c, {double? ls, double? h}) =>
      GoogleFonts.inter(
          fontSize: s, fontWeight: w, color: c,
          letterSpacing: ls ?? 0, height: h);

  @override
  void initState() {
    super.initState();
    _cargarMensajes();
    _suscribir();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) setState(() => _reproduciendo = null);
    });
    _audioPlayer.onPositionChanged.listen((pos) {
      if (_reproduciendo != null) setState(() => _posiciones[_reproduciendo!] = pos);
    });
    _audioPlayer.onDurationChanged.listen((dur) {
      if (_reproduciendo != null) setState(() => _duraciones[_reproduciendo!] = dur);
    });
  }

  @override
  void dispose() {
    _canal?.unsubscribe();
    _textoCtrl.dispose();
    _scrollCtrl.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _cargarMensajes() async {
    try {
      final data = await _supabase
          .from('mensajes')
          .select()
          .eq('pedido_id', widget.pedidoId)
          .order('creado_en', ascending: true);
      if (mounted) {
        setState(() => _mensajes = List<Map<String, dynamic>>.from(data));
        _scrollAbajo();
      }
    } catch (e) { debugPrint('Error mensajes: $e'); }
  }

  void _suscribir() {
    _canal = _supabase
        .channel('chat_${widget.pedidoId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'mensajes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'pedido_id',
            value: widget.pedidoId,
          ),
          callback: (payload) {
            if (mounted) {
              setState(() => _mensajes
                  .add(Map<String, dynamic>.from(payload.newRecord)));
              _scrollAbajo();
            }
          },
        )
        .subscribe();
  }

  void _scrollAbajo() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _enviarTexto() async {
    final texto = _textoCtrl.text.trim();
    if (texto.isEmpty) return;
    _textoCtrl.clear();
    final userId = context.read<AuthProvider>().usuarioId;
    await _supabase.from('mensajes').insert({
      'pedido_id': widget.pedidoId,
      'remitente_id': userId,
      'tipo': 'texto',
      'contenido': texto,
    });
  }

  Future<void> _enviarImagen() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    setState(() => _enviando = true);
    try {
      final userId = context.read<AuthProvider>().usuarioId;
      final bytes  = await picked.readAsBytes();
      final nombre = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path   = '$userId/$nombre';
      await _supabase.storage.from('chat-archivos').uploadBinary(
          path, bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'));
      final url = _supabase.storage.from('chat-archivos').getPublicUrl(path);
      await _supabase.from('mensajes').insert({
        'pedido_id': widget.pedidoId,
        'remitente_id': userId,
        'tipo': 'imagen',
        'url_archivo': url,
      });
    } catch (e) { debugPrint('Error imagen: $e'); }
    finally { if (mounted) setState(() => _enviando = false); }
  }

  Future<void> _iniciarGrabacion() async {
    if (!await _audioRecorder.hasPermission()) return;
    final dir = await getTemporaryDirectory();
    _rutaAudio =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _rutaAudio!);
    setState(() => _grabando = true);
  }

  Future<void> _detenerGrabacion() async {
    if (!_grabando) return;
    final path = await _audioRecorder.stop();
    setState(() => _grabando = false);
    if (path == null) return;
    setState(() => _enviando = true);
    try {
      final userId = context.read<AuthProvider>().usuarioId;
      final bytes  = await File(path).readAsBytes();
      final nombre = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final ruta   = '$userId/$nombre';
      await _supabase.storage.from('chat-archivos').uploadBinary(
          ruta, bytes,
          fileOptions: const FileOptions(contentType: 'audio/mp4'));
      final url = _supabase.storage.from('chat-archivos').getPublicUrl(ruta);
      await _supabase.from('mensajes').insert({
        'pedido_id': widget.pedidoId,
        'remitente_id': userId,
        'tipo': 'audio',
        'url_archivo': url,
      });
    } catch (e) { debugPrint('Error audio: $e'); }
    finally { if (mounted) setState(() => _enviando = false); }
  }

  Future<void> _reproducirAudio(String url, String id) async {
    if (_reproduciendo == id) {
      await _audioPlayer.pause();
      setState(() => _reproduciendo = null);
      return;
    }
    setState(() {
      _reproduciendo = id;
      _posiciones[id] = Duration.zero;
    });
    await _audioPlayer.play(UrlSource(url));
  }

  String _fmtDur(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Iniciales del contacto ────────────────────────────────────────────────
  String get _iniciales {
    final partes = widget.otroNombre.trim().split(' ');
    if (partes.length >= 2) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return widget.otroNombre.isNotEmpty
        ? widget.otroNombre[0].toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthProvider>().usuarioId ?? '';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(child: _buildMensajes(userId)),
          _buildBarra(),
        ]),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Container(
    color: _bg,
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
    child: Row(children: [
      _IconBtn(
        icon: Icons.arrow_back_ios_new_rounded,
        onTap: () => Navigator.pop(context),
      ),
      const SizedBox(width: 12),
      // Avatar
      Container(
        width: 38, height: 38,
        decoration: const BoxDecoration(
            color: _blue, shape: BoxShape.circle),
        child: Center(
          child: Text(_iniciales,
              style: _tx(13, FontWeight.w500, Colors.white)),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.otroNombre,
              style: _tx(14, FontWeight.w500, _textPri, ls: -0.2)),
          const SizedBox(height: 2),
          Row(children: [
            Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                    color: Color(0xFF34D399), shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('En línea', style: _tx(11, FontWeight.w400, _textDim)),
          ]),
        ]),
      ),
    ]),
  );

  // ── Lista de mensajes ─────────────────────────────────────────────────────
  Widget _buildMensajes(String userId) {
    if (_mensajes.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
                color: _surfaceHi,
                shape: BoxShape.circle,
                border: Border.all(color: _border)),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: _blueLight, size: 24),
          ),
          const SizedBox(height: 14),
          Text('Sin mensajes aún',
              style: _tx(14, FontWeight.w500, _textMid)),
          const SizedBox(height: 4),
          Text('Coordina los detalles del servicio',
              style: _tx(12, FontWeight.w400, _textDim)),
        ]),
      );
    }

    // Agrupar por fecha
    final agrupados = <String, List<Map<String, dynamic>>>{};
    for (final m in _mensajes) {
      final key = _labelFecha(m['creado_en']);
      agrupados.putIfAbsent(key, () => []).add(m);
    }

    return ListView(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      children: agrupados.entries.expand((entry) {
        return [
          _DateDivider(label: entry.key),
          ...entry.value.map((m) {
            final esMio = m['remitente_id'] == userId;
            return _BurbujaMensaje(
              mensaje: m,
              esMio: esMio,
              iniciales: _iniciales,
              reproduciendo: _reproduciendo == m['id'],
              posicion: _posiciones[m['id']] ?? Duration.zero,
              duracion: _duraciones[m['id']],
              onReproducir: () =>
                  _reproducirAudio(m['url_archivo'], m['id']),
              fmtDur: _fmtDur,
            );
          }),
        ];
      }).toList(),
    );
  }

  String _labelFecha(String? ts) {
    if (ts == null) return '';
    try {
      final dt  = DateTime.parse(ts).toLocal();
      final hoy = DateTime.now();
      if (dt.year == hoy.year &&
          dt.month == hoy.month &&
          dt.day == hoy.day) return 'Hoy';
      final ayer = hoy.subtract(const Duration(days: 1));
      if (dt.year == ayer.year &&
          dt.month == ayer.month &&
          dt.day == ayer.day) return 'Ayer';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }

  // ── Barra de entrada ──────────────────────────────────────────────────────
  Widget _buildBarra() => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
    decoration: BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _border))),
    child: Row(children: [
      // Imagen
      _IconBtn(
        icon: Icons.image_outlined,
        onTap: _enviando ? null : _enviarImagen,
        faded: _enviando,
      ),
      const SizedBox(width: 8),

      // Campo texto
      Expanded(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 100),
          decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                  color: _grabando
                      ? const Color(0x28FBBF24)
                      : _border)),
          child: Row(children: [
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _textoCtrl,
                maxLines: null,
                style: _tx(14, FontWeight.w400, _textPri),
                cursorColor: _blueLight,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: _grabando
                      ? 'Grabando...'
                      : 'Escribe un mensaje...',
                  hintStyle: _tx(14, FontWeight.w400,
                      _grabando
                          ? const Color(0x99FBBF24)
                          : _textDim),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 11),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ]),
        ),
      ),
      const SizedBox(width: 8),

      // Enviar / Micrófono
      ValueListenableBuilder(
        valueListenable: _textoCtrl,
        builder: (_, val, __) {
          final tieneTexto = val.text.trim().isNotEmpty;
          if (tieneTexto) {
            return _SendBtn(onTap: _enviarTexto);
          }
          return _MicBtn(
            grabando: _grabando,
            onLongPressStart: (_) => _iniciarGrabacion(),
            onLongPressEnd:   (_) => _detenerGrabacion(),
          );
        },
      ),
    ]),
  );
}

// ── Separador de fecha ────────────────────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final String label;
  const _DateDivider({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(children: [
      Expanded(child: Container(height: 1,
          color: const Color(0x0AFFFFFF))),
      const SizedBox(width: 10),
      Text(label,
          style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: const Color(0x38FFFFFF))),
      const SizedBox(width: 10),
      Expanded(child: Container(height: 1,
          color: const Color(0x0AFFFFFF))),
    ]),
  );
}

// ── Burbuja de mensaje ────────────────────────────────────────────────────────
class _BurbujaMensaje extends StatelessWidget {
  final Map<String, dynamic> mensaje;
  final bool esMio;
  final String iniciales;
  final bool reproduciendo;
  final Duration posicion;
  final Duration? duracion;
  final VoidCallback onReproducir;
  final String Function(Duration) fmtDur;

  const _BurbujaMensaje({
    required this.mensaje,
    required this.esMio,
    required this.iniciales,
    required this.reproduciendo,
    required this.posicion,
    required this.duracion,
    required this.onReproducir,
    required this.fmtDur,
  });

  String _hora(String? ts) {
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final tipo  = mensaje['tipo'] as String? ?? 'texto';
    final hora  = _hora(mensaje['creado_en']);
    final esImg = tipo == 'imagen';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            esMio ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar del otro
          if (!esMio) ...[
            Container(
              width: 26, height: 26,
              decoration: const BoxDecoration(
                  color: _blue, shape: BoxShape.circle),
              child: Center(
                child: Text(iniciales,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(width: 6),
          ],

          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.70),
              child: Container(
                padding: esImg
                    ? EdgeInsets.zero
                    : EdgeInsets.symmetric(
                        horizontal: tipo == 'audio' ? 12 : 13,
                        vertical:   tipo == 'audio' ? 10 : 10),
                decoration: BoxDecoration(
                  color: esMio ? _bubbleMine : _bubbleOther,
                  borderRadius: BorderRadius.only(
                    topLeft:     const Radius.circular(18),
                    topRight:    const Radius.circular(18),
                    bottomLeft:  Radius.circular(esMio ? 18 : 4),
                    bottomRight: Radius.circular(esMio ? 4 : 18),
                  ),
                  border: esMio
                      ? null
                      : Border.all(color: const Color(0x14FFFFFF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Texto ──────────────────────────────────────
                    if (tipo == 'texto')
                      Text(mensaje['contenido'] ?? '',
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: esMio
                                  ? Colors.white
                                  : const Color(0xCCFFFFFF),
                              height: 1.45)),

                    // ── Imagen ─────────────────────────────────────
                    if (tipo == 'imagen' &&
                        mensaje['url_archivo'] != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          mensaje['url_archivo'],
                          width: 220, height: 180,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, prog) =>
                              prog == null
                                  ? child
                                  : Container(
                                      width: 220, height: 180,
                                      color: const Color(0x14FFFFFF),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: _blueLight))),
                        ),
                      ),

                    // ── Audio ──────────────────────────────────────
                    if (tipo == 'audio')
                      _BurbujaAudio(
                        esMio: esMio,
                        reproduciendo: reproduciendo,
                        posicion: posicion,
                        duracion: duracion,
                        onReproducir: onReproducir,
                        fmtDur: fmtDur,
                      ),

                    // ── Hora ───────────────────────────────────────
                    if (!esImg) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(hora,
                            style: GoogleFonts.inter(
                                fontSize: 10,
                                color: esMio
                                    ? Colors.white
                                          .withValues(alpha: 0.5)
                                    : const Color(0x38FFFFFF))),
                      ),
                    ],

                    // Hora sobre imagen
                    if (esImg)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 5, 10, 8),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Text(hora,
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white
                                      .withValues(alpha: 0.7))),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          if (esMio) const SizedBox(width: 6),
        ],
      ),
    );
  }
}

// ── Burbuja de audio ──────────────────────────────────────────────────────────
class _BurbujaAudio extends StatelessWidget {
  final bool esMio;
  final bool reproduciendo;
  final Duration posicion;
  final Duration? duracion;
  final VoidCallback onReproducir;
  final String Function(Duration) fmtDur;

  const _BurbujaAudio({
    required this.esMio,
    required this.reproduciendo,
    required this.posicion,
    required this.duracion,
    required this.onReproducir,
    required this.fmtDur,
  });

  @override
  Widget build(BuildContext context) {
    final total   = duracion?.inMilliseconds ?? 1;
    final progreso = total > 0
        ? (posicion.inMilliseconds / total).clamp(0.0, 1.0)
        : 0.0;

    final trackBg  = esMio
        ? Colors.white.withValues(alpha: 0.20)
        : const Color(0x14FFFFFF);
    final trackFg  = esMio ? Colors.white : _blueLight;
    final iconColor = esMio ? Colors.white : _blueLight;
    final btnBg    = esMio
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0x1A60A5FA);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onReproducir,
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: btnBg, shape: BoxShape.circle),
            child: Icon(
              reproduciendo
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              size: 20, color: iconColor),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progreso.toDouble(),
                  backgroundColor: trackBg,
                  color: trackFg,
                  minHeight: 3,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reproduciendo
                  ? fmtDur(posicion)
                  : duracion != null ? fmtDur(duracion!) : '0:00',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: esMio
                    ? Colors.white.withValues(alpha: 0.55)
                    : const Color(0x38FFFFFF)),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Botón icono ───────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool faded;
  const _IconBtn({required this.icon, this.onTap, this.faded = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: const Color(0x14FFFFFF))),
      child: Icon(icon, size: 17,
          color: faded
              ? const Color(0x28FFFFFF)
              : const Color(0x61FFFFFF)),
    ),
  );
}

// ── Botón enviar ──────────────────────────────────────────────────────────────
class _SendBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _SendBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: const BoxDecoration(
          color: _blue, shape: BoxShape.circle),
      child: const Icon(Icons.send_rounded,
          color: Colors.white, size: 17),
    ),
  );
}

// ── Botón micrófono ───────────────────────────────────────────────────────────
class _MicBtn extends StatelessWidget {
  final bool grabando;
  final void Function(LongPressStartDetails) onLongPressStart;
  final void Function(LongPressEndDetails) onLongPressEnd;
  const _MicBtn({
    required this.grabando,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onLongPressStart: onLongPressStart,
    onLongPressEnd:   onLongPressEnd,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 38, height: 38,
      decoration: BoxDecoration(
          color: grabando
              ? const Color(0xFFFBBF24)
              : const Color(0x0AFFFFFF),
          shape: BoxShape.circle,
          border: Border.all(
              color: grabando
                  ? const Color(0x00000000)
                  : const Color(0x14FFFFFF))),
      child: Icon(
        grabando ? Icons.stop_rounded : Icons.mic_rounded,
        color: grabando ? const Color(0xFF1A0F00) : const Color(0x61FFFFFF),
        size: 18),
    ),
  );
}