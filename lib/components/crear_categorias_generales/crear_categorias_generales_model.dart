import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'crear_categorias_generales_widget.dart'
    show CrearCategoriasGeneralesWidget;
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';

class CrearCategoriasGeneralesModel
    extends FlutterFlowModel<CrearCategoriasGeneralesWidget> {
  ///  Local state fields for this component.

  List<String> categorias = [];
  void addToCategorias(String item) => categorias.add(item);
  void removeFromCategorias(String item) => categorias.remove(item);
  void removeAtIndexFromCategorias(int index) => categorias.removeAt(index);
  void insertAtIndexInCategorias(int index, String item) =>
      categorias.insert(index, item);
  void updateCategoriasAtIndex(int index, Function(String) updateFn) =>
      categorias[index] = updateFn(categorias[index]);

  bool agregarCategoria = false;

  String estado = 'Crear';

  String? nombreCategoria;

  ///  State fields for stateful widgets in this component.

  // State field(s) for Expandable widget.
  late ExpandableController expandableExpandableController;

  bool isDataUploading_uploadDataCrearCategoria = false;
  FFUploadedFile uploadedLocalFile_uploadDataCrearCategoria =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataCrearCategoria = '';

  // State field(s) for nombreCategoria widget.
  FocusNode? nombreCategoriaFocusNode1;
  TextEditingController? nombreCategoriaTextController1;
  String? Function(BuildContext, String?)?
      nombreCategoriaTextController1Validator;
  // State field(s) for NombreOpcion widget.
  FocusNode? nombreOpcionFocusNode;
  TextEditingController? nombreOpcionTextController;
  String? Function(BuildContext, String?)? nombreOpcionTextControllerValidator;
  bool isDataUploading_uploadDataEditarCategoria1 = false;
  FFUploadedFile uploadedLocalFile_uploadDataEditarCategoria1 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataEditarCategoria1 = '';

  // State field(s) for nombreCategoria widget.
  FocusNode? nombreCategoriaFocusNode2;
  TextEditingController? nombreCategoriaTextController2;
  String? Function(BuildContext, String?)?
      nombreCategoriaTextController2Validator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    expandableExpandableController.dispose();
    nombreCategoriaFocusNode1?.dispose();
    nombreCategoriaTextController1?.dispose();

    nombreOpcionFocusNode?.dispose();
    nombreOpcionTextController?.dispose();

    nombreCategoriaFocusNode2?.dispose();
    nombreCategoriaTextController2?.dispose();
  }
}
