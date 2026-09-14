import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_icon_button.dart';
import 'package:baul_pandora/flutter_flow/custom_functions.dart' as functions;
import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'checkout_footer_action.dart';
import '../checkout_full_page_model.dart';

class CheckoutOrderSummary extends StatelessWidget {
  const CheckoutOrderSummary({
    super.key,
    required this.shippingOption,
    required this.model,
  });

  final ShippingOptionsStruct? shippingOption;
  final CheckoutFullPageModel model;

  @override
  Widget build(BuildContext context) {
    final bool isLiquidation = model.pedidoId != null;
    
    // Calcular el precio de los productos usando el modelo
    final double cartPrice = model.cartPrice;
    
    final shippingPrice = shippingOption?.price ?? 0.0;
    
    // Calcular total usando el modelo
    final total = model.calculateTotal(shippingPrice);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxWidth: 430.0,
      ),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        boxShadow: const [
          BoxShadow(
            blurRadius: 4.0,
            color: Color(0x33000000),
            offset: Offset(0.0, 2.0),
          )
        ],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del pedido',
              style: FlutterFlowTheme.of(context).titleLarge.override(
                    font: GoogleFonts.interTight(
                      fontWeight: FlutterFlowTheme.of(context).titleLarge.fontWeight,
                      fontStyle: FlutterFlowTheme.of(context).titleLarge.fontStyle,
                    ),
                    letterSpacing: 0.0,
                    fontWeight: FlutterFlowTheme.of(context).titleLarge.fontWeight,
                    fontStyle: FlutterFlowTheme.of(context).titleLarge.fontStyle,
                  ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 12.0),
              child: Text(
                'A continuación se muestra una lista de sus artículos.',
                style: FlutterFlowTheme.of(context).labelMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                        fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                      ),
                      letterSpacing: 0.0,
                      fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                      fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                    ),
              ),
            ),
            
            // --- Nueva lista de productos ---
            if (model.productosSeleccionados.isNotEmpty) ...[
              const Divider(),
              ...model.productosSeleccionados.map((item) {
                final product = item is Map ? item : {};
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${product['nombre'] ?? 'Producto'} (x${product['cantidad'] ?? 1})',
                          style: FlutterFlowTheme.of(context).bodyMedium,
                        ),
                      ),
                      Text(
                        formatNumber((product['precio'] as num? ?? 0.0) * (product['cantidad'] as num? ?? 1),
                            formatType: FormatType.decimal,
                            decimalType: DecimalType.automatic,
                            currency: '\$'),
                        style: FlutterFlowTheme.of(context).bodyMedium,
                      ),
                    ],
                  ),
                );
              }),
            ],
            // --------------------------------

            Divider(
              height: 32.0,
              thickness: 2.0,
              color: FlutterFlowTheme.of(context).alternate,
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                    child: Text(
                      'Factura',
                      style: FlutterFlowTheme.of(context).labelMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                              fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                            fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                          ),
                    ),
                  ),
                   _buildSummaryRow(context, 'Subtotal', cartPrice),
                   if (isLiquidation)
                     _buildSummaryRow(context, 'Saldo del Apartado', model.pendingBalance),
                   if (model.saldoApartados != null && model.saldoApartados! > 0)
                     _buildSummaryRow(context, 'Saldo de Apartados', model.saldoApartados!),
                   if (shippingOption != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Envío',
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                  font: GoogleFonts.outfit(
                                    fontWeight: FontWeight.normal,
                                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.normal,
                                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(4.0, 0.0, 0.0, 0.0),
                              child: Text(
                                valueOrDefault<String>(shippingOption!.shippingName, '--'),
                                style: FlutterFlowTheme.of(context).bodySmall.override(
                                      font: GoogleFonts.outfit(
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                      fontSize: 14.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.normal,
                                      fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                    ),
                                ),
                              ),
                            ),
                          Text(
                            formatNumber(shippingOption!.price,
                                formatType: FormatType.decimal,
                                decimalType: DecimalType.automatic,
                                currency: '\$'),
                            textAlign: TextAlign.end,
                            style: FlutterFlowTheme.of(context).bodyLarge.override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                                  ),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                                ),
                          ),
                        ].divide(const SizedBox(width: 4.0)),
                      ),
                    ),
                       // --- Fin de nueva sección ---

             Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                           Row(
                             mainAxisSize: MainAxisSize.max,
                             children: [
                               Text(
                                 isLiquidation ? 'Saldo a Pagar' : 'Total',
                                 style: FlutterFlowTheme.of(context).titleMedium.override(
                                       font: GoogleFonts.outfit(
                                         fontWeight: FontWeight.w500,
                                         fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                       ),
                                       color: FlutterFlowTheme.of(context).secondaryText,
                                       fontSize: 20.0,
                                       letterSpacing: 0.0,
                                       fontWeight: FontWeight.w500,
                                       fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                                     ),
                               ),
                               FlutterFlowIconButton(
                              borderColor: Colors.transparent,
                              borderRadius: 30.0,
                              borderWidth: 1.0,
                              buttonSize: 36.0,
                              icon: Icon(
                                Icons.info_outlined,
                                color: FlutterFlowTheme.of(context).secondaryText,
                                size: 18.0,
                              ),
                              onPressed: () {
                                print('IconButton pressed ...');
                              },
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatNumber(total,
                                  formatType: FormatType.decimal,
                                  decimalType: DecimalType.automatic,
                                  currency: '\$'),
                              style: FlutterFlowTheme.of(context).displaySmall.override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FlutterFlowTheme.of(context).displaySmall.fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context).displaySmall.fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context).displaySmall.fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context).displaySmall.fontStyle,
                                  ),
                            ),
                            if (model.bcvRate != null && model.bcvRate! > 0)
                              Text(
                                formatNumber(total * model.bcvRate!,
                                    formatType: FormatType.decimal,
                                    decimalType: DecimalType.automatic,
                                    currency: 'Bs. '),
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontFamily: 'Inter',
                                      color: FlutterFlowTheme.of(context).secondaryText,
                                      fontSize: 14.0,
                                    ),
                              ),
                              InkWell(
                                onTap: () async {
                                  final montoBs = formatNumber(total * model.bcvRate!,
                                      formatType: FormatType.decimal,
                                      decimalType: DecimalType.automatic,
                                      currency: 'Bs. ');
                                  await Clipboard.setData(ClipboardData(text: montoBs));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Monto copiado al portapapeles'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                child: Icon(
                                  Icons.content_copy,
                                  size: 14.0,
                                  color: FlutterFlowTheme.of(context).primary,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  Opacity(
                    opacity: model.stepNumber == 3 ? 1.0 : 0.5,
                    child: AbsorbPointer(
                      absorbing: model.stepNumber != 3,
                      child: CheckoutFooterAction(
                        model: model,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, double value, {double? bcvRate}) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.outfit(
                    fontWeight: FontWeight.normal,
                    fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).secondaryText,
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.normal,
                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatNumber(value,
                    formatType: FormatType.decimal,
                    decimalType: DecimalType.automatic,
                    currency: '\$'),
                textAlign: TextAlign.end,
                style: FlutterFlowTheme.of(context).bodyLarge.override(
                      font: GoogleFonts.inter(
                        fontWeight: FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                        fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                      ),
                      letterSpacing: 0.0,
                      fontWeight: FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                      fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                    ),
              ),
              if (bcvRate != null && bcvRate > 0)
                Text(
                  formatNumber(value * bcvRate,
                      formatType: FormatType.decimal,
                      decimalType: DecimalType.automatic,
                      currency: 'Bs. '),
                  textAlign: TextAlign.end,
                  style: FlutterFlowTheme.of(context).bodySmall.override(
                        fontFamily: 'Inter',
                        color: FlutterFlowTheme.of(context).secondaryText,
                        fontSize: 12.0,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
