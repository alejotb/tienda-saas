// Automatic FlutterFlow imports
import 'package:baul_pandora/backend/supabase/supabase.dart';
// Imports other custom actions
// Imports custom functions
import 'sync_dtos.dart'; // Import the DTOs
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future syncOrders(List<dynamic>? wooOrdersJson) async {
  if (wooOrdersJson == null || wooOrdersJson.isEmpty) {
    print("No hay pedidos para sincronizar.");
    return;
  }

  final supabase = Supabase.instance.client;

  try {
    // 1. MAPEO: Convertimos la data cruda a DTOs y luego a mapas de Supabase.
    final ordersToSync = wooOrdersJson
        .map((json) => WooOrderDto.fromJson(json as Map<String, dynamic>))
        .map((dto) => dto.toSupabaseMap())
        .toList();

    // 2. BATCH UPSERT con CHUNKING (Batch size: 100)
    const int batchSize = 100;
    for (var i = 0; i < ordersToSync.length; i += batchSize) {
      final end = (i + batchSize < ordersToSync.length) 
          ? i + batchSize 
          : ordersToSync.length;
      
      final batch = ordersToSync.sublist(i, end);
      
      await supabase
          .from('pedidos')
          .upsert(batch, onConflict: 'id_woo');
          
      print("Procesado lote de pedidos: ${i + 1} a $end");
    }

    print("Sincronización masiva de pedidos exitosa: ${ordersToSync.length} procesados.");
  } catch (e) {
    print("ERROR CRÍTICO en syncOrders: $e");
  }
}
