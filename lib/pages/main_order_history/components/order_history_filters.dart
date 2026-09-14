import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import '../main_order_history_model.dart';

class OrderHistoryFilters extends StatelessWidget {
  const OrderHistoryFilters({
    super.key,
    required this.model,
    required this.onUpdate,
  });

  final MainOrderHistoryModel model;
  final VoidCallback onUpdate;

  Widget _buildFilterButton(BuildContext context, String label, String value) {
    bool isActive = model.filtro.contains(value);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8.0, 8.0, 8.0, 8.0),
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () {
          if (isActive) {
            model.filtro = [];
          } else {
            model.filtro = [value];
          }
          onUpdate();
        },
        child: Container(
          height: 40.0,
          decoration: BoxDecoration(
            color: isActive 
                ? FlutterFlowTheme.of(context).secondaryText.withOpacity(0.3) // Gris cuando activo
                : FlutterFlowTheme.of(context).accent4,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 16.0, 0.0),
            child: Text(
              label,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(
                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Text(
          'Filtros:',
          style: FlutterFlowTheme.of(context).bodyMedium.override(
            font: GoogleFonts.inter(
              fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
            ),
            letterSpacing: 0.0,
            fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
            fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 0.0, 0.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(8.0, 8.0, 8.0, 8.0),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        model.filtro = [];
                        onUpdate();
                      },
                      child: Container(
                        height: 40.0,
                        decoration: BoxDecoration(
                          color: model.filtro.isEmpty
                              ? FlutterFlowTheme.of(context).secondaryText.withOpacity(0.3) // Gris cuando está activo ("Todos")
                              : FlutterFlowTheme.of(context).accent4,
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 16.0, 0.0),
                          child: Text(
                            'Todos',
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                              ),
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  _buildFilterButton(context, 'Apartados', 'apartado'),
                  _buildFilterButton(context, 'Pagados', 'pagado'),
                  _buildFilterButton(context, 'Confirmados', 'confirmado'),
                  _buildFilterButton(context, 'Rechazados', 'rechazado'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
