import 'package:baul_pandora/components/related_products_component.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/components/gradient_button/gradient_button_widget.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/services/cart_service.dart';
import 'package:baul_pandora/services/favorites_service.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_animations.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_count_controller.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:baul_pandora/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'product_details_model.dart';
export 'product_details_model.dart';
import 'package:baul_pandora/flutter_flow/custom_functions.dart' as functions;


class ProductDetailsWidget extends StatefulWidget {
  const ProductDetailsWidget({
    super.key,
    required this.productRef,
  });

  final ProductosRow? productRef;

  static String routeName = 'productDetails';
  static String routePath = '/productDetails';

  @override
  State<ProductDetailsWidget> createState() => _ProductDetailsWidgetState();
}

class _ProductDetailsWidgetState extends State<ProductDetailsWidget>
    with TickerProviderStateMixin {
  late ProductDetailsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProductDetailsModel());

    _loadVariations();

    // Cargar productos relacionados
    _loadRelatedProducts();

    animationsMap.addAll({
      'rowOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
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
            begin: const Offset(0.0, -70.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
      'columnOnPageLoadAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
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
      'columnOnPageLoadAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
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
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 250.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 250.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 250.0.ms,
            duration: 600.0.ms,
            begin: const Offset(0.0, 50.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
    });
  }

  Future<void> _loadRelatedProducts() async {
    final categorias = widget.productRef?.categoriaIdWoo;
    if (categorias == null || categorias.isEmpty) return;

    final productosTable = ProductosTable();
    final allProducts = await productosTable.queryRows(queryFn: (query) {
      return query
          .filter('categoria_id_woo', 'cs', categorias)
          .neq('id', widget.productRef!.id)
          .eq('es_variacion', false);
    }, limit: 10);

    if (mounted) {
      safeSetState(() {
        _model.relatedProducts = allProducts;
      });
    }
  }

  Future<void> _loadVariations() async {
    if (widget.productRef == null) {
      return;
    }
    
    // Configurar estado inicial
    _model.currentActiveProduct = widget.productRef;
    
    if (widget.productRef!.imagePath != null) {
      _model.combinedImages.addAll(widget.productRef!.imagePath!);
    }
    
    final variaciones = await ProductosTable().queryRows(queryFn: (q) {
      if (widget.productRef!.idWoo != null) {
        return q.eq('parent_id_woo', widget.productRef!.idWoo!);
      } else {
        return q.eq('parent_id', widget.productRef!.id);
      }
    });
    
    if (variaciones.isEmpty) return;
    
    final Map<String, Set<String>> extractedAttributes = {};
    
    for (var v in variaciones) {
      // Unir imágenes
      if (v.imagePath != null && v.imagePath!.isNotEmpty) {
        for (var img in v.imagePath!) {
          if (!_model.combinedImages.contains(img)) {
            _model.combinedImages.add(img);
          }
        }
      }
      
      // Extraer atributos
      if (v.atributos != null) {
        if (v.atributos is Map) {
          final attrMap = v.atributos as Map<String, dynamic>;
          attrMap.forEach((key, value) {
            if (!extractedAttributes.containsKey(key)) {
              extractedAttributes[key] = {};
            }
            extractedAttributes[key]!.add(value.toString());
          });
        } else if (v.atributos is List) {
          final attrList = v.atributos as List<dynamic>;
          for (var attr in attrList) {
            if (attr is Map) {
              final name = attr['name']?.toString() ?? attr['key']?.toString();
              final option = attr['option']?.toString() ?? attr['value']?.toString();
              if (name != null && option != null) {
                if (!extractedAttributes.containsKey(name)) {
                  extractedAttributes[name] = {};
                }
                extractedAttributes[name]!.add(option);
              }
            }
          }
        }
      }
    }
    
    if (mounted) {
      safeSetState(() {
        _model.variaciones = variaciones;
        _model.availableAttributes = extractedAttributes;
        
        // Pre-seleccionar la primera opción de cada atributo
        extractedAttributes.forEach((key, values) {
          if (values.isNotEmpty) {
            _model.selectedAttributes[key] = values.first;
          }
        });
        
        _updateActiveProductBasedOnSelection();
      });
    }
  }

  void _updateActiveProductBasedOnSelection() {
    if (_model.variaciones.isEmpty) return;
    
    // Buscar la variación que coincida exactamente con los atributos seleccionados
    for (var v in _model.variaciones) {
      if (v.atributos != null) {
        bool match = true;
        if (v.atributos is Map) {
          final attrMap = v.atributos as Map<String, dynamic>;
          _model.selectedAttributes.forEach((key, value) {
            if (attrMap[key]?.toString() != value) {
              match = false;
            }
          });
        } else if (v.atributos is List) {
          final attrList = v.atributos as List<dynamic>;
          _model.selectedAttributes.forEach((key, value) {
            bool hasAttribute = false;
            for (var attr in attrList) {
              if (attr is Map) {
                final name = attr['name']?.toString() ?? attr['key']?.toString();
                final option = attr['option']?.toString() ?? attr['value']?.toString();
                if (name == key && option == value) {
                  hasAttribute = true;
                  break;
                }
              }
            }
            if (!hasAttribute) match = false;
          });
        } else {
          match = false;
        }
        
        if (match) {
          _model.currentActiveProduct = v;
          
          // Saltar a la imagen de esta variación en la galería si existe
          if (v.imagePath != null && v.imagePath!.isNotEmpty) {
            final firstImg = v.imagePath!.first;
            int imgIndex = _model.combinedImages.indexOf(firstImg);
            if (imgIndex == -1) {
              _model.combinedImages.add(firstImg);
              imgIndex = _model.combinedImages.length - 1;
            }
            _model.index = imgIndex;
          }
          return;
        }
      }
    }
    
    // Si no encuentra match perfecto, vuelve al padre
    _model.currentActiveProduct = widget.productRef;
  }

  void _updateProductBasedOnImageIndex() {
    if (_model.combinedImages.isEmpty || _model.index < 0 || _model.index >= _model.combinedImages.length) return;
    
    final currentImg = _model.combinedImages[_model.index];
    
    // Buscar en variaciones si alguna contiene esta imagen de forma principal
    for (var v in _model.variaciones) {
      if (v.imagePath != null && v.imagePath!.isNotEmpty && v.imagePath!.first == currentImg) {
        _model.currentActiveProduct = v;
        
        // Actualizar chips de selección para coincidir con esta variación
        if (v.atributos != null && v.atributos is Map) {
          final attrMap = v.atributos as Map<String, dynamic>;
          attrMap.forEach((key, value) {
            _model.selectedAttributes[key] = value.toString();
          });
        }
        return;
      }
    }
    
    // Si la imagen pertenece al padre, devolvemos al padre
    if (widget.productRef?.imagePath != null && widget.productRef!.imagePath!.contains(currentImg)) {
      _model.currentActiveProduct = widget.productRef;
      // Optionally reset chips here, but leaving them as is might be fine
    }
  }

  Widget _buildVariationsSelectors() {
    if (_model.availableAttributes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _model.availableAttributes.entries.map((entry) {
          final attrName = entry.key;
          final attrValues = entry.value.toList();
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attrName,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: attrValues.map((value) {
                    final isSelected = _model.selectedAttributes[attrName] == value;
                    return ChoiceChip(
                      label: Text(value),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          safeSetState(() {
                            _model.selectedAttributes[attrName] = value;
                            _updateActiveProductBasedOnSelection();
                          });
                        }
                      },
                      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
                      selectedColor: FlutterFlowTheme.of(context).primary,
                      labelStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Inter',
                        color: isSelected 
                            ? Colors.white 
                            : FlutterFlowTheme.of(context).primaryText,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    final currentProduct = _model.currentActiveProduct ?? widget.productRef;
    final images = _model.combinedImages.isNotEmpty ? _model.combinedImages : (widget.productRef?.imagePath ?? []);

    // --- NULL GUARD ---
    if (widget.productRef == null) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'No se pudo cargar el producto',
                style: FlutterFlowTheme.of(context).titleLarge,
              ),
              const SizedBox(height: 24),
              FFButtonWidget(
                onPressed: () => context.pushNamed(MainHomePageWidget.routeName),
                text: 'Volver al Inicio',
                options: FFButtonOptions(
                  height: 40,
                  width: 160,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              wrapWithModel(
                model: _model.topNavModel,
                updateCallback: () => safeSetState(() {}),
                child: const TopNavWidget(),
              ),
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: const AlignmentDirectional(0.0, 0.0),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(4.0, 0.0, 4.0, 0.0),
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(
                              maxWidth: 1170.0,
                            ),
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context).primaryBackground,
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).primaryBackground,
                                width: 2.0,
                              ),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: Stack(
                                children: [
                                  SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsetsDirectional.fromSTEB(4.0, 12.0, 0.0, 12.0),
                                          child: Container(
                                            width: double.infinity,
                                            height: 44.0,
                                            decoration: BoxDecoration(
                                              color: FlutterFlowTheme.of(context).primaryBackground,
                                            ),
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  wrapWithModel(
                                                    model: _model.gradientButtonModel,
                                                    updateCallback: () => safeSetState(() {}),
                                                    child: GradientButtonWidget(
                                                      action: () async {
                                                        context.pushNamed(MainHomePageWidget.routeName);
                                                      },
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                                                    child: Icon(
                                                      Icons.chevron_right_rounded,
                                                      color: FlutterFlowTheme.of(context).secondaryText,
                                                      size: 16.0,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
                                                    child: Container(
                                                      height: 32.0,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme.of(context).accent1,
                                                        borderRadius: BorderRadius.circular(12.0),
                                                        border: Border.all(
                                                          color: FlutterFlowTheme.of(context).primary,
                                                          width: 2.0,
                                                        ),
                                                      ),
                                                      alignment: const AlignmentDirectional(0.0, 0.0),
                                                      child: Padding(
                                                        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                                        child: Text(
                                                          'Product Details',
                                                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                font: GoogleFonts.inter(
                                                                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                ),
                                                                letterSpacing: 0.0,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ).animateOnPageLoad(animationsMap['rowOnPageLoadAnimation']!),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsetsDirectional.fromSTEB(4.0, 0.0, 4.0, 16.0),
                                          child: Container(
                                            width: double.infinity,
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
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.max,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Padding(
                                                        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.max,
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                             InkWell(
                                                               onTap: () async {
                                                                  if (_model.index > 0) {
                                                                    _model.index = _model.index - 1;
                                                                    safeSetState(() {
                                                                      _updateProductBasedOnImageIndex();
                                                                    });
                                                                  }
                                                               },
                                                               child: Icon(
                                                                 Icons.arrow_back_ios,
                                                                 color: _model.index > 0
                                                                     ? FlutterFlowTheme.of(context).primaryText
                                                                     : FlutterFlowTheme.of(context).secondaryText,
                                                                 size: isMobileWidth(context) ? 30.0 : 60.0,
                                                               ),
                                                             ),
                                                             Expanded(
                                                               child: Hero(
                                                                 tag: functions.getProxyUrl(images.elementAtOrNull(_model.index)) ?? 'product-img',
                                                                 transitionOnUserGestures: true,
                                                                 child: ClipRRect(
                                                                   borderRadius: BorderRadius.circular(10.0),
                                                                   child: Image.network(
                                                                     functions.getProxyUrl(images.elementAtOrNull(_model.index)) ?? '',
                                                                     width: 1000.0,
                                                                     height: isMobileWidth(context) ? 200.0 : 800.0,
                                                                     fit: BoxFit.cover,
                                                                     errorBuilder: (context, error, stackTrace) => Container(
                                                                       width: 1000.0,
                                                                       height: isMobileWidth(context) ? 200.0 : 800.0,
                                                                       color: Colors.grey[300],
                                                                       child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                                                     ),
                                                                   ),
                                                                 ),
                                                               ),
                                                             ),
                                                             Padding(
                                                               padding: const EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 0.0, 0.0),
                                                               child: InkWell(
                                                                 onTap: () async {
                                                                   if (_model.index < (images.length - 1)) {
                                                                     _model.index = _model.index + 1;
                                                                     safeSetState(() {
                                                                       _updateProductBasedOnImageIndex();
                                                                     });
                                                                   }
                                                                 },
                                                                 child: Icon(
                                                                   Icons.arrow_forward_ios_outlined,
                                                                   color: (_model.index < images.length - 1)
                                                                       ? FlutterFlowTheme.of(context).primaryText
                                                                       : FlutterFlowTheme.of(context).secondaryText,
                                                                   size: isMobileWidth(context) ? 30.0 : 60.0,
                                                                 ),
                                                               ),
                                                             ),
                                                          ],
                                                        ),
                                                      ),
                                                      if (responsiveVisibility(context: context, phone: false, tablet: false))
                                                        Padding(
                                                          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
                                                          child: Column(
                                                            mainAxisSize: MainAxisSize.max,
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                valueOrDefault<String>(currentProduct?.nombre, 'Unknown'),
                                                                style: FlutterFlowTheme.of(context).headlineLarge.override(
                                                                      font: GoogleFonts.interTight(
                                                                        fontWeight: FlutterFlowTheme.of(context).headlineLarge.fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context).headlineLarge.fontStyle,
                                                                      ),
                                                                      letterSpacing: 0.0,
                                                                    ),
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 12.0),
                                                                child: Text(
                                                                  valueOrDefault<String>(currentProduct?.precio?.toString(), '0.00'),
                                                                  style: FlutterFlowTheme.of(context).titleLarge.override(
                                                                        font: GoogleFonts.interTight(
                                                                          fontWeight: FlutterFlowTheme.of(context).titleLarge.fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context).titleLarge.fontStyle,
                                                                        ),
                                                                        color: FlutterFlowTheme.of(context).primary,
                                                                        letterSpacing: 0.0,
                                                                      ),
                                                                ),
                                                              ),
                                                              _buildVariationsSelectors(),
                                                              Padding(
                                                                padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                                                                child: Builder(
                                                                  builder: (context) {
                                                                    final isFavorite = FFAppState().itemsFavoritos.contains(currentProduct?.id);
                                                                    return InkWell(
                                                                      onTap: () async {
                                                                        await FavoritesService.instance
                                                                            .toggleFavorite(currentProduct!.id);
                                                                        safeSetState(() {});
                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                          SnackBar(
                                                                            content: Text(
                                                                              isFavorite
                                                                                  ? '¡Has eliminado ${currentProduct?.nombre} de tus favoritos!'
                                                                                  : '¡Has agregado ${currentProduct?.nombre} a tus favoritos!',
                                                                              style: FlutterFlowTheme.of(context).titleSmall.override(
                                                                                    font: GoogleFonts.interTight(
                                                                                      fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                    ),
                                                                                    color: FlutterFlowTheme.of(context).info,
                                                                                    letterSpacing: 0.0,
                                                                                  ),
                                                                            ),
                                                                            duration: const Duration(milliseconds: 4000),
                                                                            backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                          ),
                                                                        );
                                                                      },
                                                                      child: Icon(
                                                                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
                                                                        color: isFavorite 
                                                                            ? FlutterFlowTheme.of(context).primary 
                                                                            : FlutterFlowTheme.of(context).secondaryText,
                                                                        size: 30.0,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 24.0, 0.0),
                                                                child: Text(
                                                                  valueOrDefault<String>(currentProduct?.descripcion, 'Sin descripción disponible'),
                                                                  style: FlutterFlowTheme.of(context).labelLarge.override(
                                                                        font: GoogleFonts.inter(
                                                                          fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                        ),
                                                                        letterSpacing: 0.0,
                                                                      ),
                                                                ),
                                                              ),

                                                            ],
                                                          ).animateOnPageLoad(animationsMap['columnOnPageLoadAnimation1']!),
                                                        ),
                                                      if (responsiveVisibility(context: context, tabletLandscape: false, desktop: false))
                                                        Padding(
                                                          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                                                          child: Column(
                                                            mainAxisSize: MainAxisSize.max,
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                valueOrDefault<String>(currentProduct?.nombre, 'Unknown'),
                                                                style: FlutterFlowTheme.of(context).headlineLarge.override(
                                                                      font: GoogleFonts.interTight(
                                                                        fontWeight: FlutterFlowTheme.of(context).headlineLarge.fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context).headlineLarge.fontStyle,
                                                                      ),
                                                                      letterSpacing: 0.0,
                                                                    ),
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 12.0),
                                                                child: Text(
                                                                  valueOrDefault<String>(currentProduct?.precio?.toString(), '0.00'),
                                                                  style: FlutterFlowTheme.of(context).titleLarge.override(
                                                                        font: GoogleFonts.interTight(
                                                                          fontWeight: FlutterFlowTheme.of(context).titleLarge.fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context).titleLarge.fontStyle,
                                                                        ),
                                                                        color: FlutterFlowTheme.of(context).primary,
                                                                        letterSpacing: 0.0,
                                                                      ),
                                                                ),
                                                              ),
                                                              _buildVariationsSelectors(),
                                                              Padding(
                                                                padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                                                                child: Builder(
                                                                  builder: (context) {
                                                                    final isFavorite = FFAppState().itemsFavoritos.contains(currentProduct?.id);
                                                                    return InkWell(
                                                                      onTap: () async {
                                                                        await FavoritesService.instance
                                                                            .toggleFavorite(currentProduct!.id);
                                                                        safeSetState(() {});
                                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                                          SnackBar(
                                                                            content: Text(
                                                                              isFavorite
                                                                                  ? '¡Has eliminado ${currentProduct?.nombre} de tus favoritos!'
                                                                                  : '¡Has agregado ${currentProduct?.nombre} a tus favoritos!',
                                                                              style: FlutterFlowTheme.of(context).titleSmall.override(
                                                                                    font: GoogleFonts.interTight(
                                                                                      fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
                                                                                      fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                                    ),
                                                                                    color: FlutterFlowTheme.of(context).info,
                                                                                    letterSpacing: 0.0,
                                                                                  ),
                                                                            ),
                                                                            duration: const Duration(milliseconds: 4000),
                                                                            backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                          ),
                                                                        );
                                                                      },
                                                                      child: Icon(
                                                                        isFavorite ? Icons.favorite_rounded : Icons.favorite_border,
                                                                        color: isFavorite 
                                                                            ? FlutterFlowTheme.of(context).primary 
                                                                            : FlutterFlowTheme.of(context).secondaryText,
                                                                        size: 30.0,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding: const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 24.0, 0.0),
                                                                child: Text(
                                                                  valueOrDefault<String>(currentProduct?.descripcion, 'Sin descripción disponible'),
                                                                  style: FlutterFlowTheme.of(context).labelLarge.override(
                                                                        font: GoogleFonts.inter(
                                                                          fontWeight: FlutterFlowTheme.of(context).labelLarge.fontWeight,
                                                                          fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                                                                        ),
                                                                        letterSpacing: 0.0,
                                                                      ),
                                                                ),
                                                              ),

                                                            ],
                                                          ).animateOnPageLoad(animationsMap['columnOnPageLoadAnimation2']!),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (_model.relatedProducts != null && _model.relatedProducts!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 10.0, bottom: 100.0),
                                            child: RelatedProductsComponent(
                                              relatedProducts: _model.relatedProducts!,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Align(
                                    alignment: const AlignmentDirectional(0.0, 1.0),
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 32.0),
                                      child: Container(
                                        width: double.infinity,
                                        height: 80.0,
                                        decoration: BoxDecoration(
                                          boxShadow: const [
                                            BoxShadow(
                                              blurRadius: 4.0,
                                              color: Color(0x33000000),
                                              offset: Offset(0.0, 2.0),
                                            )
                                          ],
                                          borderRadius: BorderRadius.circular(12.0),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12.0),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 5.0,
                                              sigmaY: 2.0,
                                            ),
                                            child: Container(
                                              width: double.infinity,
                                              height: 80.0,
                                              decoration: BoxDecoration(
                                                color: FlutterFlowTheme.of(context).accent4,
                                                borderRadius: BorderRadius.circular(12.0),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.max,
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Container(
                                                      width: 160.0,
                                                      height: 50.0,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme.of(context).accent4,
                                                        borderRadius: BorderRadius.circular(25.0),
                                                        shape: BoxShape.rectangle,
                                                        border: Border.all(
                                                          color: FlutterFlowTheme.of(context).alternate,
                                                          width: 2.0,
                                                        ),
                                                      ),
                                                      child: FlutterFlowCountController(
                                                        decrementIconBuilder: (enabled) => FaIcon(
                                                          FontAwesomeIcons.minus,
                                                          color: enabled 
                                                              ? FlutterFlowTheme.of(context).primaryText 
                                                              : FlutterFlowTheme.of(context).secondaryText,
                                                          size: 20.0,
                                                        ),
                                                        incrementIconBuilder: (enabled) => FaIcon(
                                                          FontAwesomeIcons.plus,
                                                          color: enabled 
                                                              ? FlutterFlowTheme.of(context).primaryText 
                                                              : FlutterFlowTheme.of(context).secondaryText,
                                                          size: 20.0,
                                                        ),
                                                        countBuilder: (count) => Text(
                                                          count.toString(),
                                                          style: FlutterFlowTheme.of(context).headlineSmall.override(
                                                                font: GoogleFonts.interTight(
                                                                  fontWeight: FlutterFlowTheme.of(context).headlineSmall.fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(context).headlineSmall.fontStyle,
                                                                ),
                                                                letterSpacing: 0.0,
                                                              ),
                                                        ),
                                                        count: _model.countControllerValue ??= ((currentProduct?.stock ?? 0) > 0 ? 1 : 0),
                                                        updateCount: (count) => safeSetState(() => _model.countControllerValue = count),
                                                        stepSize: 1,
                                                        maximum: currentProduct?.stock,
                                                      ),
                                                    ),
                                                    Flexible(
                                                      child: Padding(
                                                        padding: const EdgeInsetsDirectional.fromSTEB(15.0, 0.0, 0.0, 0.0),
                                                        child: FFButtonWidget(
                                                          onPressed: ((currentProduct?.stock ?? 0) > 0)
                                                              ? () async {
                                                                  await CartService.instance.addItem(
                                                                    currentProduct?.id ?? '',
                                                                    (currentProduct?.precio ?? 0.0).toDouble(),
                                                                    quantity: _model.countControllerValue ?? 1,
                                                                  );
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(
                                                                        '¡Has agregado ${currentProduct?.nombre} a tu carrito!',
                                                                        style: FlutterFlowTheme.of(context).titleSmall.override(
                                                                              font: GoogleFonts.interTight(
                                                                                fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
                                                                                fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                              ),
                                                                              color: FlutterFlowTheme.of(context).info,
                                                                              letterSpacing: 0.0,
                                                                            ),
                                                                      ),
                                                                      duration: const Duration(milliseconds: 4000),
                                                                      backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                    ),
                                                                  );
                                                                }
                                                              : () async {
                                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(
                                                                        'Actualmente no tenemos ese producto, pero agrégalo a favoritos y te avisamos cuando volvamos a tener.',
                                                                        style: FlutterFlowTheme.of(context).titleSmall.override(
                                                                              font: GoogleFonts.interTight(
                                                                                fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
                                                                                fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                              ),
                                                                              color: FlutterFlowTheme.of(context).info,
                                                                              letterSpacing: 0.0,
                                                                            ),
                                                                      ),
                                                                      duration: const Duration(milliseconds: 4000),
                                                                      backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                    ),
                                                                  );
                                                                },
                                                          text: ((currentProduct?.stock ?? 0) > 0) ? 'Add to Cart' : 'Out of Stock',
                                                          options: FFButtonOptions(
                                                            width: double.infinity,
                                                            height: 50.0,
                                                            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                                            iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                                            color: ((currentProduct?.stock ?? 0) > 0) 
                                                                ? FlutterFlowTheme.of(context).primary 
                                                                : FlutterFlowTheme.of(context).secondaryText,
                                                            textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                                                  font: GoogleFonts.interTight(
                                                                    fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                                                  ),
                                                                  letterSpacing: 0.0,
                                                                ),
                                                            elevation: 2.0,
                                                            borderSide: const BorderSide(
                                                              color: Colors.transparent,
                                                              width: 1.0,
                                                            ),
                                                            borderRadius: BorderRadius.circular(50.0),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation']!),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
