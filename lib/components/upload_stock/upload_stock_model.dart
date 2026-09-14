import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'upload_stock_widget.dart' show UploadStockWidget;
import 'package:flutter/material.dart';

class UploadStockModel extends FlutterFlowModel<UploadStockWidget> {
  ///  Local state fields for this component.

  List<int> productos = [];
  void addToProductos(int item) => productos.add(item);
  void removeFromProductos(int item) => productos.remove(item);
  void removeAtIndexFromProductos(int index) => productos.removeAt(index);
  void insertAtIndexInProductos(int index, int item) =>
      productos.insert(index, item);
  void updateProductosAtIndex(int index, Function(int) updateFn) =>
      productos[index] = updateFn(productos[index]);

  List<ProductoStruct> productosNuevos = [];
  void addToProductosNuevos(ProductoStruct item) => productosNuevos.add(item);
  void removeFromProductosNuevos(ProductoStruct item) =>
      productosNuevos.remove(item);
  void removeAtIndexFromProductosNuevos(int index) =>
      productosNuevos.removeAt(index);
  void insertAtIndexInProductosNuevos(int index, ProductoStruct item) =>
      productosNuevos.insert(index, item);
  void updateProductosNuevosAtIndex(
          int index, Function(ProductoStruct) updateFn) =>
      productosNuevos[index] = updateFn(productosNuevos[index]);

  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
