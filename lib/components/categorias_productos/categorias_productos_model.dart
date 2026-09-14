import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'categorias_productos_widget.dart' show CategoriasProductosWidget;
import 'package:flutter/material.dart';

class CategoriasProductosModel
    extends FlutterFlowModel<CategoriasProductosWidget> {
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

  bool agregarCategoria = false;

  ///  State fields for stateful widgets in this component.

  // State field(s) for NombreOpcion widget.
  FocusNode? nombreOpcionFocusNode;
  TextEditingController? nombreOpcionTextController;
  String? Function(BuildContext, String?)? nombreOpcionTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nombreOpcionFocusNode?.dispose();
    nombreOpcionTextController?.dispose();
  }
}
