import 'package:flutter/foundation.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/services/store_service.dart';

class StoreIntegration {
  final String id;
  final String tiendaId;
  final String tipo; // 'woocommerce', 'shopify', 'mercadolibre'
  final bool activa;
  final Map<String, dynamic> credenciales;

  StoreIntegration({
    required this.id,
    required this.tiendaId,
    required this.tipo,
    required this.activa,
    required this.credenciales,
  });

  factory StoreIntegration.fromMap(Map<String, dynamic> map) {
    return StoreIntegration(
      id: map['id']?.toString() ?? '',
      tiendaId: map['tienda_id']?.toString() ?? '',
      tipo: map['tipo']?.toString() ?? '',
      activa: map['activa'] == true,
      credenciales: map['credenciales'] is Map
          ? Map<String, dynamic>.from(map['credenciales'] as Map)
          : <String, dynamic>{},
    );
  }
}

class IntegrationService {
  static final IntegrationService instance = IntegrationService._internal();
  IntegrationService._internal();

  /// Obtiene las integraciones configuradas para una tienda específica
  Future<List<StoreIntegration>> getStoreIntegrations(String tiendaId) async {
    try {
      final res = await SupaFlow.client
          .from('tienda_integraciones')
          .select()
          .eq('tienda_id', tiendaId);

      return (res as List).map((map) => StoreIntegration.fromMap(map)).toList();
    } catch (e) {
      debugPrint('Error cargando integraciones de la tienda: $e');
      return [];
    }
  }

  /// Guarda o actualiza las credenciales de WooCommerce para la tienda activa
  Future<bool> saveWooCommerceIntegration({
    required String tiendaId,
    required String wooUrl,
    required String consumerKey,
    required String consumerSecret,
    required bool activa,
  }) async {
    try {
      final creds = {
        'url': wooUrl.trim(),
        'consumer_key': consumerKey.trim(),
        'consumer_secret': consumerSecret.trim(),
        'last_updated': DateTime.now().toIso8601String(),
      };

      await SupaFlow.client.from('tienda_integraciones').upsert(
        {
          'tienda_id': tiendaId,
          'tipo': 'woocommerce',
          'activa': activa,
          'credenciales': creds,
        },
        onConflict: 'tienda_id, tipo',
      );

      return true;
    } catch (e) {
      debugPrint('Error guardando credenciales de WooCommerce: $e');
      return false;
    }
  }
}
