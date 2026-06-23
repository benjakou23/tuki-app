import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UbicacionService {
 static SupabaseClient get _supabase => Supabase.instance.client;
 static SupabaseClient get supabase => Supabase.instance.client;

  static Future<Position?> obtenerUbicacion() async {
    bool servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) return null;

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) return null;
    }
    if (permiso == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Técnico actualiza su posición en Supabase Realtime
  static Future<void> actualizarPosicionTecnico({
    required String tecnicoId,
    required double lat,
    required double lng,
    required bool disponible,
  }) async {
    await _supabase.from('ubicaciones_tecnicos').upsert({
      'tecnico_id': tecnicoId,
      'lat': lat,
      'lng': lng,
      'disponible': disponible,
      'actualizado_en': DateTime.now().toIso8601String(),
    }, onConflict: 'tecnico_id');
  }

  // Cliente escucha técnicos disponibles en tiempo real
  static RealtimeChannel escucharTecnicos({
    required Function(List<Map<String, dynamic>>) onUpdate,
  }) {
    final channel = _supabase.channel('tecnicos_disponibles');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'ubicaciones_tecnicos',
      callback: (payload) async {
        final data = await _supabase
          .from('ubicaciones_tecnicos')
          .select()
          .eq('disponible', true);
        onUpdate(List<Map<String, dynamic>>.from(data));
      },
    ).subscribe();

    return channel;
  }

  // Calcular distancia entre dos puntos (km)
  static double calcularDistancia(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }
}