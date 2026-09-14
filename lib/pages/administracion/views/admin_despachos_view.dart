import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDespachosView extends StatefulWidget {
  const AdminDespachosView({super.key});

  @override
  State<AdminDespachosView> createState() => _AdminDespachosViewState();
}

class _AdminDespachosViewState extends State<AdminDespachosView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
          child: Text(
            'Pedidos a Despachar',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: FlutterFlowTheme.of(context).headlineMediumFamily,
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontWeight: FontWeight.w600,
                  useGoogleFonts: GoogleFonts.asMap().containsKey(FlutterFlowTheme.of(context).headlineMediumFamily),
                ),
          ),
        ),
        const Expanded(
          child: Center(
            child: Text("Lista de pedidos confirmados listos para envío irá aquí (Migrando desde General)"),
          ),
        ),
      ],
    );
  }
}
