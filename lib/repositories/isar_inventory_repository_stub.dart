// lib/repositories/isar_inventory_repository_stub.dart
import 'inventory_repository.dart';
import 'package:baul_pandora/models/inventory_models.dart';
// Stub que no hace nada en Web
class IsarInventoryRepository implements IInventoryRepository {
  @override
  Future<LocalProduct?> getProductById(String id) async => null;
  @override
  Future<List<LocalStockLog>> getStockLogs() async => [];
  
  @override
  Future<List<LocalProduct>> getProducts() async => [];

  @override
  Future<void> sync() async {}

  @override
  Future<void> updateStock({
    required String productId,
    required int delta,
    String? reason,
    String? type,
  }) async {}
}
