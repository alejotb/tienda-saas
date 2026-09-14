import 'package:baul_pandora/components/full_cart_summary/cart_summary_component.dart';
import 'package:baul_pandora/components/full_cart_list/cart_list_component.dart';
import 'package:baul_pandora/components/full_cart_selection/selection_header_component.dart';
import 'package:baul_pandora/components/full_cart_selection/apartado_payment_sheet.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/pages/full_cart_view/components/cart_out_of_stock_section.dart';
import 'package:baul_pandora/pages/full_cart_view/components/apartados_list_component.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'full_cart_view_model.dart';
import 'package:baul_pandora/index.dart';

class FullCartViewWidget extends StatefulWidget {
  const FullCartViewWidget({
    super.key,
    bool? subPage,
    String? subPageName,
  }) : subPage = subPage ?? false,
       subPageName = subPageName ?? 'Product Details';

  final bool subPage;
  final String subPageName;

  static String routeName = 'fullCartView';
  static String routePath = '/fullCartView';

  @override
  State<FullCartViewWidget> createState() => _FullCartViewWidgetState();
}

class _FullCartViewWidgetState extends State<FullCartViewWidget> {
  late FullCartViewModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = FullCartViewModel();
    _model.initState(context);
    _model.validateCartStock(context);
    _model.loadApartados();
    _model.updateSelectedTotal();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _navigateToApartadoPayment() async {
    final cartDetails = _model.selectedItemsDetails.toList();
    final apartadosDetails = _model.selectedApartadosDetails.toList();
    
    debugPrint('DEBUG: Navegando a pago. CartDetails: $cartDetails');
    debugPrint('DEBUG: Navegando a pago. ApartadosDetails: $apartadosDetails');
    
    // Combinar listas. 
    final combinedProductDetails = [...cartDetails, ...apartadosDetails];
    
    debugPrint('DEBUG: Navegando a pago. Combined: $combinedProductDetails');
    
    if (combinedProductDetails.isEmpty) return;
    
    context.pushNamed(
      ApartadoPaymentPage.routeName,
      queryParameters: {
        'productDetailsJson': jsonEncode(combinedProductDetails),
      },
    );
  }

  void _showPagoApartadoDialog(String pedidoId, double saldo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ApartadoPaymentSheet(
        pedidoId: pedidoId,
        saldoPendiente: saldo,
      ),
    ).then((value) {
      if (value == true) {
        _model.loadApartados();
        safeSetState(() {});
      }
    });
  }

  Widget _buildBreadcrumbs() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 0.0, 0.0),
      child: InkWell(
        onTap: () => context.pushNamed(MainHomePageWidget.routeName),
        child: Text('Inicio > Mi Carrito', style: FlutterFlowTheme.of(context).bodyMedium),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          _buildTabButton('carrito', 'Carrito'),
          const SizedBox(width: 8),
          _buildTabButton('apartados', 'Apartados'),
        ],
      ),
    );
  }

  Widget _buildTabButton(String value, String label) {
    final isActive = _model.activeTab == value;
    return InkWell(
      onTap: () {
        _model.activeTab = value;
        safeSetState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: FlutterFlowTheme.of(context).primary),
        ),
        child: Text(
          label,
          style: FlutterFlowTheme.of(context).bodyMedium.override(
                fontFamily: 'Inter',
                color: isActive ? Colors.white : FlutterFlowTheme.of(context).primary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ),
    );
  }

  Widget _buildLeftColumn(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        boxShadow: const [
          BoxShadow(
            blurRadius: 4.0,
            color: Color(0x33000000),
            offset: Offset(0.0, 2.0),
          )
        ],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabSelector(),
            if (_model.activeTab == 'carrito') ...[
              const SelectionHeaderComponent(),
              CartListComponent(
                items: FFAppState().itemsCarrito.toList(),
                onUpdate: () {
                  _model.validateCartStock(context);
                  _model.updateSelectedTotal();
                  safeSetState(() {});
                },
              ),
            ] else ...[
              const SelectionHeaderComponent(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tus Apartados',
                        style: FlutterFlowTheme.of(context).titleLarge),
                    const SizedBox(height: 12),
                    Consumer<FullCartViewModel>(
                      builder: (context, model, child) {
                        if (model.isLoadingApartados) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (model.apartados.isEmpty) {
                          return Text('No tienes productos apartados.',
                              style: FlutterFlowTheme.of(context).bodySmall);
                        } else {
                          return ApartadosListComponent(
                            apartados: model.apartados,
                            apartadosSeleccionados: model.apartadosSeleccionados,
                            onToggleSeleccion: (itemId) {
                              model.toggleApartadoSeleccion(itemId);
                              safeSetState(() {});
                            },
                            onUpdateApartadoItem: (apartadoId, itemId, delta) {
                              model.updateApartadoItemLocal(
                                  apartadoId, itemId, delta);
                              safeSetState(() {});
                            },
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRightColumn(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).secondaryBackground,
        boxShadow: const [
          BoxShadow(
            blurRadius: 4.0,
            color: Color(0x33000000),
            offset: Offset(0.0, 2.0),
          )
        ],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Consumer<FullCartViewModel>(
        builder: (context, model, child) {
          return CartSummaryComponent(
            items: model.allSelectedDetails,
            subtotal: model.subtotal,
            totalPagado: model.totalPagado,
            total: model.total,
            bcvRate: model.bcvRateGetter,
            onApartar: () => _navigateToApartadoPayment(),
            onComprar: () {
              debugPrint(
                  'DEBUG: selectedItemsDetails antes de enviar: ${model.selectedItemsDetails}');
              context.pushNamed(
                CheckoutFullPageWidget.routeName,
                queryParameters: {
                  'subPage': 'false',
                  'subPageName': 'Checkout',
                  'productIdsJson': jsonEncode([
                    ...model.selectedItemsDetails.map((item) => {
                          'id': item['idProducto'] ?? item['id'],
                          'cantidad': item['cantidad'] ?? 1
                        }),
                    ...model.selectedApartadosDetails
                        .where((item) => item['id'] != null) // Filtrar nulos
                        .map((item) {
                      debugPrint(
                          'DEBUG: Enviando ID de apartado: ${item['id']}');
                      return {
                        'id': item['id'],
                        'cantidad': item['cantidad'] ?? 1,
                        'pedido_id': item['pedido_id'],
                      };
                    })
                  ]),
                  'totalPagado': model.totalPagado.toString(),
                  'bcvRate': model.bcvRateGetter.toString(),
                },
              );
            },
            isApartarEnabled: model.selectedItemIds.isNotEmpty &&
                model.apartadosSeleccionados.isEmpty,
            isComprarEnabled: model.selectedItemIds.isNotEmpty ||
                model.apartadosSeleccionados.isNotEmpty,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FullCartViewModel>.value(
      value: _model,
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TopNavWidget(),
              _buildBreadcrumbs(),
              OutOfStockSection(itemsSinStock: _model.itemsSinStock),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Mi Carrito',
                    style: FlutterFlowTheme.of(context).displaySmall),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 900) {
                      return Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            16.0, 0.0, 16.0, 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 24.0),
                                  child: _buildLeftColumn(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 32.0),
                            Expanded(
                              flex: 1,
                              child: _buildRightColumn(context),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              16.0, 0.0, 16.0, 44.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildLeftColumn(context),
                              const SizedBox(height: 16.0),
                              _buildRightColumn(context),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
