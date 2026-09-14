import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/components/add_pago/add_pago_widget.dart';
import '../checkout_full_page_model.dart';

class CheckoutPaymentSection extends StatelessWidget {
  const CheckoutPaymentSection({
    super.key,
    required this.model,
    required this.onUpdate,
    required this.action,
  });

  final CheckoutFullPageModel model;
  final VoidCallback onUpdate;
  final Future<void> Function() action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 12.0),
          child: Text(
            'Información del pago',
            style: FlutterFlowTheme.of(context).titleMedium,
          ),
        ),
        const SizedBox(height: 12),
        AddPagoWidget(
          model: model.addPagoModel,
          action: action,
          onUpdate: onUpdate,
          initialAmountUsd: model.totalPrice,
          bcvRate: model.bcvRate ?? 0.0,
        ),
      ],
    );
  }
}
