import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_icon_button.dart';
import '../apartado_payment_model.dart';

class ApartadoOrderSummary extends StatelessWidget {
  const ApartadoOrderSummary({
    super.key,
    required this.model,
    required this.onConfirm,
    required this.onPagarMasTarde,
    required this.isProcessing,
    required this.comprobanteValidado,
  });
  final ApartadoPaymentModel model;
  final Future<void> Function() onConfirm;
  final Future<void> Function() onPagarMasTarde;
  final bool isProcessing;
  final bool comprobanteValidado;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Productos por apartar', style: FlutterFlowTheme.of(context).titleMedium),
          const Divider(height: 32),
          ...model.productsDetails.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['nombre'],
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        Text(
                          formatNumber(item['precio'] * item['cantidad'], formatType: FormatType.decimal, decimalType: DecimalType.automatic, currency: '\$'),
                          style: FlutterFlowTheme.of(context).bodySmall,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Precio: ${formatNumber(item['precio'], formatType: FormatType.decimal, decimalType: DecimalType.automatic, currency: '\$')} x ${item['cantidad']}',
                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: FlutterFlowTheme.of(context).secondaryText,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
          const Divider(height: 32),
          _buildRow(context, 'Tarifa de apartado (\$2 x ${model.productIds.length})', model.feeToPay),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mínimo a cancelar', style: FlutterFlowTheme.of(context).titleMedium),
                  if (model.bcvRate > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        'Total a pagar en bs',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatNumber(model.pendingBalance, formatType: FormatType.decimal, decimalType: DecimalType.automatic, currency: '\$'),
                    style: FlutterFlowTheme.of(context).displaySmall.override(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                  if (model.bcvRate > 0)
                    Row(
                      children: [
                        Text(
                          formatNumber(model.pendingBalance * model.bcvRate, formatType: FormatType.decimal, decimalType: DecimalType.automatic, currency: 'Bs.'),
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        FlutterFlowIconButton(
                          borderColor: Colors.transparent,
                          borderRadius: 20,
                          buttonSize: 30,
                          icon: Icon(
                            Icons.content_copy,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 14,
                          ),
                          onPressed: () async {
                            final textToCopy = formatNumber(
                              model.pendingBalance * model.bcvRate,
                              formatType: FormatType.decimal,
                              decimalType: DecimalType.automatic,
                              currency: '',
                            ).replaceAll(',', '.');
                            await Clipboard.setData(ClipboardData(text: textToCopy));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Monto copiado al portapapeles')),
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Cantidad mínima a pagar para asegurar el apartado de sus productos',
            style: FlutterFlowTheme.of(context).bodySmall.override(
              fontFamily: 'Inter',
              color: FlutterFlowTheme.of(context).secondaryText,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isProcessing ? null : onPagarMasTarde,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FlutterFlowTheme.of(context).secondary,
                    side: BorderSide(color: FlutterFlowTheme.of(context).secondary),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Pagar más tarde',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (isProcessing || !comprobanteValidado) ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlutterFlowTheme.of(context).primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: FlutterFlowTheme.of(context).primary.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Apartar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: FlutterFlowTheme.of(context).bodyMedium)),
          Text(
            formatNumber(amount, formatType: FormatType.decimal, decimalType: DecimalType.automatic, currency: '\$'),
            style: FlutterFlowTheme.of(context).bodyMedium.override(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
