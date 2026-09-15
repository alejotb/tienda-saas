import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/services/cart_service.dart';
import 'package:baul_pandora/services/store_service.dart';
import 'package:baul_pandora/services/store_theme_service.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';

import 'components/featured_categories_widget.dart';
import 'components/product_list_area.dart';
import 'package:baul_pandora/components/barcode_scanner_modal.dart' as baul_pandora;
import 'package:baul_pandora/pages/search_results/components/search_sidebar_filters.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:baul_pandora/services/ai/ai_product_service.dart';

import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'main_home_page_model.dart';
export 'main_home_page_model.dart';

class MainHomePageWidget extends StatefulWidget {
  const MainHomePageWidget({super.key});

  static String routeName = 'mainHomePage';
  static String routePath = '/mainHomePage';

  @override
  State<MainHomePageWidget> createState() => _MainHomePageWidgetState();
}

class _MainHomePageWidgetState extends State<MainHomePageWidget> {
  late MainHomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MainHomePageModel());
    debugPrint('DEBUG: Cart items on Home Page: ${FFAppState().itemsCarrito.map((e) => e.idProducto).toList()}');

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (FFAppState().activeStoreId.isNotEmpty && StoreThemeService.instance.currentStore == null) {
        final store = await StoreService.instance.getStoreById(FFAppState().activeStoreId);
        if (store != null) {
          StoreThemeService.instance.setStore(store);
        }
      }
      if (loggedIn) {
        await CartService.instance.fetchRemoteCart();
        safeSetState(() {});
      }
      _model.usuario = await UsuariosTable().queryRows(
        queryFn: (q) => q.eq(
          'id',
          currentUserUid,
        ),
      );
      if (_model.usuario != null && (_model.usuario)!.isNotEmpty) {
        final user = _model.usuario!.firstOrNull;
        if (user != null) {
          FFAppState().isAdmin = user.isAdmin;
          _model.favoritos = user.favoriteItems.toList().cast<String>();
        }
        safeSetState(() {});
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        drawerScrimColor: Colors.black.withValues(alpha: 0.8),
        drawer: Drawer(
          child: SearchSidebarFilters(
            selectedCategoryId: _model.selectedCategoryId,
            onFiltersApplied: (catId, minP, maxP, sortB, inStock) {
              scaffoldKey.currentState?.closeDrawer();
              context.pushNamed(
                'searchResults',
                queryParameters: {
                  'category': catId,
                  'minPrice': minP?.toString(),
                  'maxPrice': maxP?.toString(),
                  'sortBy': sortB,
                  'inStockOnly': inStock.toString(),
                }.withoutNulls,
              );
            },
          ),
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 8.0, 0.0),
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 1400.0,
                    ),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).primaryBackground,
                        width: 2.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 16.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              wrapWithModel(
                                model: _model.topNavModel,
                                updateCallback: () async { safeSetState(() {}); },
                                child: const TopNavWidget(),
                              ),
                              FeaturedCategoriesWidget(
                                model: _model,
                                updateCallback: () async { safeSetState(() {}); },
                              ),
                              ],
                              ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        decoration: InputDecoration(
                                          hintText: 'Buscar productos...',
                                          prefixIcon: const Icon(Icons.search),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12.0),
                                          ),
                                          filled: true,
                                          fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                                        ),
                                        onSubmitted: (value) {
                                          if (value.isNotEmpty) {
                                            context.pushNamed(
                                              'searchResults',
                                              queryParameters: {'q': value}.withoutNulls,
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8.0),
                                    IconButton(
                                      icon: Icon(
                                        Icons.qr_code_scanner,
                                        color: FlutterFlowTheme.of(context).secondaryText,
                                        size: 28,
                                      ),
                                      onPressed: () async {
                                        final code = await Navigator.push<String>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const baul_pandora.BarcodeScannerModal(),
                                          ),
                                        );
                                        if (code != null && code.isNotEmpty) {
                                          final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(code);
                                          final products = await ProductosTable().queryRows(
                                            queryFn: (q) => isUuid ? q.eq('id', code).limit(1) : q.eq('codigo_barras', code).limit(1),
                                          );
                                          if (products.isNotEmpty && context.mounted) {
                                            context.pushNamed(
                                              'productDetails',
                                              queryParameters: {
                                                'productRow': serializeParam(
                                                  products.first,
                                                  ParamType.SupabaseRow,
                                                ),
                                              }.withoutNulls,
                                            );
                                          } else if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Producto no encontrado')));
                                          }
                                        }
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.image_search,
                                        color: FlutterFlowTheme.of(context).secondaryText,
                                        size: 28,
                                      ),
                                      onPressed: () async {
                                        final picker = ImagePicker();
                                        final xfile = await picker.pickImage(source: ImageSource.gallery);
                                        if (xfile != null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Analizando imagen para buscar...')),
                                          );
                                          try {
                                            final bytes = await xfile.readAsBytes();
                                            final keyword = await AIProductService.instance.identifyProductForSearch(bytes);
                                            if (keyword != null && keyword.isNotEmpty) {
                                              _searchController.text = keyword;
                                              if (context.mounted) {
                                                context.pushNamed(
                                                  'searchResults',
                                                  queryParameters: {'q': keyword}.withoutNulls,
                                                );
                                              }
                                            } else {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('No se pudo identificar el producto en la imagen')),
                                                );
                                              }
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Error de IA: ${e.toString().replaceAll('Exception:', '')}')),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),

                        Expanded(
                          child: ProductListArea(
                            model: _model,
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
    );
  }
}

