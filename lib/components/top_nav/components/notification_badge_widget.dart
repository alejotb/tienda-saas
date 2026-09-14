import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:badges/badges.dart' as badges;
import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_icon_button.dart';
import 'package:baul_pandora/dropdowns/dropdown_notifications/dropdown_notifications_widget.dart';
import 'package:baul_pandora/services/notification_service.dart';
import '../../../flutter_flow/flutter_flow_animations.dart';

class NotificationBadgeWidget extends StatelessWidget {
  const NotificationBadgeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 8.0, 0.0),
      child: StreamBuilder<int>(
        stream: NotificationService.instance.getUnreadCountStream(),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return badges.Badge(
            badgeContent: Text(
              count.toString(),
              style: FlutterFlowTheme.of(context).titleSmall.override(
                fontFamily: 'Inter',
                color: Colors.white,
              ),
            ),
            showBadge: count > 0,
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
                  'Notifications',
                  style: FlutterFlowTheme.of(context).labelMedium,
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
              child: Visibility(
                visible: loggedIn,
                child: Builder(
                  builder: (context) => FlutterFlowIconButton(
                    borderColor: FlutterFlowTheme.of(context).alternate,
                    borderRadius: 12.0,
                    borderWidth: 1.0,
                    buttonSize: 44.0,
                    fillColor: FlutterFlowTheme.of(context).primaryBackground,
                    icon: const FaIcon(
                      FontAwesomeIcons.bell,
                      size: 24.0,
                    ),
                    onPressed: () async {
                      await showAlignedDialog(
                        barrierColor: Colors.transparent,
                        context: context,
                        isGlobal: false,
                        avoidOverflow: true,
                        targetAnchor: const AlignmentDirectional(-1.0, 1.0)
                            .resolve(Directionality.of(context)),
                        followerAnchor: const AlignmentDirectional(0.0, 0.0)
                            .resolve(Directionality.of(context)),
                        builder: (dialogContext) {
                          return const Material(
                            color: Colors.transparent,
                            child: DropdownNotificationsWidget(),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
