import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_widgets.dart';
import 'package:baul_pandora/index.dart';
import 'package:baul_pandora/pages/administracion/admin_dashboard_page.dart';
import 'package:baul_pandora/pages/store_register/store_register_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class NavButtonsWidget extends StatelessWidget {
  final BuildContext parentContext;

  const NavButtonsWidget({super.key, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStateNotifier.instance,
      builder: (context, _) {
        final hasStore = AppStateNotifier.instance.hasStore;
        final isAdmin = (AppStateNotifier.instance.currentUserRow?.isAdmin ?? false) || FFAppState().isAdmin || hasStore;

        if (!responsiveVisibility(context: context, phone: false, tablet: false)) {
          return const SizedBox.shrink();
        }

        if (isAdmin) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildButton(context, 'Panel Control', AdminDashboardPage.routeName),
              _buildButton(context, 'Inventario', 'adminInventario'),
              _buildButton(context, 'Pagos', 'adminPagos'),
              _buildButton(context, 'Despachos', 'adminDespachos'),
            ],
          );
        } else {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildButton(context, '💼 Crea tu Tienda', StoreRegisterWidget.routeName, isHighlight: true),
              _buildButton(context, 'Mis ordenes', MainOrderHistoryWidget.routeName),
              _buildButton(context, 'Favoritos', MainFavoritesWidget.routeName),
            ],
          );
        }
      },
    );
  }

  Widget _buildButton(BuildContext context, String text, String routeName, {bool isHighlight = false}) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
      child: FFButtonWidget(
        onPressed: () async {
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
          height: 40.0,
          padding: const EdgeInsetsDirectional.fromSTEB(18.0, 0.0, 18.0, 0.0),
          iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
          color: isHighlight ? theme.primary : Colors.transparent,
          textStyle: theme.bodyMedium.override(
                fontFamily: theme.bodyMediumFamily,
                color: isHighlight ? Colors.white : theme.primaryText,
                letterSpacing: 0.0,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                useGoogleFonts: GoogleFonts.asMap().containsKey(theme.bodyMediumFamily),
              ),
          elevation: isHighlight ? 2.0 : 0.0,
          borderSide: BorderSide(
            color: isHighlight ? theme.primary : Colors.transparent,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(12.0),
          hoverColor: isHighlight ? theme.accent1 : theme.alternate,
          hoverBorderSide: BorderSide(
            color: isHighlight ? theme.primary : theme.alternate,
            width: 1.0,
          ),
          hoverTextColor: isHighlight ? theme.primary : theme.primaryText,
        ),
      ),
    );
  }
}
