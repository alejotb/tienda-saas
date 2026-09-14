import 'package:baul_pandora/repositories/inventory_repository.dart';
import 'package:baul_pandora/services/local_inventory_service.dart';
import 'package:baul_pandora/models/inventory_models.dart';

class IsarInventoryRepository implements IInventoryRepository {
  final _localService = LocalInventoryService.instance;

  @override
  Future<void> sync() async {
    await _localService.syncProductsFromCloud();
  }

  @override
  Future<List<LocalProduct>> getProducts() async {
    final isarProducts = await _localService.getLocalProducts();
    return isarProducts.map((p) => LocalProduct(
      id: p.id,
      nombre: p.nombre,
      stock: p.stock,
      precio: p.precio,
      supabaseId: p.supabaseId,
      name: p.name,
      stockActual: p.stockActual,
      price: p.price,
      lastSynced: p.lastSynced,
    )).toList();
  }

  @override
  Future<void> updateStock({
    required String productId,
    required int delta,
    required String reason,
    required String type,
  }) async {
    await _localService.updateStockLocal(
      productId: productId,
      delta: delta,
      reason: reason,
      type: type,
    );
  }

  @override
  Future<LocalProduct?> getProductById(String id) async {
    final p = await _localService.getProductById(id);
    if (p == null) return null;
    return LocalProduct(
      id: p.id,
      nombre: p.nombre,
      stock: p.stock,
      precio: p.precio,
      supabaseId: p.supabaseId,
      name: p.name,
      stockActual: p.stockActual,
      price: p.price,
      lastSynced: p.lastSynced,
    );
  }

  @override
  Future<List<LocalStockLog>> getStockLogs() async {
    final isarLogs = await _localService.getLocalStockLogs();
    return isarLogs.map((l) => LocalStockLog(
      productId: l.productId,
      adminId: l.adminId,
      delta: l.delta,
      type: l.type,
      reason: l.reason,
      createdAt: l.createdAt,
      isSynced: l.isSynced,
    )).toList();
  }
}