import 'package:flutter/material.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderHeader extends StatelessWidget {
  final PedidosRow orderRef;

  const OrderHeader({super.key, required this.orderRef});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                (orderRef.status == 'apartado')
                    ? 'Apartado'
                    : (orderRef.status == 'expirado')
                        ? 'Expirado'
                        : valueOrDefault<String>(orderRef.pedidoNombre, 'Unknown'),
                style: FlutterFlowTheme.of(context).headlineMedium,
              ),
            ),
            Text(
              formatNumber(
                orderRef.totalPrice ?? 0.0,
                formatType: FormatType.decimal,
                decimalType: DecimalType.automatic,
              ),
              style: FlutterFlowTheme.of(context).headlineSmall,
            ),
          ].divide(const SizedBox(width: 16.0)),
        ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if ((orderRef.status == 'apartado' || orderRef.status == 'expirado') &&
                orderRef.fechaExpiracion != null)
              Text(
                'Vence: ${dateTimeFormat("MMMEd", orderRef.fechaExpiracion)}',
                style: FlutterFlowTheme.of(context).labelSmall.override(
                      font: GoogleFonts.inter(),
                      color: FlutterFlowTheme.of(context).error,
                      fontWeight: FontWeight.bold,
                    ),
              )
            else
              const SizedBox.shrink(), // Mantener espacio si no hay fecha
            Container(
              height: 32.0,
              decoration: BoxDecoration(
                color: _getStatusColor(context, orderRef.status, isBackground: true),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: _getStatusColor(context, orderRef.status, isBackground: false),
                  width: 2.0,
                ),
              ),
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  valueOrDefault<String>(orderRef.status, '--'),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(),
                        color: _getStatusColor(context, orderRef.status, isBackground: false),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(BuildContext context, String? status, {required bool isBackground}) {
    if (status == 'pendiente_pago') {
      return isBackground ? FlutterFlowTheme.of(context).accent3 : FlutterFlowTheme.of(context).tertiary;
    } else if (status == 'confirmado') {
      return isBackground ? FlutterFlowTheme.of(context).accent2 : FlutterFlowTheme.of(context).secondary;
    } else {
      return isBackground ? FlutterFlowTheme.of(context).accent1 : FlutterFlowTheme.of(context).primary;
    }
  }
}
