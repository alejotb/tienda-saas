import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPagosView extends StatefulWidget {
  const AdminPagosView({super.key});

  @override
  State<AdminPagosView> createState() => _AdminPagosViewState();
}

class _AdminPagosViewState extends State<AdminPagosView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
          child: Text(
            'Confirmación de Pagos',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: FlutterFlowTheme.of(context).headlineMediumFamily,
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontWeight: FontWeight.w600,
                  useGoogleFonts: GoogleFonts.asMap().containsKey(FlutterFlowTheme.of(context).headlineMediumFamily),
                ),
          ),
        ),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: FlutterFlowTheme.of(context).primary,
                  unselectedLabelColor: FlutterFlowTheme.of(context).secondaryText,
                  indicatorColor: FlutterFlowTheme.of(context).primary,
                  tabs: const [
                    Tab(text: 'Pagos Regulares'),
                    Tab(text: 'Abonos de Apartado'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      Center(child: Text("Lista de pagos por confirmar irá aquí (Migrando desde General)")),
                      Center(child: Text("Lista de apartados por confirmar irá aquí (Migrando desde General)")),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
