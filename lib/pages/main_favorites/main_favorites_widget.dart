import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/components/empty_products/empty_products_widget.dart';
import 'package:baul_pandora/components/loading_list/loading_list_widget.dart';
import 'package:baul_pandora/components/product_list_view/product_list_view_widget.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/services/favorites_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'main_favorites_model.dart';
export 'main_favorites_model.dart';

class MainFavoritesWidget extends StatefulWidget {
  const MainFavoritesWidget({super.key});

  static String routeName = 'mainFavorites';
  static String routePath = '/mainFavorites';

  @override
  State<MainFavoritesWidget> createState() => _MainFavoritesWidgetState();
}

class _MainFavoritesWidgetState extends State<MainFavoritesWidget> {
  late MainFavoritesModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MainFavoritesModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      // Favorites are now handled by FavoritesService and synchronized on login.
    });
  }

  @override
  void dispose() {
    _model.dispose();

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
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
          automaticallyImplyLeading: false,
          title: const Text(''),
          actions: const [],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Container(
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
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 0.0, 0.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.goNamed('mainHomePage'),
                            child: Text(
                              'Inicio',
                              style: FlutterFlowTheme.of(context).labelSmall.override(
                                    fontFamily: 'Inter',
                                    color: FlutterFlowTheme.of(context).secondaryText,
                                  ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              '>',
                              style: FlutterFlowTheme.of(context).labelSmall,
                            ),
                          ),
                          Text(
                            'Favoritos',
                            style: FlutterFlowTheme.of(context).labelSmall.override(
                                  fontFamily: 'Inter',
                                  color: FlutterFlowTheme.of(context).primaryText,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Mis favoritos',
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
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: const AlignmentDirectional(0.0, -1.0),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxWidth: 1170.0,
                    ),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                    ),
                    child: Container(
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                                16.0, 4.0, 0.0, 0.0),
                            child: Text(
                              'A continuación se muestran los artículos que ha marcado como favoritos.',
                              style: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                  ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 32.0),
                            child: Builder(
                              builder: (context) {
                                final idFavoritos =
                                    FFAppState().itemsFavoritos.toList();
                                if (idFavoritos.isEmpty) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: EmptyProductsWidget(),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  padding: EdgeInsets.zero,
                                  scrollDirection: Axis.vertical,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: idFavoritos.length,
                                  itemBuilder: (context, idFavoritosIndex) {
                                    final idFavoritosItem =
                                        idFavoritos[idFavoritosIndex];
                                    return FutureBuilder<List<ProductosRow>>(
                                      future: ProductosTable().querySingleRow(
                                        queryFn: (q) => q.eq(
                                          'id',
                                          idFavoritosItem,
                                        ),
                                      ),
                                      builder: (context, snapshot) {
                                        // Customize what your widget looks like when it's loading.
                                        if (!snapshot.hasData) {
                                          return Center(
                                            child: SizedBox(
                                              width: 50.0,
                                              height: 50.0,
                                              child: CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        List<ProductosRow>
                                            productListViewProductosRowList =
                                            snapshot.data!;

                                        final productListViewProductosRow =
                                            productListViewProductosRowList
                                                    .isNotEmpty
                                                ? productListViewProductosRowList
                                                    .first
                                                : null;

                                        if (productListViewProductosRow == null) {
                                          return Container();
                                        }

                                        return ProductListViewWidget(
                                          key: Key(
                                              'Key5po_${idFavoritosIndex}_of_${idFavoritos.length}'),
                                          favorited: true,
                                          productRef:
                                              productListViewProductosRow,
                                           action: () async {
                                             await FavoritesService.instance.toggleFavorite(
                                                 idFavoritosItem);
                                             safeSetState(() {});
                                           },

                                        );
                                      },
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
