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
      expect(store.whatsappActivo, false);
      expect(store.whatsappConfirmado, false);
    });

    test('StoreData.fromMap parses whatsapp fields and phone number correctly', () {
      final map = {
        'id': 'store-wa',
        'dueno_id': 'user-wa',
        'nombre': 'Tienda WA',
        'slug': 'tienda-wa',
        'color_primario': '#6366F1',
        'color_secundario': '#4F46E5',
        'moneda_principal': 'USD',
        'activa': true,
        'telefono_contacto': '+584121234567',
        'whatsapp_activo': true,
        'whatsapp_confirmado': true,
      };

      final store = StoreData.fromMap(map);

      expect(store.telefonoContacto, '+584121234567');
      expect(store.whatsappActivo, true);
      expect(store.whatsappConfirmado, true);
    });

    test('StoreEligibility evaluates Free plan 2-store quota correctly', () {
      // 0 stores -> Allowed
      final eligibilityZero = StoreEligibility(
        canCreate: true,
        currentStoreCount: 0,
        hasProPlan: false,
      );
      expect(eligibilityZero.canCreate, isTrue);
      expect(eligibilityZero.hasProPlan, isFalse);

      // 1 Free store -> Allowed (Free limit is 2 stores)
      final eligibilityOneFree = StoreEligibility(
        canCreate: true,
        currentStoreCount: 1,
        hasProPlan: false,
      );
      expect(eligibilityOneFree.canCreate, isTrue);
      expect(eligibilityOneFree.hasProPlan, isFalse);

      // 2 Free stores -> Blocked (Free limit reached)
      final eligibilityTwoFree = StoreEligibility(
        canCreate: false,
        currentStoreCount: 2,
        hasProPlan: false,
        message: 'Las cuentas con Plan Free están limitadas a un máximo de 2 tiendas. Para crear 3 o más tiendas con una misma cuenta, actualiza al Plan Pro.',
      );
      expect(eligibilityTwoFree.canCreate, isFalse);
      expect(eligibilityTwoFree.hasProPlan, isFalse);
      expect(eligibilityTwoFree.message, contains('Plan Pro'));

      // 2 Pro stores -> Allowed (Multi-store unlimited enabled)
      final eligibilityPro = StoreEligibility(
        canCreate: true,
        currentStoreCount: 2,
        hasProPlan: true,
      );
      expect(eligibilityPro.canCreate, isTrue);
      expect(eligibilityPro.hasProPlan, isTrue);

      // 5 Pro stores -> Allowed (Unlimited stores)
      final eligibilityProMultiple = StoreEligibility(
        canCreate: true,
        currentStoreCount: 5,
        hasProPlan: true,
      );
      expect(eligibilityProMultiple.canCreate, isTrue);
      expect(eligibilityProMultiple.currentStoreCount, 5);
    });
  });
}
