import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'components/search_sidebar_filters.dart' as components;
import 'package:baul_pandora/components/product_grid/product_grid_widget.dart' as components2;
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'search_results_model.dart';
export 'search_results_model.dart';

class SearchResultsWidget extends StatefulWidget {
  const SearchResultsWidget({
    super.key,
    this.searchQuery,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.sortBy,
    this.inStockOnly,
  });

  final String? searchQuery;
  final String? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final String? sortBy;
  final bool? inStockOnly;

  static String routeName = 'searchResults';
  static String routePath = '/searchResults';

  @override
  State<SearchResultsWidget> createState() => _SearchResultsWidgetState();
}

class _SearchResultsWidgetState extends State<SearchResultsWidget> {
  late SearchResultsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SearchResultsModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final isDesktop = MediaQuery.of(context).size.width >= 992;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        automaticallyImplyLeading: true,
        title: Text(
          'Resultados de búsqueda',
          style: FlutterFlowTheme.of(context).headlineMedium.override(
                fontFamily: 'Readex Pro',
                color: FlutterFlowTheme.of(context).primaryText,
                fontSize: 22.0,
              ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: FlutterFlowTheme.of(context).primaryText),
            onPressed: () {
              scaffoldKey.currentState?.openDrawer();
            },
          ),
        ],
        centerTitle: false,
        elevation: 2.0,
      ),
      drawerScrimColor: Colors.black.withValues(alpha: 0.8),
      drawer: Drawer(
        child: components.SearchSidebarFilters(
          selectedCategoryId: widget.categoryId,
          minPrice: widget.minPrice,
          maxPrice: widget.maxPrice,
          sortBy: widget.sortBy ?? 'created_at',
          inStockOnly: widget.inStockOnly ?? false,
          onFiltersApplied: (catId, minP, maxP, sortB, inStock) {
            Navigator.pop(context); // Close drawer
            context.pushNamed(
              'searchResults',
              queryParameters: {
                'q': widget.searchQuery ?? '', 
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
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FutureBuilder<List<ProductosRow>>(
                        future: ProductosTable().queryRows(
                          queryFn: (q) {
                            q = q.eq('es_variacion', false);
                            if (widget.categoryId != null && widget.categoryId!.isNotEmpty) {
                              q = q.overlaps('categorias', [widget.categoryId!]);
                            }
                            if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
                              q = q.ilike('nombre', '%${widget.searchQuery}%');
                            }
                            if (widget.minPrice != null) {
                              q = q.gte('precio', widget.minPrice!);
                            }
                            if (widget.maxPrice != null) {
                              q = q.lte('precio', widget.maxPrice!);
                            }
                            if (widget.inStockOnly == true) {
                              q = q.gt('stock', 0);
                            }
                            
                            if (widget.sortBy == 'precio_asc') {
                              return q.order('precio', ascending: true);
                            } else if (widget.sortBy == 'precio_desc') {
                              return q.order('precio', ascending: false);
                            } else if (widget.sortBy == 'nombre_asc') {
                              return q.order('nombre', ascending: true);
                            } else {
                              return q.order('created_at', ascending: false);
                            }
                          },
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          final products = snapshot.data!;
                          
                          if (products.isEmpty) {
                            return Center(
                              child: Text(
                                'No se encontraron resultados.',
                                style: FlutterFlowTheme.of(context).bodyLarge,
                              ),
                            );
                          }
                          
                          return GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isDesktop ? 4 : (MediaQuery.sizeOf(context).width >= 768.0 ? 3 : 2),
                              crossAxisSpacing: 8.0,
                              mainAxisSpacing: 8.0,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              // Asegúrate de tener importado el widget correcto para las tarjetas
                              // por ahora usamos un placeholder o importamos ProductGridWidget
                              return components2.ProductGridWidget(
                                key: Key('prod_grid_${index}_of_${products.length}'),
                                productoRow: products[index],
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
