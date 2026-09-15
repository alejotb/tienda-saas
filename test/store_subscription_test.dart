import 'package:flutter_test/flutter_test.dart';
import 'package:baul_pandora/services/store_service.dart';

void main() {
  group('Store Subscription & Custom Domain Model Tests', () {
    test('StoreData.fromMap parses subscription plan and custom domain correctly', () {
      final map = {
        'id': 'store-123',
        'dueno_id': 'user-456',
        'nombre': 'Tienda de Prueba',
        'slug': 'tienda-prueba',
        'color_primario': '#10B981',
        'color_secundario': '#059669',
        'moneda_principal': 'USD',
        'activa': true,
        'plan': 'pro',
        'permite_invitados': false,
        'dominio_personalizado': 'www.tiendaprueba.com',
        'estado_dominio': 'conectado',
      };

      final store = StoreData.fromMap(map);

      expect(store.id, 'store-123');
      expect(store.nombre, 'Tienda de Prueba');
      expect(store.plan, 'pro');
      expect(store.permiteInvitados, false);
      expect(store.dominioPersonalizado, 'www.tiendaprueba.com');
      expect(store.estadoDominio, 'conectado');
    });

    test('StoreData.fromMap applies safe default values for free plan without domain', () {
      final map = {
        'id': 'store-free',
        'dueno_id': 'user-789',
        'nombre': 'Tienda Free',
        'slug': 'tienda-free',
        'color_primario': '#6366F1',
        'color_secundario': '#4F46E5',
        'moneda_principal': 'USD',
        'activa': true,
      };

      final store = StoreData.fromMap(map);

      expect(store.plan, 'free');
      expect(store.permiteInvitados, true);
      expect(store.dominioPersonalizado, isNull);
      expect(store.estadoDominio, 'sin_configurar');
    });
  });
}
