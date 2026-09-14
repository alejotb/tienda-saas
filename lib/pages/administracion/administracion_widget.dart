import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/services/woocommerce_sync_service.dart';
import 'package:baul_pandora/services/isar_service.dart';
import 'package:baul_pandora/services/local_inventory_service.dart';
import 'package:flutter/material.dart';
import 'administracion_model.dart';
import 'views/admin_general_view.dart';

export 'administracion_model.dart';

class AdministracionWidget extends StatefulWidget {
  const AdministracionWidget({super.key});

  static String routeName = 'administracion';
  static String routePath = '/administracion';

  @override
  State<AdministracionWidget> createState() => _AdministracionWidgetState();
}

class _AdministracionWidgetState extends State<AdministracionWidget> {
  late AdministracionModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdministracionModel());
    _initAdminDatabase();
  }

  Future<void> _initAdminDatabase() async {
    try {
      await IsarService.instance.init();
      print("o. Isar inicializado. Iniciando sincronizaciA3n de inventario...");
      await LocalInventoryService.instance.syncProductsFromCloud();
    } catch (e) {
      print("?O Error inicializando DB de Admin: $e");
    }
  }

  @override
  void dispose() {
    IsarService.instance.close();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⏳ Sincronizando catálogo en la base de datos...'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );

            final result = await WooCommerceSyncService().syncAllProducts();

            if (context.mounted) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result.message),
                  backgroundColor: result.success ? const Color(0xFF16A34A) : Colors.red,
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }

            safeSetState(() {});
          },
          backgroundColor: FlutterFlowTheme.of(context).primary,
          elevation: 8.0,
          child: Icon(
            Icons.sync,
            color: FlutterFlowTheme.of(context).primaryText,
            size: 28.0,
          ),
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const TopNavWidget(),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  color: FlutterFlowTheme.of(context).primaryBackground,
                  child: const SizedBox.expand(
                    child: AdminGeneralView(), // Carga directamente el dashboard en lugar de usar sidebar
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
