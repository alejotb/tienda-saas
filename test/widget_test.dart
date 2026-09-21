import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baul_pandora/components/whatsapp_connection_modal.dart';
import 'package:baul_pandora/services/store_service.dart';

void main() {
  testWidgets('WhatsAppConnectionModal renders correctly with store data', (WidgetTester tester) async {
    final mockStore = StoreData(
      id: 'store-1',
      duenoId: 'user-1',
      nombre: 'Tienda Test',
      slug: 'tienda-test',
      colorPrimario: '#6366F1',
      colorSecundario: '#4F46E5',
      monedaPrincipal: 'USD',
      activa: true,
      plan: 'free',
      telefonoContacto: '+584121234567',
      whatsappActivo: true,
      whatsappConfirmado: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WhatsAppConnectionModal(
            store: mockStore,
          ),
        ),
      ),
    );

    expect(find.text('Conexión con WhatsApp'), findsOneWidget);
    expect(find.text('Activar pedidos por WhatsApp'), findsOneWidget);
    expect(find.text('Enviar mensaje de prueba a WhatsApp'), findsOneWidget);
    expect(find.text('Confirmar y verificar este número'), findsOneWidget);
    expect(find.text('Guardar Configuración'), findsOneWidget);
  });
}
