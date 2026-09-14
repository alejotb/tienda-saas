import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/pages/administracion/views/admin_products_view.dart';

class AdminInventarioPage extends StatefulWidget {
  const AdminInventarioPage({super.key});

  static String routeName = 'adminInventario';
  static String routePath = '/adminInventario';

  @override
  State<AdminInventarioPage> createState() => _AdminInventarioPageState();
}

class _AdminInventarioPageState extends State<AdminInventarioPage> {
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: const AdminProductsView(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
