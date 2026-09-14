import 'package:baul_pandora/backend/api_requests/api_calls.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:flutter/foundation.dart';

import 'package:baul_pandora/custom_code/actions/index.dart' as actions;

class SyncResult {
  final bool success;
  final String message;
  final double durationSeconds;
  final Map<String, dynamic> summary;

  SyncResult({
    required this.success,
    required this.message,
    this.durationSeconds = 0.0,
    this.summary = const {},
  });
}

class WooCommerceSyncService {
  // Singleton pattern
  static final WooCommerceSyncService _instance = WooCommerceSyncService._internal();
  factory WooCommerceSyncService() => _instance;
  WooCommerceSyncService._internal();

  /// Sincroniza pedidos y movimientos de WooCommerce
  Future<SyncResult> syncOrders() async {
    return await syncAllProducts(target: 'orders');
  }

  /// Sincroniza WooCommerce directamente desde el Backend de Supabase (Edge Function)
  /// Si el backend no está disponible o falla, realiza un fallback automático al cliente.
  Future<SyncResult> syncAllProducts({String target = 'all'}) async {
    final startTime = DateTime.now();
    try {
      debugPrint('🚀 Intentando sincronización mediante Supabase Backend (Edge Function)...');

      final functionResponse = await SupaFlow.client.functions.invoke(
        'sync-woocommerce',
        body: {'target': target},
      );

      if (functionResponse.status == 200 && functionResponse.data != null) {
        final data = functionResponse.data as Map<String, dynamic>;
        final duration = (data['duration_seconds'] as num?)?.toDouble() ?? 
            (DateTime.now().difference(startTime).inMilliseconds / 1000.0);
        final summary = Map<String, dynamic>.from(data['summary'] ?? {});
        final int catCount = (summary['categories_synced'] as num?)?.toInt() ?? 0;
        final int prodCount = (summary['products_synced'] as num?)?.toInt() ?? 0;
        final int varCount = (summary['variations_synced'] as num?)?.toInt() ?? 0;
        final int ordCount = (summary['orders_synced'] as num?)?.toInt() ?? 0;
        final int movCount = (summary['movements_created'] as num?)?.toInt() ?? 0;

        final List<String> details = [];
        if (prodCount > 0) details.add('📦 $prodCount productos');
        if (varCount > 0) details.add('🔀 $varCount variaciones');
        if (catCount > 0) details.add('📂 $catCount categorías');
        if (ordCount > 0) details.add('🛒 $ordCount pedidos');
        if (movCount > 0) details.add('📊 $movCount movimientos');

        final String detailMsg = '✅ ¡Sincronización en la base de datos completada (${duration.toStringAsFixed(1)}s)!\n' +
            (details.isNotEmpty ? details.join(' | ') : 'Todo sincronizado.');

        debugPrint('✅ Sincronización Backend Exitosa en ${duration}s: $summary');
        return SyncResult(
          success: true,
          message: detailMsg,
          durationSeconds: duration,
          summary: summary,
        );
      } else {
        debugPrint('⚠️ Edge function retornó status ${functionResponse.status}. Ejecutando sincronización fallback local...');
      }
    } catch (e) {
      debugPrint('⚠️ Error al invocar Edge Function (puede que aún no esté desplegada): $e');
      debugPrint('➡️ Continuando con sincronización de fallback local en el cliente...');
    }

    // Fallback: Sincronización en cliente
    return await _syncLocalFallback();
  }

  /// Sincronización local en el cliente (Fallback)
  Future<SyncResult> _syncLocalFallback() async {
    final startTime = DateTime.now();
    int totalCategories = 0;
    int totalProducts = 0;

    try {
      debugPrint('📂 [Fallback Local] Sincronizando categorías...');
      try {
        final categoriesResponse = await WooCommerceFetchCall().call(
          endpoint: 'products/categories',
        );

        if (categoriesResponse.succeeded) {
          final List<dynamic> categories = categoriesResponse.jsonBody as List<dynamic>;
          await actions.syncCategories(categories);
          totalCategories = categories.length;
          debugPrint('✅ [Fallback Local] Categorías sincronizadas: $totalCategories');
        }
      } catch (e) {
        debugPrint('⚠️ [Fallback Local] Advertencia al sincronizar categorías: $e');
      }

      debugPrint('📦 [Fallback Local] Sincronizando productos...');
      int page = 1;
      bool hasMore = true;

      while (hasMore) {
        final response = await WooCommerceFetchCall().call(
          endpoint: 'products',
          page: page,
        );

        if (!response.succeeded) break;

        final List<dynamic> products = response.jsonBody as List<dynamic>;
        if (products.isEmpty) break;

        final List<dynamic> allProductsWithVariations = List.from(products);

        for (final product in products) {
          if (product is Map && product['type'] == 'variable') {
            final productId = product['id'];
            try {
              final variationsResponse = await WooCommerceFetchCall().call(
                endpoint: 'products/$productId/variations',
              );
              if (variationsResponse.succeeded) {
                final variations = variationsResponse.jsonBody as List<dynamic>;
                for (var v in variations) {
                  if (v is Map) {
                    v['type'] = 'variation';
                    v['parent_id'] = productId;
                    v['categories'] = product['categories'];
                  }
                }
                allProductsWithVariations.addAll(variations);
              }
            } catch (e) {
              debugPrint('⚠️ Error en variaciones de producto $productId: $e');
            }
          }
        }

        await actions.syncProducts(allProductsWithVariations);
        totalProducts += allProductsWithVariations.length;

        final totalPagesStr = response.headers['x-wp-totalpages'] ?? '1';
        final totalPages = int.tryParse(totalPagesStr) ?? 1;

        if (page >= totalPages) {
          hasMore = false;
        } else {
          page++;
        }
      }

      final duration = DateTime.now().difference(startTime).inMilliseconds / 1000.0;
      debugPrint('🏁 [Fallback Local] Sincronización completada en ${duration}s. Total: $totalProducts');

      return SyncResult(
        success: true,
        message: 'ℹ️ Sincronización local completada (${duration.toStringAsFixed(1)}s):\n'
            '📦 $totalProducts productos | 📂 $totalCategories categorías',
        durationSeconds: duration,
        summary: {
          'categories_synced': totalCategories,
          'products_synced': totalProducts,
        },
      );
    } catch (e) {
      debugPrint('🔥 Error crítico en sincronización fallback: $e');
      return SyncResult(
        success: false,
        message: 'Error al sincronizar: $e',
        durationSeconds: DateTime.now().difference(startTime).inMilliseconds / 1000.0,
      );
    }
  }
}
