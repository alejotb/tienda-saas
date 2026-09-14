import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';

class PaymentInstructionsComponent extends StatelessWidget {
  const PaymentInstructionsComponent({super.key, required this.paymentType});

  final String? paymentType;

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copiado: $text')),
    );
  }

  Widget _buildDataItem(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: value),
                ],
              ),
              style: FlutterFlowTheme.of(context).bodyMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            onPressed: () => _copyToClipboard(context, value),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (paymentType == null || paymentType == 'Efectivo') {
      return const SizedBox.shrink();
    }

    String title = '';
    List<Map<String, String>> data = [];

    if (paymentType == 'Pago Movil') {
      title = 'Datos para Pago Móvil';
      data = [
        {'label': 'Banco', 'value': 'Banco de Venezuela'},
        {'label': 'C.I', 'value': '26749184'},
        {'label': 'Teléfono', 'value': '04120756612'},
      ];
    } else if (paymentType == 'Binance' || paymentType == 'Pay Pal') {
      title = 'Datos para $paymentType';
      data = [
        {'label': 'Correo', 'value': 'ajulia.seo@gmail.com'},
      ];
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FlutterFlowTheme.of(context).primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: FlutterFlowTheme.of(context).titleSmall.override(fontWeight: FontWeight.bold, fontFamily: 'Inter')),
          const SizedBox(height: 8),
          ...data.map((item) => _buildDataItem(context, item['label']!, item['value']!)),
        ],
      ),
    );
  }
}
