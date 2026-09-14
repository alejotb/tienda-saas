import 'dart:async';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/services/notification_service.dart';
import 'package:baul_pandora/components/main_logo/main_logo_widget.dart';
import 'package:baul_pandora/components/barcode_scanner_modal.dart' as baul_pandora;
import 'package:baul_pandora/dropdowns/dropdown_account/dropdown_account_widget.dart';
import 'package:baul_pandora/dropdowns/dropdown_account_guest/dropdown_account_guest_widget.dart';
import 'package:baul_pandora/dropdowns/dropdown_notifications/dropdown_notifications_widget.dart';
import 'package:baul_pandora/dropdowns/order_summary_new/order_summary_new_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_animations.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_icon_button.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_widgets.dart';
import 'package:baul_pandora/index.dart';
import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:badges/badges.dart' as badges;
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'top_nav_model.dart';
export 'top_nav_model.dart';
import 'components/theme_toggle_widget.dart';
import 'components/nav_buttons_widget.dart';
import 'components/notification_badge_widget.dart';
import 'components/user_profile_widget.dart';
import 'components/cart_badge_widget.dart';

class TopNavWidget extends StatefulWidget {
  const TopNavWidget({super.key});

  @override
  State<TopNavWidget> createState() => _TopNavWidgetState();
}

class _TopNavWidgetState extends State<TopNavWidget>
    with TickerProviderStateMixin {
  late TopNavModel _model;
  int _unreadCount = 0;
  StreamSubscription? _notificationSubscription;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TopNavModel());

    // Escuchar el contador de notificaciones en tiempo real
    if (loggedIn) {
      _notificationSubscription = NotificationService.instance
          .getUnreadCountStream()
          .listen((count) {
        setState(() {
          _unreadCount = count;
        });
      });
    }

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {});

    animationsMap.addAll({
      'containerOnActionTriggerAnimation': AnimationInfo(
        trigger: AnimationTrigger.onActionTrigger,
        applyInitialState: true,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: const Offset(-40.0, 0.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
    });
    setupAnimations(
      animationsMap.values.where((anim) =>
          anim.trigger == AnimationTrigger.onActionTrigger ||
          !anim.applyInitialState),
      this,
    );
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _model.maybeDispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [

        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                  child: wrapWithModel(
                    model: _model.mainLogoModel,
                    updateCallback: () => safeSetState(() {}),
                    child: const MainLogoWidget(),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (responsiveVisibility(
                    context: context,
                    phone: false,
                  ))
                    ThemeToggleWidget(
                      animationsMap: animationsMap,
                      vsync: this,
                    ),
                  NavButtonsWidget(parentContext: context),
                  NotificationBadgeWidget(),
                  CartBadgeWidget(),
                  UserProfileWidget(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
