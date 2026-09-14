import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_animations.dart';
import 'package:baul_pandora/components/gradient_button/gradient_button_widget.dart';
import 'package:baul_pandora/index.dart';

class CheckoutBreadcrumbs extends StatelessWidget {
  const CheckoutBreadcrumbs({
    super.key,
    this.subPage,
    required this.subPageName,
  });

  final bool? subPage;
  final String subPageName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 0.0, 0.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            GradientButtonWidget(
              action: () async {
                context.pushNamed(MainHomePageWidget.routeName);
              },
            ),
            if (subPage == true)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 4.0, 0.0),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  size: 16.0,
                ),
              ),
            if (subPage == true)
              InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  context.safePop();
                },
                child: Container(
                  height: 32.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).alternate,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  alignment: const AlignmentDirectional(0.0, 0.0),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    child: Text(
                      valueOrDefault<String>(
                        subPageName,
                        'Nombre de la página',
                      ),
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
                ),
              ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 4.0, 0.0),
              child: Icon(
                Icons.chevron_right_rounded,
                color: FlutterFlowTheme.of(context).secondaryText,
                size: 16.0,
              ),
            ),
            Container(
              height: 32.0,
              decoration: BoxDecoration(
                color: FlutterFlowTheme.of(context).accent1,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: FlutterFlowTheme.of(context).primary,
                  width: 2.0,
                ),
              ),
              alignment: const AlignmentDirectional(0.0, 0.0),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                child: Text(
                  'Verificar',
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
          ],
        ).animateOnPageLoad(
          AnimationInfo(
            trigger: AnimationTrigger.onPageLoad,
            effectsBuilder: () => [
              VisibilityEffect(duration: 1.ms),
              FadeEffect(
                curve: Curves.easeInOut,
                delay: 0.0.ms,
                duration: 600.0.ms,
                begin: 0.0,
                end: 1.0,
              ),
              MoveEffect(
                curve: Curves.easeInOut,
                delay: 0.0.ms,
                duration: 600.0.ms,
                begin: const Offset(0.0, -70.0),
                end: const Offset(0.0, 0.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
