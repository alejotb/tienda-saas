import 'package:baul_pandora/backend/supabase/supabase.dart';

class AdminService {
  static final AdminService instance = AdminService._internal();
  AdminService._internal();

  /// Cambia el estado de un pedido a 'confirmado'.
  /// Se usa tanto para pedidos normales como para apartados.
  Future<bool> confirmOrder(String pedidoId) async {
    try {
      await SupaFlow.client
          .from('pedidos')
          .update({'status': 'confirmado'})
          .eq('id', pedidoId);
      return true;
    } catch (e) {
      print('Error confirming order $pedidoId: $e');
      return false;
    }
  }

  /// Cambia el estado de un pedido a 'cancelado' (rechazado).
  Future<bool> rejectOrder(String pedidoId, {String? reason}) async {
    try {
      // First, fetch the current datos_pago to merge the reason
      final order = await SupaFlow.client.from('pedidos').select('datos_pago').eq('id', pedidoId).maybeSingle();
      final datosPago = (order != null && order['datos_pago'] != null) ? Map<String, dynamic>.from(order['datos_pago']) : <String, dynamic>{};
      
      if (reason != null) {
        datosPago['motivo_rechazo'] = reason;
      }
      
      await SupaFlow.client
          .from('pedidos')
          .update({
            'status': 'rechazado',
            'estado': 'rechazado',
            'datos_pago': datosPago
          })
          .eq('id', pedidoId);
      return true;
    } catch (e) {
      print('Error rejecting order $pedidoId: $e');
      return false;
    }
  }

  /// Cambia el estado de un pedido a 'completado' (entregado).
  Future<bool> markAsDelivered(String pedidoId) async {
    try {
      await SupaFlow.client
          .from('pedidos')
          .update({'status': 'completado'})
          .eq('id', pedidoId);
      return true;
    } catch (e) {
      print('Error marking order as delivered $pedidoId: $e');
      return false;
    }
  }

  /// Recupera pedidos filtrados por un status específico o una lista de ellos,
  /// e integra los datos del comprobante y pagos desde la tabla 'pagos'.
  Future<List<PedidosRow>> getOrdersByStatus(dynamic status) async {
    try {
      final rows = await PedidosTable().queryRows(
        queryFn: (q) {
          if (status is List<String>) {
            return q.inFilter('status', status);
          } else {
            return q.eq('status', status as String);
          }
        },
      );

      if (rows.isNotEmpty) {
        try {
          final pedidoIds = rows.map((r) => r.id).toList();
          final pagosList = await SupaFlow.client
              .from('pagos')
              .select()
              .filter('pedido_id', 'in', pedidoIds);

          final Map<String, Map<String, dynamic>> pagosByPedido = {};
          for (var p in (pagosList as List)) {
            if (p is Map && p['pedido_id'] != null) {
              pagosByPedido[p['pedido_id'].toString()] = Map<String, dynamic>.from(p);
            }
          }

          for (var row in rows) {
            final pago = pagosByPedido[row.id];
            if (pago != null) {
              final currentDatos = row.datosPago is Map
                  ? Map<String, dynamic>.from(row.datosPago as Map)
                  : <String, dynamic>{};

              if (pago['comprobante_url'] != null && currentDatos['comprobante_url'] == null) {
                currentDatos['comprobante_url'] = pago['comprobante_url'];
              }
              if (pago['ai_data'] != null && currentDatos['ai_data'] == null) {
                currentDatos['ai_data'] = pago['ai_data'];
              }
              if (pago['referencia'] != null && (currentDatos['referencia'] == null || currentDatos['referencia'] == '')) {
                currentDatos['referencia'] = pago['referencia'];
              }
              if (pago['amount_ves'] != null && currentDatos['montoVes'] == null) {
                currentDatos['montoVes'] = pago['amount_ves'];
              }
              if (pago['exchange_rate_applied'] != null && currentDatos['tasaAplicada'] == null) {
                currentDatos['tasaAplicada'] = pago['exchange_rate_applied'];
              }
              if (pago['banco_emisor'] != null && currentDatos['bancoEnviado'] == null) {
                currentDatos['bancoEnviado'] = pago['banco_emisor'];
              }
              if (pago['telefono_emisor'] != null && currentDatos['numeroTelefono'] == null) {
                currentDatos['numeroTelefono'] = pago['telefono_emisor'];
              }

              row.datosPago = currentDatos;
            }
          }
        } catch (pagoError) {
          print('Nota: No se pudo adjuntar datos adicionales de pagos: $pagoError');
        }
      }

      return rows;
    } catch (e) {
      print('Error fetching orders by status $status: $e');
      return [];
    }
  }

  /// Método helper para obtener los status críticos del dashboard
  static const List<String> statusNormalConfirm = ['pendiente', 'pagado', 'pendiente_pago'];
  static const List<String> statusApartadoConfirm = ['pendiente_apartados', 'apartado'];
  static const String statusConfirmed = 'confirmado';
  static const String statusCompleted = 'completado';
}
