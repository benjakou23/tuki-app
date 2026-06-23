import 'package:supabase_flutter/supabase_flutter.dart';

class OfertasService {
  static final _supabase = Supabase.instance.client;

  // Técnico lanza oferta
  static Future<Map<String, dynamic>> crearOferta({
    required String pedidoId,
    required String tecnicoId,
    required String clienteId,
    required double monto,
    required String tipo, // 'oferta' | 'contraoferta'
  }) async {
    final res = await _supabase.from('ofertas').insert({
      'pedido_id': pedidoId,
      'tecnico_id': tecnicoId,
      'cliente_id': clienteId,
      'monto': monto,
      'tipo': tipo,
      'estado': 'pendiente',
    }).select().single();
    return res;
  }

  // Aceptar o rechazar oferta
  static Future<void> responderOferta({
    required String ofertaId,
    required String estado, // 'aceptada' | 'rechazada'
  }) async {
    await _supabase.from('ofertas')
      .update({'estado': estado})
      .eq('id', ofertaId);
  }

  // Escuchar ofertas de un pedido en tiempo real
  static RealtimeChannel escucharOfertas({
    required String pedidoId,
    required Function(List<Map<String, dynamic>>) onUpdate,
  }) {
    final channel = _supabase.channel('ofertas_$pedidoId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'ofertas',
      filter: PostgresChangeFilter(
        type: FilterType.eq,
        column: 'pedido_id',
        value: pedidoId,
      ),
      callback: (payload) async {
        final data = await _supabase
          .from('ofertas')
          .select()
          .eq('pedido_id', pedidoId)
          .order('creado_en', ascending: false);
        onUpdate(List<Map<String, dynamic>>.from(data));
      },
    ).subscribe();

    return channel;
  }
}