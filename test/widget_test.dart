import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baul_pandora/components/otp_verification_dialog.dart';

void main() {
  testWidgets('OtpVerificationDialog renders correctly with title and inputs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OtpVerificationDialog(
            email: 'test@example.com',
            title: 'Confirma tu correo',
          ),
        ),
      ),
    );

    expect(find.text('Confirma tu correo'), findsOneWidget);
    expect(find.textContaining('test@example.com'), findsOneWidget);
    expect(find.text('Verificar y Continuar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
