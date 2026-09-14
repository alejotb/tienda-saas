import 'package:baul_pandora/repositories/inventory_repository.dart';
import 'package:baul_pandora/models/inventory_models.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';

class CloudInventoryRepository implements IInventoryRepository {
  @override
  Future<void> sync() async {
    // En modo nube, la "sincronización" es simplemente hacer el fetch
    print("🌐 Modo Nube: No se requiere sincronización local.");
  }

  @override
  Future<List<LocalProduct>> getProducts() async {
    final cloudProducts = await ProductosTable().queryRows(queryFn: (q) => q);
    
    // Convertimos los productos de Supabase al formato LocalProduct para no romper la UI
    return cloudProducts.map((p) => LocalProduct(
      id: p.id ?? '',
      nombre: p.nombre ?? 'Sin nombre',
      stock: p.stock ?? 0,
      precio: p.precio,
      supabaseId: p.id,
      name: p.nombre,
      stockActual: p.stock ?? 0,
      price: p.precio,
    )).toList();
  }

  @override
  Future<void> updateStock({
    required String productId,
    required int delta,
    required String reason,
    required String type,
  }) async {
    print("☁️ Sincronizando delta en la nube: $productId | Delta: $delta");
    
    try {
      // USAMOS RPC para un incremento atómico. 
      // Evitamos el .update() directo porque causaría Race Conditions.
      await SupaFlow.client.rpc('increment_stock', params: {
        'product_id': productId,
        'delta_value': delta,
      });
      
      // Aquí también deberíamos insertar el log en la tabla de auditoría de Supabase
      await SupaFlow.client.from('stock_logs').insert({
        'product_id': productId,
        'delta': delta,
        'reason': reason,
        'type': type,
        'admin_id': currentUserUid,
      });
      
    } catch (e) {
      print("❌ Error sincronizando stock en nube: $e");
      rethrow;
    }
  }

  @override
  Future<LocalProduct?> getProductById(String id) async {
    final rows = await ProductosTable().queryRows(queryFn: (q) => q.eq('id', id));
    if (rows.isEmpty) return null;
    
    final p = rows.first;
    return LocalProduct()
      ..supabaseId = p.id
      ..name = p.nombre
      ..stockActual = p.stock ?? 0
      ..price = p.precio;
  }

  @override
  Future<List<LocalStockLog>> getStockLogs() async {
    final logs = await SupaFlow.client
        .from('stock_logs')
        .select()
        .order('created_at', ascending: false);
    
    return logs.map((l) => LocalStockLog(
      productId: l['product_id'],
      adminId: l['admin_id'],
      delta: l['delta'] ?? 0,
      type: l['type'],
      reason: l['reason'],
      createdAt: DateTime.parse(l['created_at']),
      isSynced: true,
    )).toList();
  }
}