import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
static const baseUrl = 'http://192.168.18.186:8000';
  static const _storage = FlutterSecureStorage();

  static Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  static Future<void> guardarToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  static Future<void> cerrarSesion() async {
    await _storage.delete(key: 'token');
  }

  static Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<dynamic> get(String path, {bool auth = false}) async {
    final res = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
    );
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body,
      {bool auth = false}) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body,
      {bool auth = false}) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return jsonDecode(utf8.decode(res.bodyBytes));
  }




  static Future<void> subirDocumento(
    String usuarioId, File archivo, String tipo) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('$baseUrl/documentos/subir?usuario_id=$usuarioId&tipo=$tipo'),
  );
  request.files.add(await http.MultipartFile.fromPath(
    'archivo', archivo.path,
  ));
  await request.send();
}    
static Future<dynamic> getUri(String url, {bool auth = false}) async {
    final res = await http.get(
      Uri.parse(url),
      headers: await _headers(auth: auth),
    );
    return jsonDecode(utf8.decode(res.bodyBytes));
  }
} 
