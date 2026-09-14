import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/components/categorias_productos/categorias_productos_widget.dart';
import 'package:baul_pandora/components/gradient_button/gradient_button_widget.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/index.dart';
import 'product_edit_widget.dart' show ProductEditWidget;
import 'package:flutter/material.dart';

class ProductEditModel extends FlutterFlowModel<ProductEditWidget> {
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

  ///  State fields for stateful widgets in this page.

  // Model for topNav component.
  late TopNavModel topNavModel;
  // Model for gradientButton component.
  late GradientButtonModel gradientButtonModel;
  bool isDataUploading_editUploadData24h1 = false;
  FFUploadedFile uploadedLocalFile_editUploadData24h1 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_editUploadData24h1 = '';

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;
  // State field(s) for CountController widget.
  int? countControllerValue1;
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
  // State field(s) for CountController widget.
  int? countControllerValue2;
  // Model for categoriasProductos component.
  late CategoriasProductosModel categoriasProductosModel;

  @override
  void initState(BuildContext context) {
    topNavModel = createModel(context, () => TopNavModel());
    gradientButtonModel = createModel(context, () => GradientButtonModel());
    categoriasProductosModel =
        createModel(context, () => CategoriasProductosModel());
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

    categoriasProductosModel.dispose();
  }
}
