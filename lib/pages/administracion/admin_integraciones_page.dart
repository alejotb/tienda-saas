import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/pages/administracion/views/admin_integrations_view.dart';

class AdminIntegracionesPage extends StatefulWidget {
  const AdminIntegracionesPage({super.key});

  static String routeName = 'adminIntegraciones';
  static String routePath = '/adminIntegraciones';

  @override
  State<AdminIntegracionesPage> createState() => _AdminIntegracionesPageState();
}

class _AdminIntegracionesPageState extends State<AdminIntegracionesPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: const SafeArea(
        child: Column(
          children: [
            TopNavWidget(),
            Expanded(
              child: AdminIntegrationsView(),
            ),
          ],
        ),
      ),
    );
  }
}
