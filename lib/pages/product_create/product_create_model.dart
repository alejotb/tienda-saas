import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/components/gradient_button/gradient_button_widget.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'product_create_widget.dart' show ProductCreateWidget;
import 'package:flutter/material.dart';

class ProductCreateModel extends FlutterFlowModel<ProductCreateWidget> {
  ///  Local state fields for this page.

  List<String> categoriasSeleccionadas = [];
  void addToCategoriasSeleccionadas(String item) =>
      categoriasSeleccionadas.add(item);
  void removeFromCategoriasSeleccionadas(String item) =>
      categoriasSeleccionadas.remove(item);
  void removeAtIndexFromCategoriasSeleccionadas(int index) =>
      categoriasSeleccionadas.removeAt(index);
  void insertAtIndexInCategoriasSeleccionadas(int index, String item) =>
      categoriasSeleccionadas.insert(index, item);
  void updateCategoriasSeleccionadasAtIndex(
          int index, Function(String) updateFn) =>
      categoriasSeleccionadas[index] = updateFn(categoriasSeleccionadas[index]);

  List<String> imagesPaths = [];
  void addToImagesPaths(String item) => imagesPaths.add(item);
  void removeFromImagesPaths(String item) => imagesPaths.remove(item);
  void removeAtIndexFromImagesPaths(int index) => imagesPaths.removeAt(index);
  void insertAtIndexInImagesPaths(int index, String item) =>
      imagesPaths.insert(index, item);
  void updateImagesPathsAtIndex(int index, Function(String) updateFn) =>
      imagesPaths[index] = updateFn(imagesPaths[index]);

  int indexImage = 0;

  List<String> categoriasGenerales = [];
  void addToCategoriasGenerales(String item) => categoriasGenerales.add(item);
  void removeFromCategoriasGenerales(String item) =>
      categoriasGenerales.remove(item);
  void removeAtIndexFromCategoriasGenerales(int index) =>
      categoriasGenerales.removeAt(index);
  void insertAtIndexInCategoriasGenerales(int index, String item) =>
      categoriasGenerales.insert(index, item);
  void updateCategoriasGeneralesAtIndex(int index, Function(String) updateFn) =>
      categoriasGenerales[index] = updateFn(categoriasGenerales[index]);

  String? uuidProductoTemp;

  // Fields for Variable Products & Variations
  bool isVariable = false;
  bool switchValue1 = true; // Gestionar inventario
  bool switchValue2 = true; // Publicar en wooCommerce
  List<Map<String, dynamic>> attributesList = [];
  List<Map<String, dynamic>> variationsList = [];
  List<TextEditingController> variationPriceControllers = [];
  List<TextEditingController> variationStockControllers = [];

  // Controllers for adding a new attribute
  TextEditingController? newAttributeNameController;
  FocusNode? newAttributeNameFocusNode;
  TextEditingController? newAttributeOptionsController;
  FocusNode? newAttributeOptionsFocusNode;

  void generateVariations() {
    // 1. Parse attributes from attributesList
    List<String> attrNames = [];
    List<List<String>> attrOptionsList = [];

    for (var attr in attributesList) {
      String name = attr['name']?.toString().trim() ?? '';
      String rawOptions = attr['options']?.toString() ?? '';
      if (name.isNotEmpty && rawOptions.isNotEmpty) {
        List<String> options = rawOptions
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        if (options.isNotEmpty) {
          attrNames.add(name);
          attrOptionsList.add(options);
        }
      }
    }

    // Dispose old controllers first to prevent leaks
    for (var ctrl in variationPriceControllers) {
      ctrl.dispose();
    }
    for (var ctrl in variationStockControllers) {
      ctrl.dispose();
    }

    variationPriceControllers = [];
    variationStockControllers = [];

    if (attrNames.isEmpty) {
      variationsList = [];
      return;
    }

    // 2. Cartesian product
    List<Map<String, String>> cartesian = [{}];
    for (int i = 0; i < attrNames.length; i++) {
      String name = attrNames[i].replaceAll(RegExp(r'[\[\]]'), '').trim();
      List<String> options = attrOptionsList[i];
      List<Map<String, String>> newCartesian = [];

      for (var item in cartesian) {
        for (var option in options) {
          String cleanOption = option.replaceAll(RegExp(r'[\[\]]'), '').trim();
          newCartesian.add({...item, name: cleanOption});
        }
      }
      cartesian = newCartesian;
    }

    // 3. Build variationsList
    variationsList = cartesian.map((attrs) {
      final defaultPriceStr = textController3?.text ?? '0.0';
      final defaultStockStr = (countControllerValue ?? 1).toString();

      final priceCtrl = TextEditingController(text: defaultPriceStr);
      final stockCtrl = TextEditingController(text: defaultStockStr);

      variationPriceControllers.add(priceCtrl);
      variationStockControllers.add(stockCtrl);

      return {
        'attributes': attrs,
        'price': double.tryParse(defaultPriceStr) ?? 0.0,
        'stock': int.tryParse(defaultStockStr) ?? 1,
        'images': <String>[], // Lista de rutas de imágenes (hereda del padre si queda vacía)
      };
    }).toList();
  }

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Query Rows] action in productCreate widget.
  List<CategoriasRow>? generales;
  // Model for topNav component.
  late TopNavModel topNavModel;
  // Model for gradientButton component.
  late GradientButtonModel gradientButtonModel;
  bool isDataUploadingUploadData24h1 = false;
  bool isAnalyzingAI = false;
  FFUploadedFile uploadedLocalFileUploadData24h1 =
      FFUploadedFile(bytes: Uint8List.fromList([]));
  String uploadedFileUrlUploadData24h1 = '';

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  // State field(s) for CountController widget.
  int? countControllerValue;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;
  // Stores action output result for [Backend Call - Query Rows] action in categorias_generales widget.
  List<CategoriasRow>? categorias;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode4;
  TextEditingController? textController4;
  String? Function(BuildContext, String?)? textController4Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode5;
  TextEditingController? textController5;
  String? Function(BuildContext, String?)? textController5Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode6;
  TextEditingController? textController6;
  String? Function(BuildContext, String?)? textController6Validator;
  // Stores action output result for [Backend Call - Query Rows] action in categorias_generales widget.
  List<CategoriasRow>? categorias2;

  @override
  void initState(BuildContext context) {
    topNavModel = createModel(context, () => TopNavModel());
    gradientButtonModel = createModel(context, () => GradientButtonModel());
    newAttributeNameController ??= TextEditingController();
    newAttributeNameFocusNode ??= FocusNode();
    newAttributeOptionsController ??= TextEditingController();
    newAttributeOptionsFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    topNavModel.dispose();
    gradientButtonModel.dispose();
    textFieldFocusNode1?.dispose();
    textController1?.dispose();

    textFieldFocusNode2?.dispose();
    textController2?.dispose();

    textFieldFocusNode3?.dispose();
    textController3?.dispose();

    textFieldFocusNode4?.dispose();
    textController4?.dispose();

    textFieldFocusNode5?.dispose();
    textController5?.dispose();

    textFieldFocusNode6?.dispose();
    textController6?.dispose();

    for (var ctrl in variationPriceControllers) {
      ctrl.dispose();
    }
    for (var ctrl in variationStockControllers) {
      ctrl.dispose();
    }
    newAttributeNameController?.dispose();
    newAttributeNameFocusNode?.dispose();
    newAttributeOptionsController?.dispose();
    newAttributeOptionsFocusNode?.dispose();
  }
}
