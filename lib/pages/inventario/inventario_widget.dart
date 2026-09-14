import 'package:baul_pandora/components/stock_update_modal/stock_update_widget.dart';
import 'package:baul_pandora/pages/product_create/product_create_widget.dart';
import 'package:baul_pandora/repositories/inventory_factory.dart';
import 'package:baul_pandora/models/inventory_models.dart';

import 'package:baul_pandora/components/empty_products/empty_products_widget.dart';
import 'package:baul_pandora/components/product_inventory_list_view/product_inventory_list_view_widget.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart'
    show TopNavWidget;
import 'package:baul_pandora/dropdowns/dropdown_inventario_menu/dropdown_inventario_menu_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/backend/supabase/database/tables/usuarios.dart';
import 'package:baul_pandora/backend/supabase/database/tables/productos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'inventario_model.dart';
export 'inventario_model.dart';

class InventarioWidget extends StatefulWidget {
  const InventarioWidget({super.key});

  static String routeName = 'inventario';
  static String routePath = '/inventario';

  @override
  State<InventarioWidget> createState() => _InventarioWidgetState();
}

class _InventarioWidgetState extends State<InventarioWidget> {
  late InventarioModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InventarioModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      // 1. Obtener el repositorio según el rol y la plataforma
      _model.inventoryRepo = InventoryFactory.getRepository();
      
      // 2. Sincronizar datos (Isar bajará la data de Supabase si es admin)
      await _model.inventoryRepo!.sync();

      // 3. Cargar el usuario (esto ya estaba)
      _model.usuario = await UsuariosTable().queryRows(
        queryFn: (q) => q.eq('id', currentUserUid),
      );
      
      // Refrescar la UI para que el FutureBuilder se dispare con el repo listo
      setState(() {});
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (dialogContext) {
                  return Dialog(
                    elevation: 0,
                    insetPadding: EdgeInsets.zero,
                    backgroundColor: Colors.transparent,
                    alignment: const AlignmentDirectional(0.0, 0.0)
                        .resolve(Directionality.of(context)),
                    child: GestureDetector(
                      onTap: () {
                        FocusScope.of(dialogContext).unfocus();
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      child: const DropdownInventarioMenuWidget(),
                    ),
                  );
                },
              );
            },
            backgroundColor: FlutterFlowTheme.of(context).primary,
            elevation: 8.0,
            child: Icon(
              Icons.add_rounded,
              color: FlutterFlowTheme.of(context).info,
              size: 24.0,
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          title: Text(
            'Inventario',
            style: FlutterFlowTheme.of(context).displaySmall.override(
                  font: GoogleFonts.interTight(
                    fontWeight:
                        FlutterFlowTheme.of(context).displaySmall.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).displaySmall.fontStyle,
                  ),
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).displaySmall.fontWeight,
                  fontStyle:
                      FlutterFlowTheme.of(context).displaySmall.fontStyle,
                ),
          ),
           actions: [
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 8.0),
               child: ElevatedButton.icon(
                 onPressed: () async {
                   context.pushNamed(ProductCreateWidget.routeName);
                 },
                 icon: const Icon(Icons.add),
                 label: const Text('Nuevo Producto'),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: FlutterFlowTheme.of(context).primary,
                   foregroundColor: Colors.white,
                 ),
               ),
             ),
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 8.0),
               child: ElevatedButton.icon(
                 onPressed: () async {
                   await showDialog(
                     context: context,
                     builder: (dialogContext) {
                       return Dialog(
                         elevation: 0,
                         insetPadding: EdgeInsets.zero,
                         backgroundColor: Colors.transparent,
                         alignment: const AlignmentDirectional(0.0, 0.0)
                             .resolve(Directionality.of(context)),
                         child: const StockUpdateWidget(),
                       );
                     },
                   );
                 },
                 icon: const Icon(Icons.inventory),
                 label: const Text('Actualizar Stock'),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: FlutterFlowTheme.of(context).secondary,
                   foregroundColor: Colors.white,
                 ),
               ),
             ),
           ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                if (responsiveVisibility(
                  context: context,
                  phone: false,
                ))
                  wrapWithModel(
                    model: _model.topNavModel,
                    updateCallback: () => safeSetState(() {}),
                    child: const TopNavWidget(),
                  ),
                Align(
                  alignment: const AlignmentDirectional(0.0, 0.0),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxWidth: 1170.0,
                    ),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      30.0, 4.0, 0.0, 0.0),
                                  child: Text(
                                    'Imagen',
                                    style: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16.0, 4.0, 0.0, 0.0),
                                  child: Text(
                                    'Nombre',
                                    style: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                      16.0, 4.0, 0.0, 0.0),
                                  child: Text(
                                    'Stock',
                                    style: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 32.0),
                            child: FutureBuilder<List<LocalProduct>>(
                               future: _model.inventoryRepo?.getProducts(),
                               builder: (context, snapshot) {
                                 if (_model.inventoryRepo == null || !snapshot.hasData) {
                                   return Center(
                                     child: SizedBox(
                                       width: 50.0,
                                       height: 50.0,
                                       child: CircularProgressIndicator(
                                         valueColor:
                                             AlwaysStoppedAnimation<Color>(
                                           FlutterFlowTheme.of(context).primary,
                                         ),
                                       ),
                                     ),
                                   );
                                 }
                                 
                                 List<LocalProduct> listViewProductosRowList =
                                     snapshot.data!;

                                 if (listViewProductosRowList.isEmpty) {
                                   return const Center(
                                     child: SizedBox(
                                       width: 300.0,
                                       height: 300.0,
                                       child: EmptyProductsWidget(),
                                     ),
                                   );
                                 }

                                 return ListView.builder(
                                   padding: EdgeInsets.zero,
                                   shrinkWrap: true,
                                   scrollDirection: Axis.vertical,
                                   itemCount: listViewProductosRowList.length,
                                   itemBuilder: (context, listViewIndex) {
                                     final listViewProductosRow =
                                         listViewProductosRowList[listViewIndex];
                                     return ProductInventoryListViewWidget(
                                       key: Key(
                                           'Keyl6z_${listViewIndex}_of_${listViewProductosRowList.length}'),
                                       // IMPORTANTE: Aquí el widget hijo debe aceptar LocalProduct o 
                                       // debemos convertirlo a un formato que entienda.
                                       productRef: listViewProductosRow, 
                                     );
                                   },
                                 );
                               },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
