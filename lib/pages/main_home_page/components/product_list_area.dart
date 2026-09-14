import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/components/empty_products/empty_products_widget.dart';
import 'package:baul_pandora/components/loading_list/loading_list_widget.dart';
import 'package:baul_pandora/components/product_grid/product_grid_widget.dart';
import 'package:baul_pandora/components/tarjeta_producto/tarjeta_producto_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main_home_page_model.dart';

class ProductListArea extends StatelessWidget {
  const ProductListArea({
    super.key,
    required this.model,
  });

  final MainHomePageModel model;

  @override
  Widget build(BuildContext context) {
    final isDesktop = responsiveVisibility(
      context: context,
      phone: false,
      tablet: false,
    );

    final isMobile = responsiveVisibility(
      context: context,
      tabletLandscape: false,
      desktop: false,
    );

    return Stack(
      children: [
        if (isDesktop) _buildProductGrid(context),
        if (isMobile) _buildProductList(context),
      ],
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    return Visibility(
      visible: responsiveVisibility(
        context: context,
        phone: false,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 32.0),
        child: FutureBuilder<List<ProductosRow>>(
          future: FFAppState().productList(
            overrideCache: true,
            requestFn: () => ProductosTable().queryRows(
              queryFn: (q) {
                q = q.eq('es_variacion', false);
                if (model.selectedCategoryName?.toLowerCase() == 'novedades') {
                  final lastMonth = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
                  q = q.gte('created_at', lastMonth);
                } else if (model.selectedCategoryId != null && model.selectedCategoryId!.isNotEmpty) {
                  q = q.overlaps('categorias', [model.selectedCategoryId!]);
                }
                return q.order('created_at', ascending: false);
              },
            ),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: SizedBox(
                  height: 300.0,
                  child: LoadingListWidget(),
                ),
              );
            }
            List<ProductosRow> products = snapshot.data!;
            print("DEBUG: Query returned ${products.length} products.");

            if (products.isEmpty) {
              return const EmptyProductsWidget();
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          Scaffold.of(context).openDrawer();
                        },
                        child: Row(
                          children: [
                            Icon(Icons.filter_list, color: FlutterFlowTheme.of(context).primaryText),
                            const SizedBox(width: 8.0),
                            Text(
                              'Filtrar y Ordenar',
                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${products.length} productos',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              font: GoogleFonts.inter(),
                              color: FlutterFlowTheme.of(context).secondaryText,
                            ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: () {
                  if (MediaQuery.sizeOf(context).width >= 1371.0) return 4;
                  if (MediaQuery.sizeOf(context).width >= 768.0) return 3;
                  return 2;
                }(),
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.9,
              ),

              scrollDirection: Axis.vertical,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductGridWidget(
                  key: Key('prod_grid_${index}_of_${products.length}'),
                  productoRow: product,
                );
              },
            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductList(BuildContext context) {
    return Visibility(
      visible: responsiveVisibility(
        context: context,
        tablet: false,
        tabletLandscape: false,
        desktop: false,
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 32.0),
        child: FutureBuilder<List<ProductosRow>>(
          future: FFAppState().productList(
            overrideCache: true,
            requestFn: () => ProductosTable().queryRows(
              queryFn: (q) {
                q = q.eq('es_variacion', false);
                if (model.selectedCategoryName?.toLowerCase() == 'novedades') {
                  final lastMonth = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
                  q = q.gte('created_at', lastMonth);
                } else if (model.selectedCategoryId != null && model.selectedCategoryId!.isNotEmpty) {
                  q = q.overlaps('categorias', [model.selectedCategoryId!]);
                }
                return q.order('created_at', ascending: false);
              },
            ),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: SizedBox(
                  width: 50.0,
                  height: 50.0,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                ),
              );
            }
            List<ProductosRow> products = snapshot.data!;
            print("DEBUG: Query returned ${products.length} products.");

            if (products.isEmpty) {
              return const EmptyProductsWidget();
            }

            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: Divider(height: 1, thickness: 1)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            Scaffold.of(context).openDrawer();
                          },
                          child: Row(
                            children: [
                              Icon(Icons.filter_list, color: FlutterFlowTheme.of(context).primaryText),
                              const SizedBox(width: 8.0),
                              Text(
                                'Filtrar y Ordenar',
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                      font: GoogleFonts.inter(),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${products.length} productos',
                          style: FlutterFlowTheme.of(context).bodySmall.override(
                                font: GoogleFonts.inter(),
                                color: FlutterFlowTheme.of(context).secondaryText,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: Divider(height: 1, thickness: 1)),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 8.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        return TarjetaProductoWidget(
                          key: Key('prod_list_${index}_of_${products.length}'),
                          productoRow: product,
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
