import 'package:baul_pandora/models/inventory_models.dart';

/// Interface que define cómo se debe comportar cualquier sistema de inventario
/// sea local (Isar) o remoto (Supabase/API).
abstract class IInventoryRepository {
  /// Sincroniza los datos locales con la nube (si aplica)
  Future<void> sync();

  /// Obtiene la lista de productos
  Future<List<LocalProduct>> getProducts();

  /// Actualiza la cantidad de un producto
  Future<void> updateStock({
    required String productId,
    required int delta,
    required String reason,
    required String type,
  });

  /// Obtiene un producto específico por su ID de Supabase
  Future<LocalProduct?> getProductById(String id);

  /// Obtiene el historial de movimientos de stock (Auditoría)
  Future<List<LocalStockLog>> getStockLogs();
}