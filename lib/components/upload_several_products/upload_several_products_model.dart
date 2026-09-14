import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'upload_several_products_widget.dart' show UploadSeveralProductsWidget;
import 'package:flutter/material.dart';

class UploadSeveralProductsModel
    extends FlutterFlowModel<UploadSeveralProductsWidget> {
  ///  Local state fields for this component.

  List<ProductoStruct> productoNuevo = [];
  void addToProductoNuevo(ProductoStruct item) => productoNuevo.add(item);
  void removeFromProductoNuevo(ProductoStruct item) =>
      productoNuevo.remove(item);
  void removeAtIndexFromProductoNuevo(int index) =>
      productoNuevo.removeAt(index);
  void insertAtIndexInProductoNuevo(int index, ProductoStruct item) =>
      productoNuevo.insert(index, item);
  void updateProductoNuevoAtIndex(
          int index, Function(ProductoStruct) updateFn) =>
      productoNuevo[index] = updateFn(productoNuevo[index]);

  List<int> productoNum = [];
  void addToProductoNum(int item) => productoNum.add(item);
  void removeFromProductoNum(int item) => productoNum.remove(item);
  void removeAtIndexFromProductoNum(int index) => productoNum.removeAt(index);
  void insertAtIndexInProductoNum(int index, int item) =>
      productoNum.insert(index, item);
  void updateProductoNumAtIndex(int index, Function(int) updateFn) =>
      productoNum[index] = updateFn(productoNum[index]);

  List<ProductoUpdateStruct> productoActualizado = [];
  void addToProductoActualizado(ProductoUpdateStruct item) =>
      productoActualizado.add(item);
  void removeFromProductoActualizado(ProductoUpdateStruct item) =>
      productoActualizado.remove(item);
  void removeAtIndexFromProductoActualizado(int index) =>
      productoActualizado.removeAt(index);
  void insertAtIndexInProductoActualizado(
          int index, ProductoUpdateStruct item) =>
      productoActualizado.insert(index, item);
  void updateProductoActualizadoAtIndex(
          int index, Function(ProductoUpdateStruct) updateFn) =>
      productoActualizado[index] = updateFn(productoActualizado[index]);

  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  ProductosRow? categoriaGeneralNueva;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
