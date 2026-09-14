import 'package:flutter/material.dart';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/dropdowns/dropdown_account/dropdown_account_widget.dart';
import 'package:baul_pandora/dropdowns/dropdown_account_guest/dropdown_account_guest_widget.dart';
import 'package:aligned_tooltip/aligned_tooltip.dart';
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserProfileWidget extends StatelessWidget {
  const UserProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 12.0, 8.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          AlignedTooltip(
            content: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
              child: Text(
                'My Account',
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
              builder: (context) {
                if (!loggedIn || FFAppState().invitado) {
                  return _buildGuestAvatar(context);
                } else {
                  return _buildUserAvatar(context);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestAvatar(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () async {
        await showAlignedDialog(
          context: context,
          isGlobal: false,
          avoidOverflow: true,
          targetAnchor: const AlignmentDirectional(1.0, 1.2).resolve(Directionality.of(context)),
          followerAnchor: const AlignmentDirectional(1.0, -1.0).resolve(Directionality.of(context)),
          builder: (dialogContext) {
            return const Material(
              color: Colors.transparent,
              child: DropdownAccountGuestWidget(),
            );
          },
        );
      },
      child: Container(
        width: 44.0,
        height: 44.0,
        decoration: BoxDecoration(
          border: Border.all(color: FlutterFlowTheme.of(context).primary, width: 2.0),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Image.asset(
            'assets/images/guestUser.png',
            width: 44.0,
            height: 44.0,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    return FutureBuilder<List<UsuariosRow>>(
      future: UsuariosTable().querySingleRow(
        queryFn: (q) => q.eq('id', currentUserUid),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: SizedBox(
              width: 50.0,
              height: 50.0,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(FlutterFlowTheme.of(context).primary),
              ),
            ),
          );
        }
        List<UsuariosRow> usuariosRowList = snapshot.data!;
        final usuario = usuariosRowList.isNotEmpty ? usuariosRowList.first : null;

        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            InkWell(
              splashColor: Colors.transparent,
              focusColor: Colors.transparent,
              hoverColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                await showAlignedDialog(
                  context: context,
                  isGlobal: false,
                  avoidOverflow: true,
                  targetAnchor: const AlignmentDirectional(1.0, 1.2).resolve(Directionality.of(context)),
                  followerAnchor: const AlignmentDirectional(1.0, -1.0).resolve(Directionality.of(context)),
                  builder: (dialogContext) {
                    return const Material(
                      color: Colors.transparent,
                      child: DropdownAccountWidget(),
                    );
                  },
                );
              },
              child: Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  border: Border.all(color: FlutterFlowTheme.of(context).primary, width: 2.0),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: usuario?.photoPath != null && usuario?.photoPath != ''
                      ? CachedNetworkImage(
                          imageUrl: usuario!.photoPath!,
                          width: 44.0,
                          height: 44.0,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Image.asset(
                            'assets/images/guestUser.png',
                            width: 44.0,
                            height: 44.0,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          'assets/images/guestUser.png',
                          width: 44.0,
                          height: 44.0,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
            if (loggedIn && responsiveVisibility(context: context, phone: false))
              Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 0.0, 0.0),
                    child: Text(
                      valueOrDefault<String>(usuario?.nombre, 'Unknown'),
                      style: FlutterFlowTheme.of(context).bodyLarge.override(
                            fontFamily: 'Inter',
                            letterSpacing: 0.0,
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(12.0, 4.0, 0.0, 0.0),
                    child: Text(
                      currentUserEmail,
                      style: FlutterFlowTheme.of(context).labelMedium.override(
                            fontFamily: 'Inter',
                            letterSpacing: 0.0,
                          ),
                    ),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}
