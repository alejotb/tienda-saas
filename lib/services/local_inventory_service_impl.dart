import 'package:isar/isar.dart';
import 'package:baul_pandora/services/isar_service.dart';
import 'package:baul_pandora/models/isar/local_inventory_models.dart' as isar_model;
import 'package:baul_pandora/models/inventory_models.dart' as bridge;
import 'package:baul_pandora/repositories/inventory_factory.dart';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';

class LocalInventoryService {
  static final LocalInventoryService instance = LocalInventoryService._internal();
  LocalInventoryService._internal();

  // Acceso rápido a la instancia de Isar
  Isar get _isar => IsarService.instance.isar;

  /// 1. SINCRONIZACIÓN: Baja productos del repositorio actual y los guarda en Isar
  Future<void> syncProductsFromCloud() async {
    try {
      print("🔄 Sincronizando productos desde el repositorio...");
      
      // USAMOS EL FACTORY: No nos importa si vienen de Supabase o de donde sea
      final repo = InventoryFactory.getRepository();
      final cloudProducts = await repo.getProducts();
      
      // Abrimos una transacción para que la escritura sea atómica y rápida
      await _isar.writeTxn(() async {
        for (var product in cloudProducts) {
          // Convertimos del modelo abstracto a Isar local
          final localProduct = isar_model.LocalProduct()
            ..supabaseId = product.id
            ..name = product.nombre
            ..stockActual = product.stock
            ..price = product.precio
            ..lastSynced = DateTime.now();
          
          // .put() inserta si no existe o actualiza si ya existe (gracias al @Index unique)
          await _isar.localProducts.put(localProduct);
        }
      });
      
      print("✅ Sincronización completada. ${cloudProducts.length} productos cacheados.");
    } catch (e) {
      print("❌ Error en syncProductsFromCloud: $e");
      rethrow;
    }
  }

  /// 2. LECTURA: Obtiene la lista de productos desde la base local
  Future<List<isar_model.LocalProduct>> getLocalProducts() async {
    return await _isar.localProducts.where().findAll();
  }

  /// 3. ACTUALIZACIÓN OFFLINE: Cambia el stock y crea el log
  Future<void> updateStockLocal({
    required String productId,
    required int delta,
    required String reason,
    required String type,
  }) async {
    try {
      await _isar.writeTxn(() async {
        // A. Buscar el producto localmente por su ID de Supabase
        final product = await _isar.localProducts
            .filter()
            .supabaseIdEqualTo(productId)
            .findFirst();

        if (product == null) {
          throw Exception("Producto no encontrado en el cache local.");
        }

        // B. Actualizar el stock local (La simulación inmediata)
        product.stockActual += delta;
        await _isar.localProducts.put(product);

        // C. Crear el LOG del movimiento (El "Delta")
        final log = isar_model.LocalStockLog(
          productId: productId,
          adminId: currentUserUid, // ID del admin actual
          delta: delta,
          reason: reason,
          type: type,
          createdAt: DateTime.now(),
          isSynced: false,
        ); // Marcamos como pendiente de subir a la nube

        await _isar.localStockLogs.put(log);
        
        print("💾 Cambio guardado localmente: $productId | Delta: $delta | Stock Final: ${product.stockActual}");
      });

      // INTENTO DE SINCRONIZACIÓN INMEDIATA:
      syncPendingLogs().catchError((e) => print("⚠️ Sync inmediato falló: $e"));

    } catch (e) {
      print("❌ Error en updateStockLocal: $e");
      rethrow;
    }
  }

  /// 4. SINCRONIZADOR: Procesa los logs pendientes y los sube a la nube
  Future<void> syncPendingLogs() async {
    try {
      // 1. Buscar todos los logs que NO han sido sincronizados
      final pendingLogs = await _isar.localStockLogs
          .filter()
          .isSyncedEqualTo(false)
          .sortByCreatedAt() // IMPORTANTE: Mantener el orden cronológico
          .findAll();

      if (pendingLogs.isEmpty) return;

      print("🚀 Sincronizando ${pendingLogs.length} movimientos de stock pendientes...");

      final repo = InventoryFactory.getRepository();

      for (var log in pendingLogs) {
        try {
          // Sincronizamos el delta en la nube
          await repo.updateStock(
            productId: log.productId ?? '',
            delta: log.delta,
            reason: log.reason ?? 'Sincronización offline',
            type: log.type ?? 'AJUSTE',
          );

          // Marcamos el log como sincronizado en Isar
          await _isar.writeTxn(() async {
            log.isSynced = true;
            await _isar.localStockLogs.put(log);
          });
        } catch (e) {
          print("❌ Fallo al sincronizar log ${log.id}: $e. Deteniendo cola para evitar desorden.");
          break; // Detenemos la cola: si uno falla, no podemos seguir para no romper la cronología
        }
      }
      print("✅ Sincronización de logs completada.");
    } catch (e) {
      print("❌ Error general en syncPendingLogs: $e");
    }
  }

  /// Método helper para obtener un solo producto por su ID de Supabase
  Future<isar_model.LocalProduct?> getProductById(String supabaseId) async {
    return await _isar.localProducts
        .filter()
        .supabaseIdEqualTo(supabaseId)
        .findFirst();
  }

  /// Obtiene todos los logs de stock locales ordenados por fecha
  Future<List<isar_model.LocalStockLog>> getLocalStockLogs() async {
    return await _isar.localStockLogs.where().sortByCreatedAtDesc().findAll();
  }
}