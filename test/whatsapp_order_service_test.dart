import 'package:flutter_test/flutter_test.dart';
import 'package:baul_pandora/services/whatsapp_order_service.dart';

void main() {
  group('WhatsAppOrderService Tests', () {
    final service = WhatsAppOrderService.instance;

    test('cleanPhoneNumber formats Venezuelan local phone numbers to international standard', () {
      expect(service.cleanPhoneNumber('0412-1234567'), '584121234567');
      expect(service.cleanPhoneNumber('0414 987 6543'), '584149876543');
      expect(service.cleanPhoneNumber('0424.555.44.33'), '584245554433');
      expect(service.cleanPhoneNumber('+58 416 1112233'), '584161112233');
    });

    test('cleanPhoneNumber preserves already formatted international numbers', () {
      expect(service.cleanPhoneNumber('+1 (555) 234-5678'), '15552345678');
      expect(service.cleanPhoneNumber('573001234567'), '573001234567');
    });

    test('formatOrderMessage generates comprehensive structured message for WhatsApp', () {
      final items = [
        WhatsAppOrderItem(id: '1', nombre: 'Zapatos Deportivos', cantidad: 2, precioUnitario: 30.0, subtotal: 60.0),
        WhatsAppOrderItem(id: '2', nombre: 'Gorra Urbana', cantidad: 1, precioUnitario: 15.0, subtotal: 15.0),
      ];

      final customer = WhatsAppOrderCustomerInfo(
        name: 'Carlos Perez',
        phone: '04121234567',
        deliveryType: 'domicilio',
        address: 'Av. Bolívar, Res. Sol, Apto 4B',
        paymentMethod: 'Pago Móvil',
        paymentReference: '987654',
        notes: 'Timbre no funciona, llamar al llegar',
      );

      final msg = service.formatOrderMessage(
        storeName: 'Moda Caracas',
        orderNumber: '5544',
        items: items,
        totalUsd: 75.0,
        bcvRate: 40.0,
        customer: customer,
      );

      expect(msg.contains('NUEVO PEDIDO - Moda Caracas'), isTrue);
      expect(msg.contains('#5544'), isTrue);
      expect(msg.contains('2x Zapatos Deportivos'), isTrue);
      expect(msg.contains(r'TOTAL:* $75.00 USD'), isTrue);
      expect(msg.contains('Bs. 3000.00'), isTrue);
      expect(msg.contains('Carlos Perez'), isTrue);
      expect(msg.contains('Av. Bolívar, Res. Sol, Apto 4B'), isTrue);
      expect(msg.contains('Pago Móvil'), isTrue);
      expect(msg.contains('987654'), isTrue);
      expect(msg.contains('Timbre no funciona'), isTrue);
    });
  });
}
