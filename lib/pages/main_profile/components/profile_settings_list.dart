import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/components/modal_edit/modal_edit_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import '../main_profile_model.dart';

class ProfileSettingsList extends StatelessWidget {
  const ProfileSettingsList({
    super.key,
    required this.model,
    required this.updateCallback,
    required this.onSignOut,
  });

  final MainProfileModel model;
  final Future<void> Function() updateCallback;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            boxShadow: const [
              BoxShadow(
                blurRadius: 3.0,
                color: Color(0x33000000),
                offset: Offset(0.0, 1.0),
              )
            ],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSettingsItem(
                context,
                icon: Icon(Icons.person_outline_outlined, color: FlutterFlowTheme.of(context).secondaryText, size: 24.0),
                text: 'Editar perfil',
                onTap: () async {
                  await showModalBottomSheet(
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    context: context,
                    builder: (bottomSheetContext) {
                      return Padding(
                        padding: MediaQuery.viewInsetsOf(bottomSheetContext),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.85,
                          child: const ModalEditWidget(editProfile: true),
                        ),
                      );
                    },
                  );
                  await updateCallback();
                },
              ),
              Divider(height: 1.0, thickness: 1.0, color: FlutterFlowTheme.of(context).alternate),
              _buildSettingsSwitch(
                context,
                icon: Icon(Icons.dark_mode_outlined, color: FlutterFlowTheme.of(context).secondaryText, size: 24.0),
                text: 'Modo oscuro',
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: (val) {
                  setDarkModeSetting(context, val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
              Divider(height: 1.0, thickness: 1.0, color: FlutterFlowTheme.of(context).alternate),
              _buildSettingsItem(
                context,
                icon: Icon(Icons.language_outlined, color: FlutterFlowTheme.of(context).secondaryText, size: 24.0),
                text: 'Idioma',
                onTap: () async {
                  _showLanguageModal(context);
                },
              ),
              if ((AppStateNotifier.instance.currentUserRow?.isAdmin ?? false) || FFAppState().isAdmin) ...[
                Divider(height: 1.0, thickness: 1.0, color: FlutterFlowTheme.of(context).alternate),
                _buildSettingsItem(
                  context,
                  icon: Icon(Icons.manage_history_rounded, color: FlutterFlowTheme.of(context).primary, size: 24.0),
                  text: 'Auditoría',
                  onTap: () {
                    context.pushNamed('adminAuditoria');
                  },
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 0.0),
          child: FFButtonWidget(
            onPressed: () async {
              GoRouter.of(context).prepareAuthEvent();
              await authManager.signOut();
              GoRouter.of(context).clearRedirectLocation();
              onSignOut();
            },
            text: 'CERRAR SESIÓN',
            options: FFButtonOptions(
              height: 48.0,
              padding: const EdgeInsetsDirectional.fromSTEB(32.0, 0.0, 32.0, 0.0),
              color: FlutterFlowTheme.of(context).secondaryBackground,
              textStyle: FlutterFlowTheme.of(context).bodyLarge,
              borderSide: BorderSide(
                color: FlutterFlowTheme.of(context).alternate,
                width: 2.0,
              ),
              borderRadius: BorderRadius.circular(50.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required Widget icon,
    required String text,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
        child: Row(
          children: [
            icon,
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 0.0, 0.0),
                child: Text(text, style: FlutterFlowTheme.of(context).bodyLarge),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: FlutterFlowTheme.of(context).secondaryText, size: 24.0),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSwitch(
    BuildContext context, {
    required Widget icon,
    required String text,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 8.0),
      child: Row(
        children: [
          icon,
          Expanded(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 0.0, 0.0),
              child: Text(text, style: FlutterFlowTheme.of(context).bodyLarge),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: FlutterFlowTheme.of(context).primary,
          ),
        ],
      ),
    );
  }

  void _showLanguageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20.0),
              topRight: Radius.circular(20.0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Seleccionar Idioma',
                style: FlutterFlowTheme.of(context).headlineSmall,
              ),
              const SizedBox(height: 24.0),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text('Español', style: FlutterFlowTheme.of(context).bodyLarge),
                trailing: Icon(Icons.check, color: FlutterFlowTheme.of(context).primary),
                onTap: () {
                  Navigator.pop(context);
                  // Lógica para cambiar a Español (por implementar luego)
                },
              ),
              Divider(color: FlutterFlowTheme.of(context).alternate),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text('English', style: FlutterFlowTheme.of(context).bodyLarge),
                onTap: () {
                  Navigator.pop(context);
                  // Lógica para cambiar a Inglés (por implementar luego)
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
