import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/components/top_nav/top_nav_widget.dart';

import 'product_create_model.dart';
export 'product_create_model.dart';

// Components
import 'components/product_images_section.dart';
import 'components/product_basic_info_section.dart';
import 'components/product_pricing_inventory_section.dart';
import 'components/product_categories_section.dart';
import 'components/product_variations_section.dart';

class ProductCreateWidget extends StatefulWidget {
  const ProductCreateWidget({super.key, this.productRow});

  final ProductosRow? productRow;

  static String routeName = 'productCreate';
  static String routePath = '/productCreate';

  @override
  State<ProductCreateWidget> createState() => _ProductCreateWidgetState();
}

class _ProductCreateWidgetState extends State<ProductCreateWidget> {
  late ProductCreateModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProductCreateModel());

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (widget.productRow != null) {
        await _loadExistingProduct();
      } else {
        _model.uuidProductoTemp = functions.generateRealUUID();
      }
      safeSetState(() {});
      _model.generales = await CategoriasTable().queryRows(
        queryFn: (q) => q.isFilter('parent_id', null),
      );
      _model.categoriasGenerales = _model.generales!.map((e) => e.id).toList().cast<String>();
      safeSetState(() {});
    });

    _model.textController1 ??= TextEditingController();
    _model.textFieldFocusNode1 ??= FocusNode();
    _model.textController2 ??= TextEditingController();
    _model.textFieldFocusNode2 ??= FocusNode();
    _model.textController3 ??= TextEditingController();
    _model.textFieldFocusNode3 ??= FocusNode();
    _model.textController4 ??= TextEditingController();
    _model.textFieldFocusNode4 ??= FocusNode();
    _model.textController5 ??= TextEditingController();
    _model.textFieldFocusNode5 ??= FocusNode();
    _model.textController6 ??= TextEditingController();
    _model.textFieldFocusNode6 ??= FocusNode();
  }

  Future<void> _loadExistingProduct() async {
    final product = widget.productRow!;
    _model.uuidProductoTemp = product.id;
    _model.textController1?.text = product.nombre;
    _model.textController2?.text = product.descripcion ?? '';
    _model.textController3?.text = product.precio?.toString() ?? '';
    _model.textController6?.text = product.stock.toString();
    _model.textController5?.text = product.codigoBarras ?? '';

    _model.categoriasSeleccionadas = List<String>.from(product.categorias);
    _model.imagesPaths = List<String>.from(product.imagePath ?? []);

    try {
      final variations = await ProductosTable().queryRows(
        queryFn: (q) => q.eq('parent_id', product.id).eq('es_variacion', true),
      );

      if (variations.isNotEmpty) {
        _model.isVariable = true;
        _model.variationsList = variations.map((v) {
          final attrs = v.atributos is Map ? Map<String, dynamic>.from(v.atributos as Map) : <String, dynamic>{};
          return {
            'attributes': attrs,
            'price': v.precio?.toString(),
            'stock': v.stock.toString(),
            'images': List<String>.from(v.imagePath ?? []),
            'id': v.id,
          };
        }).toList();

        _model.variationPriceControllers = List.generate(variations.length, (i) => TextEditingController(text: variations[i].precio?.toString() ?? ''));
        _model.variationStockControllers = List.generate(variations.length, (i) => TextEditingController(text: variations[i].stock.toString()));
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error cargando variaciones: $e');
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  bool _isSaving = false;

  Future<void> _saveProduct() async {
    if (_isSaving) return;

    final nombre = _model.textController1?.text ?? '';
    final uuid = _model.uuidProductoTemp;

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre es obligatorio')),
      );
      return;
    }
    if (uuid == null || uuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: ID de producto no generado')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final isEdit = widget.productRow != null;

      if (_model.isVariable) {
        // 1. Guardar producto padre
        final double parentPrice = double.tryParse(_model.textController3?.text ?? '') ?? 0.0;
        final parentData = {
          'nombre': nombre,
          'descripcion': _model.textController2?.text ?? '',
          'ubicacion': '',
          'precio': parentPrice,
          'categorias': _model.categoriasSeleccionadas,
          'image_path': _model.imagesPaths,
          'stock': 0, // Stock padre es 0
          'es_variacion': false,
          'atributos': null,
          'codigo_barras': _model.textController5?.text ?? '',
        };

        if (isEdit) {
          await ProductosTable().update(
            data: parentData,
            matchingRows: (q) => q.eq('id', uuid),
          );
          // Opcional: Eliminar variaciones existentes que fueron removidas
          // Podríamos hacer un query de las existentes, compararlas, y borrar.
          // Por simplicidad, mantendremos las que sigan estando y agregaremos las nuevas.
        } else {
          parentData['id'] = uuid;
          await ProductosTable().insert(parentData);
        }

        // 2. Guardar variaciones
        for (int i = 0; i < _model.variationsList.length; i++) {
          final variation = _model.variationsList[i];
          final Map<String, String> attrs = Map<String, String>.from(variation['attributes']);
          
          // Si la variación ya tenía un ID, es una actualización
          final bool isVariationEdit = variation['id'] != null;
          final variationUuid = isVariationEdit ? variation['id'] as String : (functions.generateRealUUID() ?? '');

          final double varPrice = double.tryParse(_model.variationPriceControllers.elementAtOrNull(i)?.text ?? '') ?? parentPrice;
          final int varStock = int.tryParse(_model.variationStockControllers.elementAtOrNull(i)?.text ?? '') ?? 1;

          List<String> varImages = List<String>.from(variation['images'] ?? []);
          if (varImages.isEmpty) {
            varImages = _model.imagesPaths; // Hereda la del padre
          }

          final varData = {
            'parent_id_woo': null,
            'parent_id': uuid,
            'nombre': '$nombre - ${attrs.values.join(', ')}',
            'descripcion': _model.textController2?.text ?? '',
            'ubicacion': '',
            'precio': varPrice,
            'stock': varStock,
            'categorias': _model.categoriasSeleccionadas,
            'image_path': varImages,
            'es_variacion': true,
            'atributos': attrs,
          };

          if (isVariationEdit) {
            await ProductosTable().update(
              data: varData,
              matchingRows: (q) => q.eq('id', variationUuid),
            );
          } else {
            varData['id'] = variationUuid;
            await ProductosTable().insert(varData);
          }
        }
      } else {
        // Guardar producto simple
        final int stock = int.tryParse(_model.textController6?.text ?? '') ?? 0;
        final simpleData = {
          'nombre': nombre,
          'descripcion': _model.textController2?.text ?? '',
          'ubicacion': '',
          'precio': double.tryParse(_model.textController3?.text ?? '') ?? 0.0,
          'categorias': _model.categoriasSeleccionadas,
          'image_path': _model.imagesPaths,
          'stock': stock,
          'es_variacion': false,
          'atributos': null,
          'codigo_barras': _model.textController5?.text ?? '',
        };

        if (isEdit) {
          await ProductosTable().update(
            data: simpleData,
            matchingRows: (q) => q.eq('id', uuid),
          );
        } else {
          simpleData['id'] = uuid;
          await ProductosTable().insert(simpleData);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEdit ? 'Producto actualizado exitosamente' : 'Producto creado exitosamente')),
        );
        context.pushNamed('administracion');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear producto: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
        body: SafeArea(
          top: true,
          child: Column(
            children: [
              wrapWithModel(
                model: _model.topNavModel,
                updateCallback: () => safeSetState(() {}),
                child: const TopNavWidget(),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () => context.safePop(),
                                child: Icon(Icons.arrow_back_ios, color: FlutterFlowTheme.of(context).primaryText),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                widget.productRow != null ? 'Editar Producto' : 'Crear Producto',
                                style: FlutterFlowTheme.of(context).headlineMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // Components Extracted!
                          ProductImagesSection(
                            model: _model,
                            onStateChanged: () => safeSetState(() {}),
                          ),
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 32),

                          ProductBasicInfoSection(model: _model),
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 32),

                          ProductPricingInventorySection(
                            model: _model,
                            onStateChanged: () => safeSetState(() {}),
                          ),
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 32),

                          ProductCategoriesSection(
                            model: _model,
                            onStateChanged: () => safeSetState(() {}),
                          ),
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 32),

                          ProductVariationsSection(
                            model: _model,
                            onStateChanged: () => safeSetState(() {}),
                          ),

                          const SizedBox(height: 48),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: FFButtonWidget(
                              onPressed: _isSaving ? null : _saveProduct,
                              text: _isSaving
                                  ? 'Guardando...'
                                  : (widget.productRow != null ? 'Actualizar Producto' : 'Guardar Producto'),
                              options: FFButtonOptions(
                                color: FlutterFlowTheme.of(context).primary,
                                textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                                  fontFamily: 'Inter',
                                  color: Colors.white,
                                ),
                                elevation: 2.0,
                                borderRadius: BorderRadius.circular(8.0),
                                disabledColor: FlutterFlowTheme.of(context).alternate,
                              ),
                            ),
                          ),
                          const SizedBox(height: 64),
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
    );
  }
}
