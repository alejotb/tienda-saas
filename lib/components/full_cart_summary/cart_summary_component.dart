import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:baul_pandora/components/whatsapp_order_modal.dart';

class CartSummaryComponent extends StatelessWidget {
  const CartSummaryComponent({
    super.key,
    required this.items,
    required this.subtotal,
    required this.totalPagado,
    required this.total,
    required this.bcvRate,
    this.onApartar,
    this.onComprar,
    this.isApartarEnabled = false,
    this.isComprarEnabled = false,
    this.onApartadoCreado,
  });

  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double totalPagado;
  final double total;
  final double bcvRate;
  final VoidCallback? onApartar;
  final VoidCallback? onComprar;
  final bool isApartarEnabled;
  final bool isComprarEnabled;
  final VoidCallback? onApartadoCreado;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 430.0),
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        boxShadow: const [
          BoxShadow(blurRadius: 4.0, color: Color(0x33000000), offset: Offset(0.0, 2.0))
        ],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumen del pedido', style: FlutterFlowTheme.of(context).titleLarge),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 12.0),
              child: Text('A continuación se muestra una lista de sus artículos.',
                  style: FlutterFlowTheme.of(context).labelMedium),
            ),
            Divider(height: 32.0, thickness: 2.0, color: FlutterFlowTheme.of(context).alternate),
            
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No hay productos seleccionados',
                    style: FlutterFlowTheme.of(context).bodySmall,
                  ),
                ),
              )
            else
              ...items.map((item) => _buildProductRow(context, item)),
            
            const Divider(height: 24),
            _buildRow(context, 'Subtotal', subtotal, isTotal: false),
            
            if (totalPagado > 0)
              _buildRow(context, 'Saldo de Apartados', totalPagado, isTotal: false),
            
            const Divider(),
            
            _buildRow(context, 'Total', total, isTotal: true),

            // Aviso de envío gratis
            if (bcvRate > 0 && items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total en Bs.',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Inter',
                            fontSize: 12,
                          ),
                    ),
                    Text(
                      formatNumber(total * bcvRate, formatType: FormatType.decimal, decimalType: DecimalType.automatic, currency: 'Bs.'),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            
            // Aviso de envío gratis (Movido debajo del total en Bs.)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping, size: 16, color: FlutterFlowTheme.of(context).secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Envío gratis por MRW a partir de 6 productos',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Inter',
                              color: FlutterFlowTheme.of(context).secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (onApartar != null || onComprar != null || items.isNotEmpty) ...[
              const SizedBox(height: 20),

              // Botón Pedir por WhatsApp
              if (items.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                    label: const Text(
                      'Pedir por WhatsApp',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => WhatsAppOrderModal(
                          items: items,
                          subtotal: subtotal,
                          total: total,
                          bcvRate: bcvRate,
                          onOrderPlaced: onApartadoCreado,
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),

              Row(
                children: [
                  if (onApartar != null) ...[
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isApartarEnabled ? onApartar : null,
                        child: const Text('Apartar', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (onComprar != null)
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlutterFlowTheme.of(context).primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isComprarEnabled ? onComprar : null,
                        child: const Text('Pagar en Línea', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow(BuildContext context, Map<String, dynamic> item) {
    return Padding(
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
                formatNumber(item['subtotal'], formatType: FormatType.decimal, decimalType: DecimalType.automatic, currency: '\$'),
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
    );
  }

  Widget _buildRow(BuildContext context, String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isTotal ? FlutterFlowTheme.of(context).titleMedium : FlutterFlowTheme.of(context).bodySmall),
          Text(
            formatNumber(amount, formatType: FormatType.decimal, decimalType: DecimalType.automatic, currency: '\$'),
            style: isTotal ? FlutterFlowTheme.of(context).displaySmall : FlutterFlowTheme.of(context).bodyLarge,
          ),
        ],
      ),
    );
  }
}
