import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import '../apartado_payment_model.dart';

class ApartadoPaymentSection extends StatelessWidget {
  const ApartadoPaymentSection({
    super.key,
    required this.model,
    required this.onUpdate,
  });

  final ApartadoPaymentModel model;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Método de Pago', style: FlutterFlowTheme.of(context).titleMedium),
        const SizedBox(height: 12),
        // Aquí iría el AddPagoWidget adaptado o campos simplificados
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).primaryBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('Simulación de campos de pago (AddPagoWidget aquí)'),
        ),
      ],
    );
  }
}
