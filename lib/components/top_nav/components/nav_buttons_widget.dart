import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_widgets.dart';
import 'package:baul_pandora/index.dart';
import 'package:google_fonts/google_fonts.dart';

class NavButtonsWidget extends StatelessWidget {
  final BuildContext parentContext;

  const NavButtonsWidget({super.key, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStateNotifier.instance,
      builder: (context, _) {
        final isAdmin = (AppStateNotifier.instance.currentUserRow?.isAdmin ?? false) || FFAppState().isAdmin;

        if (!responsiveVisibility(context: context, phone: false, tablet: false)) {
          return const SizedBox.shrink();
        }

        if (isAdmin) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildButton(context, 'Tienda', MainHomePageWidget.routeName),
              _buildButton(context, 'Confirmar Pagos', 'adminPagos'),
              _buildButton(context, 'Despachos', 'adminDespachos'),
              _buildButton(context, 'Inventario', 'adminInventario'),
            ],
          );
        } else {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildButton(context, 'Mis ordenes', MainOrderHistoryWidget.routeName),
              _buildButton(context, 'Favoritos', MainFavoritesWidget.routeName),
            ],
          );
        }
      },
    );
  }

  Widget _buildButton(BuildContext context, String text, String routeName) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
      child: FFButtonWidget(
        onPressed: () async {
          // Si el admin hace clic en los botones de administraciA3n, navegamos cambiando el estado en main.dart
          // Por ahora, usaremos el mismo mecanismo de go_router que ya existAa.
          context.pushNamed(
            routeName,
            extra: <String, dynamic>{
              '__transition_info__': const TransitionInfo(
                hasTransition: true,
                transitionType: PageTransitionType.fade,
                duration: Duration(milliseconds: 0),
              ),
            },
          );
        },
        text: text,
        options: FFButtonOptions(
          height: 44.0,
          padding: const EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
          iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
          color: Colors.transparent,
          textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: FlutterFlowTheme.of(context).bodyMediumFamily,
                color: FlutterFlowTheme.of(context).primaryText,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w500,
                useGoogleFonts: GoogleFonts.asMap().containsKey(FlutterFlowTheme.of(context).bodyMediumFamily),
              ),
          elevation: 0.0,
          borderSide: const BorderSide(
            color: Colors.transparent,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
          hoverColor: FlutterFlowTheme.of(context).alternate,
          hoverBorderSide: BorderSide(
            color: FlutterFlowTheme.of(context).alternate,
            width: 1.0,
          ),
          hoverTextColor: FlutterFlowTheme.of(context).primaryText,
        ),
      ),
    );
  }
}
