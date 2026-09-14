import 'package:flutter/material.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:google_fonts/google_fonts.dart';

class ApartadoPaymentDetails extends StatelessWidget {
  final String pedidoId;
  final double totalPedido;

  const ApartadoPaymentDetails({
    super.key,
    required this.pedidoId,
    required this.totalPedido,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: SupaFlow.client
          .from('pagos')
          .select('*')
          .eq('pedido_id', pedidoId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final pagos = snapshot.data!;
        double totalPagado = 0.0;
        for (var pago in pagos) {
          totalPagado += (pago['monto'] as num).toDouble();
        }
        
        final saldoPendiente = totalPedido - totalPagado;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Detalles de Pagos',
                style: FlutterFlowTheme.of(context).labelMedium,
              ),
            ),
            ...pagos.map((pago) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${pago['tipo'] ?? 'Pago'}: ${pago['referencia'] ?? 'S/R'}',
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                  Text(
                    formatNumber(
                      (pago['monto'] as num).toDouble(),
                      formatType: FormatType.decimal,
                      decimalType: DecimalType.automatic,
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saldo Pendiente',
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                    font: GoogleFonts.inter(),
                    color: FlutterFlowTheme.of(context).error,
                  ),
                ),
                Text(
                  formatNumber(
                    saldoPendiente,
                    formatType: FormatType.decimal,
                    decimalType: DecimalType.automatic,
                  ),
                  style: FlutterFlowTheme.of(context).titleMedium.override(
                    font: GoogleFonts.inter(),
                    color: FlutterFlowTheme.of(context).error,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
