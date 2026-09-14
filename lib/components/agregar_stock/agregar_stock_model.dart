import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/form_field_controller.dart';
import 'agregar_stock_widget.dart' show AgregarStockWidget;
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';

class AgregarStockModel extends FlutterFlowModel<AgregarStockWidget> {
  ///  Local state fields for this component.

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

  ProductoStruct? productoNuevo;
  void updateProductoNuevoStruct(Function(ProductoStruct) updateFn) {
    updateFn(productoNuevo ??= ProductoStruct());
  }

  String? auxId;

  String? uuidTemp;

  List<String> images = [];
  void addToImages(String item) => images.add(item);
  void removeFromImages(String item) => images.remove(item);
  void removeAtIndexFromImages(int index) => images.removeAt(index);
  void insertAtIndexInImages(int index, String item) =>
      images.insert(index, item);
  void updateImagesAtIndex(int index, Function(String) updateFn) =>
      images[index] = updateFn(images[index]);

  int? imagesIndex = 0;

  String estado = 'Crear';

  String? auxProductId;

  List<String> productosStock = [];
  void addToProductosStock(String item) => productosStock.add(item);
  void removeFromProductosStock(String item) => productosStock.remove(item);
  void removeAtIndexFromProductosStock(int index) =>
      productosStock.removeAt(index);
  void insertAtIndexInProductosStock(int index, String item) =>
      productosStock.insert(index, item);
  void updateProductosStockAtIndex(int index, Function(String) updateFn) =>
      productosStock[index] = updateFn(productosStock[index]);

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - Query Rows] action in agregar_stock widget.
  List<ProductosRow>? nombresProductos;
  // State field(s) for Expandable widget.
  late ExpandableController expandableExpandableController;

  // State field(s) for Checkbox widget.
  bool? checkboxValue;
  bool isDataUploading_uploadProductPhoto24h = false;
  FFUploadedFile uploadedLocalFile_uploadProductPhoto24h =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadProductPhoto24h = '';

  // State field(s) for nombreProducto widget.
  FocusNode? nombreProductoFocusNode;
  TextEditingController? nombreProductoTextController;
  String? Function(BuildContext, String?)?
      nombreProductoTextControllerValidator;
  // State field(s) for descripcionProducto widget.
  FocusNode? descripcionProductoFocusNode;
  TextEditingController? descripcionProductoTextController;
  String? Function(BuildContext, String?)?
      descripcionProductoTextControllerValidator;
  // State field(s) for CountController widget.
  int? countControllerValue1;
  // State field(s) for precio widget.
  FocusNode? precioFocusNode;
  TextEditingController? precioTextController;
  String? Function(BuildContext, String?)? precioTextControllerValidator;
  // Stores action output result for [Backend Call - Query Rows] action in categorias_generales widget.
  List<CategoriasRow>? categorias2;
  // State field(s) for nombreProducto widget.
  String? nombreProductoValue;
  FormFieldController<String>? nombreProductoValueController;
  // State field(s) for CountController widget.
  int? countControllerValue2;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    expandableExpandableController.dispose();
    nombreProductoFocusNode?.dispose();
    nombreProductoTextController?.dispose();

    descripcionProductoFocusNode?.dispose();
    descripcionProductoTextController?.dispose();

    precioFocusNode?.dispose();
    precioTextController?.dispose();
  }
}
