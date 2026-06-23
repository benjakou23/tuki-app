import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'notificaciones_service.dart';

class AuthProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();

  Map<String, dynamic>? _usuario;
  bool _cargando = false;

  Map<String, dynamic>? get usuario => _usuario;
  bool get cargando => _cargando;
  bool get autenticado => _usuario != null;
  String? get rol => _usuario?['rol'];
  String? get usuarioId => _usuario?['id'];
  String? get estadoVerificacion => _usuario?['estado_verificacion'];
  bool get estaVerificado => estadoVerificacion == 'verificado';
  bool get estaEnRevision =>
      estadoVerificacion == 'docs_enviados' ||
      estadoVerificacion == 'en_revision';

  Future<void> cargarSesion() async {
    try {
      final token = await ApiClient.getToken();
      if (token == null) return;
      final res = await ApiClient.get('/usuarios/me', auth: true);
      if (res != null && res['id'] != null) {
        _usuario = res;
        notifyListeners();
        // Actualizar FCM token al cargar sesión
        _guardarFcmToken();
      }
    } catch (e) {
      debugPrint('ERROR CARGAR SESION: $e');
      await ApiClient.cerrarSesion();
    }
  }

  Future<void> _guardarFcmToken() async {
    try {
      final fcmToken = await NotificacionesService.obtenerToken();
      if (fcmToken != null) {
        await ApiClient.patch('/usuarios/actualizar',
          {'fcm_token': fcmToken}, auth: true);
        debugPrint('FCM token guardado: $fcmToken');
      }
    } catch (e) {
      debugPrint('Error guardando FCM token: $e');
    }
  }

  Future<bool> registrar(Map<String, dynamic> datos) async {
    if (_cargando) return false;
    _cargando = true;
    notifyListeners();
    try {
      final res = await ApiClient.post('/usuarios/registro', datos);
      if (res != null && res['access_token'] != null) {
        await ApiClient.guardarToken(res['access_token']);
        await _storage.write(
            key: 'usuario_id', value: res['usuario']['id']);
        _usuario = Map<String, dynamic>.from(res['usuario']);
        _cargando = false;
        notifyListeners();
        return true;
      }
      _cargando = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('ERROR REGISTRO: $e');
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String telefono, String password) async {
    if (_cargando) return false;
    _cargando = true;
    notifyListeners();
    try {
      final res = await ApiClient.post('/usuarios/login', {
        'telefono': telefono,
        'password': password,
      });
      if (res != null && res['access_token'] != null) {
        await ApiClient.guardarToken(res['access_token']);
        await _storage.write(
            key: 'usuario_id', value: res['usuario']['id']);
        _usuario = Map<String, dynamic>.from(res['usuario']);
        _cargando = false;
        notifyListeners();
        // Guardar FCM token después del login
        _guardarFcmToken();
        return true;
      }
      _cargando = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('ERROR LOGIN: $e');
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refrescarUsuario() async {
    try {
      final res = await ApiClient.get('/usuarios/me', auth: true);
      if (res != null && res['id'] != null) {
        _usuario = Map<String, dynamic>.from(res);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('ERROR REFRESCAR: $e');
    }
  }

  Future<void> cerrarSesion() async {
    await ApiClient.cerrarSesion();
    await _storage.delete(key: 'usuario_id');
    _usuario = null;
    _cargando = false;
    notifyListeners();
  }
}