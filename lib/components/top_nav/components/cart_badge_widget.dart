import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_icon_button.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/dropdowns/order_summary_new/order_summary_new_widget.dart';
import 'package:badges/badges.dart' as badges;
import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:google_fonts/google_fonts.dart';

class CartBadgeWidget extends StatelessWidget {
  const CartBadgeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<FFAppState>();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 8.0, 0.0),
      child: badges.Badge(
        badgeContent: Text(
          valueOrDefault<String>(
            appState.itemsCarrito.length.toString(),
            '0',
          ),
          style: FlutterFlowTheme.of(context).titleSmall.override(
            fontFamily: 'Inter',
            color: Colors.white,
            letterSpacing: 0.0,
          ),
        ),
        showBadge: appState.itemsCarrito.isNotEmpty,
        shape: badges.BadgeShape.circle,
        badgeColor: FlutterFlowTheme.of(context).primary,
        elevation: 4.0,
        padding: const EdgeInsets.all(8.0),
        position: badges.BadgePosition.topEnd(),
        animationType: badges.BadgeAnimationType.scale,
        toAnimate: true,
        child: AlignedTooltip(
          content: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
            child: Text(
              'My Cart',
              style: FlutterFlowTheme.of(context).labelMedium.override(
                fontFamily: 'Inter',
                letterSpacing: 0.0,
              ),
            ),
          ),
          offset: 4.0,
          preferredDirection: AxisDirection.down,
          borderRadius: BorderRadius.circular(8.0),
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          elevation: 3.0,
          tailBaseWidth: 16.0,
          tailLength: 8.0,
          waitDuration: const Duration(milliseconds: 50),
          showDuration: const Duration(milliseconds: 600),
          triggerMode: TooltipTriggerMode.tap,
          child: Builder(
            builder: (context) => FlutterFlowIconButton(
              borderColor: FlutterFlowTheme.of(context).primary,
              borderRadius: 12.0,
              borderWidth: 2.0,
              buttonSize: 44.0,
              fillColor: FlutterFlowTheme.of(context).accent1,
              icon: Icon(
                Icons.shopping_cart_outlined,
                color: FlutterFlowTheme.of(context).primaryText,
                size: 22.0,
              ),
              onPressed: () async {
                showAlignedDialog(
                  barrierColor: FlutterFlowTheme.of(context).accent4,
                  context: context,
                  isGlobal: false,
                  avoidOverflow: true,
                  targetAnchor: const AlignmentDirectional(1.0, 1.2)
                      .resolve(Directionality.of(context)),
                  followerAnchor: const AlignmentDirectional(1.0, -1.0)
                      .resolve(Directionality.of(context)),
                  builder: (dialogContext) {
                    return const Material(
                      color: Colors.transparent,
                      child: OrderSummaryNewWidget(),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
