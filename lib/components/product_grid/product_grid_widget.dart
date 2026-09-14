import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_animations.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_icon_button.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/services/favorites_service.dart';
import 'package:baul_pandora/services/cart_service.dart';
import 'package:baul_pandora/flutter_flow/custom_functions.dart' as functions;
import 'package:baul_pandora/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'product_grid_model.dart';
export 'product_grid_model.dart';

class ProductGridWidget extends StatefulWidget {
  const ProductGridWidget({
    super.key,
    required this.productoRow,
  });

  final ProductosRow? productoRow;

  @override
  State<ProductGridWidget> createState() => _ProductGridWidgetState();
}

class _ProductGridWidgetState extends State<ProductGridWidget>
    with TickerProviderStateMixin {
  late ProductGridModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProductGridModel());
    _loadVariations();

    animationsMap.addAll({
      'containerOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: const Offset(0.0, 50.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 200.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 200.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 200.0.ms,
            duration: 600.0.ms,
            begin: const Offset(0.5, 0.5),
            end: const Offset(1.0, 1.0),
          ),
          RotateEffect(
            curve: Curves.easeInOut,
            delay: 200.0.ms,
            duration: 600.0.ms,
            begin: 0.5,
            end: 1.0,
          ),
        ],
      ),
      'iconButtonOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          ScaleEffect(
            curve: Curves.bounceOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: const Offset(0.3, 0.3),
            end: const Offset(1.5, 1.5),
          ),
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 300.0.ms,
            duration: 150.0.ms,
            begin: const Offset(1.5, 1.5),
            end: const Offset(1.0, 1.0),
          ),
        ],
      ),
      'iconButtonOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          ScaleEffect(
            curve: Curves.bounceOut,
            delay: 0.0.ms,
            duration: 300.0.ms,
            begin: const Offset(0.3, 0.3),
            end: const Offset(1.5, 1.5),
          ),
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 300.0.ms,
            duration: 150.0.ms,
            begin: const Offset(1.5, 1.5),
            end: const Offset(1.0, 1.0),
          ),
        ],
      ),
    });
  }

  Future<void> _loadVariations() async {
    if (widget.productoRow == null || widget.productoRow!.idWoo == null) return;
    
    if (widget.productoRow!.imagePath != null) {
      _model.combinedImages.addAll(widget.productoRow!.imagePath!);
    }
    
    final variaciones = await ProductosTable().queryRows(queryFn: (q) {
      return q.eq('parent_id_woo', widget.productoRow!.idWoo!);
    });
    
    if (variaciones.isEmpty) return;
    
    for (var v in variaciones) {
      if (v.imagePath != null && v.imagePath!.isNotEmpty) {
        for (var img in v.imagePath!) {
          if (!_model.combinedImages.contains(img)) {
            _model.combinedImages.add(img);
          }
        }
      }
    }
    
    if (mounted) {
      safeSetState(() {});
    }
  }

  @override
  void didUpdateWidget(ProductGridWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.productoRow?.idWoo != oldWidget.productoRow?.idWoo) {
      _model.indexImages = 0;
      _model.combinedImages.clear();
      _loadVariations();
    }
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    final images = _model.combinedImages.isNotEmpty ? _model.combinedImages : (widget.productoRow?.imagePath ?? []);

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () async {
          context.pushNamed(
            ProductDetailsWidget.routeName,
            queryParameters: {
              'productRef': serializeParam(
                widget.productoRow,
                ParamType.SupabaseRow,
              ),
            }.withoutNulls,
          );
        },
        child: Container(
          width: 400.0,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            boxShadow: const [
              BoxShadow(
                blurRadius: 2.0,
                color: Color(0x520E151B),
                offset: Offset(0.0, 1.0),
              )
            ],
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Align(
                        alignment: const AlignmentDirectional(0.0, 0.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            InkWell(
                              splashColor: Colors.transparent,
                              focusColor: Colors.transparent,
                              hoverColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () async {
                                if (_model.indexImages! > 0) {
                                  _model.indexImages = _model.indexImages! + -1;
                                  safeSetState(() {});
                                }
                              },
                              child: Icon(
                                Icons.arrow_back_ios,
                                color: _model.indexImages! > 0
                                    ? FlutterFlowTheme.of(context).primaryText
                                    : FlutterFlowTheme.of(context)
                                        .secondaryText,
                                size: 34.0,
                               ),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Expanded(
                                    child: Hero(
                                      tag: 'grid-${widget.productoRow?.id}-${functions.getProxyUrl(images.elementAtOrNull(_model.indexImages!))}',
                                      transitionOnUserGestures: true,
                                      child: ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                        child: CachedNetworkImage(
                                          fadeInDuration:
                                              const Duration(milliseconds: 500),
                                          fadeOutDuration:
                                              const Duration(milliseconds: 500),
                                          imageUrl: functions.getProxyUrl(images.elementAtOrNull(_model.indexImages!)),
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  10.0, 0.0, 0.0, 0.0),
                              child: InkWell(
                                splashColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  if (_model.indexImages! <
                                      (images.length - 1)) {
                                    _model.indexImages =
                                        _model.indexImages! + 1;
                                    safeSetState(() {});
                                  }
                                },
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  color: _model.indexImages! <
                                          (images.length - 1)
                                      ? FlutterFlowTheme.of(context).primaryText
                                      : FlutterFlowTheme.of(context)
                                          .secondaryText,
                                  size: 34.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: const AlignmentDirectional(1.0, -1.0),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0, 12.0, 12.0, 0.0),
                          child: _buildCartButton(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(5.0, 12.0, 5.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                    Text(
                                      valueOrDefault<String>(
                                          widget.productoRow?.nombre, 'Unknown'),
                                      style: FlutterFlowTheme.of(context).bodyLarge,
                                    ),
                                    if (widget.productoRow?.stock == 0)
                                      Text(
                                        'AGOTADO',
                                        style: FlutterFlowTheme.of(context).bodySmall.override(
                                              fontFamily: 'Inter',
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    const SizedBox(height: 4),
                            Text(
                              '${widget.productoRow?.precio?.toString()} \$',
                              style: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .override(
                                    fontFamily: 'InterTight',
                                    fontSize: 16.0,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Builder(
                            builder: (context) {
                              if (!FFAppState()
                                  .itemsFavoritos
                                  .contains(widget.productoRow?.id)) {
                                return FlutterFlowIconButton(
                                  borderRadius: 12.0,
                                  borderWidth: 1.0,
                                  buttonSize: 32.0,
                                  icon: Icon(
                                    Icons.favorite_border,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    size: 20.0,
                                  ),
                                  onPressed: () async {
                                    await FavoritesService.instance
                                        .toggleFavorite(widget.productoRow!.id);
                                    safeSetState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'You have added ${widget.productoRow?.nombre} to your favorites!',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyLarge,
                                        ),
                                        duration: const Duration(milliseconds: 1000),
                                        backgroundColor:
                                            FlutterFlowTheme.of(context)
                                                .alternate,
                                      ),
                                    );
                                  },
                                ).animateOnPageLoad(animationsMap[
                                    'iconButtonOnPageLoadAnimation1']!);
                              } else {
                                return FlutterFlowIconButton(
                                  borderColor: Colors.transparent,
                                  borderRadius: 12.0,
                                  borderWidth: 1.0,
                                  buttonSize: 32.0,
                                  icon: Icon(
                                    Icons.favorite_rounded,
                                    color: FlutterFlowTheme.of(context).primary,
                                    size: 20.0,
                                  ),
                                  onPressed: () async {
                                    await FavoritesService.instance
                                        .toggleFavorite(widget.productoRow!.id);
                                    safeSetState(() {});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'You have removed ${widget.productoRow?.nombre} from your favorites!',
                                          style: FlutterFlowTheme.of(context)
                                              .titleSmall,
                                        ),
                                        duration: const Duration(milliseconds: 1000),
                                        backgroundColor:
                                            FlutterFlowTheme.of(context)
                                                .primary,
                                      ),
                                    );
                                  },
                                ).animateOnPageLoad(animationsMap[
                                    'iconButtonOnPageLoadAnimation2']!);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation1']!);
  }

  Widget _buildCartButton(BuildContext context) {
    if (!FFAppState()
        .itemsCarrito
        .any((item) => item.idProducto == widget.productoRow?.id)) {
      final bool isOutOfStock = widget.productoRow?.stock == 0;
      return FlutterFlowIconButton(
        borderColor: Colors.transparent,
        borderRadius: 12.0,
        borderWidth: 1.0,
        buttonSize: 44.0,
        fillColor: isOutOfStock
            ? Colors.grey
            : FlutterFlowTheme.of(context).accent1,
        icon: Icon(
          Icons.shopping_cart_outlined,
          color: isOutOfStock
              ? Colors.white70
              : FlutterFlowTheme.of(context).primaryText,
          size: 24.0,
        ),
        onPressed: () async {
          if (isOutOfStock) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Agrega este producto a tus favoritos y te avisaremos cuando volvamos a tener en el stock',
                  style: FlutterFlowTheme.of(context).titleSmall,
                ),
                duration: const Duration(milliseconds: 1000),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          await CartService.instance.addItem(
              widget.productoRow!.id, widget.productoRow!.precio!);
          safeSetState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'You have added ${widget.productoRow?.nombre} to your cart!',
                style: FlutterFlowTheme.of(context).titleSmall,
              ),
              duration: const Duration(milliseconds: 1000),
              backgroundColor: FlutterFlowTheme.of(context).primary,
            ),
          );
          safeSetState(() {});
        },
      );
    } else {
      return Container(
        width: 44.0,
        height: 44.0,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primary,
          borderRadius: BorderRadius.circular(12.0),
        ),
        alignment: const AlignmentDirectional(0.0, 0.0),
        child: Icon(
          Icons.check_rounded,
          color: FlutterFlowTheme.of(context).info,
          size: 24.0,
        ),
      ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation2']!);
    }
  }
}
