import 'package:baul_pandora/models/inventory_models.dart';

class LocalInventoryService {
  static final LocalInventoryService instance = LocalInventoryService._internal();
  LocalInventoryService._internal();

  Future<void> syncProductsFromCloud() async {}
  
  Future<List<LocalProduct>> getLocalProducts() async {
    return [];
  }
  
  Future<void> updateStockLocal({
    required String productId,
    required int delta,
    String? reason,
    String? type,
  }) async {}

  Future<void> syncPendingLogs() async {}

  Future<LocalProduct?> getProductById(String supabaseId) async {
    return null;
  }

  Future<List<LocalStockLog>> getLocalStockLogs() async {
    return [];
  }
}
