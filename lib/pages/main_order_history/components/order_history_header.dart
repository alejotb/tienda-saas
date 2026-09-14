import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';

class OrderHistoryHeader extends StatelessWidget {
  const OrderHistoryHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 0.0, 0.0),
          child: Text(
            'Historial de pedidos',
            style: FlutterFlowTheme.of(context).headlineLarge.override(
              font: GoogleFonts.interTight(
                fontWeight: FlutterFlowTheme.of(context).headlineLarge.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).headlineLarge.fontStyle,
              ),
              letterSpacing: 0.0,
              fontWeight: FlutterFlowTheme.of(context).headlineLarge.fontWeight,
              fontStyle: FlutterFlowTheme.of(context).headlineLarge.fontStyle,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16.0, 4.0, 0.0, 12.0),
          child: Text(
            'Ordenes pendientes',
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
      ],
    );
  }
}
