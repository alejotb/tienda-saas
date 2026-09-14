import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/pages/administracion/views/admin_audit_view.dart';

class AdminAuditoriaPage extends StatefulWidget {
  const AdminAuditoriaPage({super.key});

  static String routeName = 'adminAuditoria';
  static String routePath = '/adminAuditoria';

  @override
  State<AdminAuditoriaPage> createState() => _AdminAuditoriaPageState();
}

class _AdminAuditoriaPageState extends State<AdminAuditoriaPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        top: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopNavWidget(),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: AdminAuditView(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
