import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/form_field_controller.dart';
import 'categorias_generales_widget.dart' show CategoriasGeneralesWidget;
import 'package:flutter/material.dart';

class CategoriasGeneralesModel
    extends FlutterFlowModel<CategoriasGeneralesWidget> {
  ///  Local state fields for this component.

  List<String> categoriasHijas = [];
  void addToCategoriasHijas(String item) => categoriasHijas.add(item);
  void removeFromCategoriasHijas(String item) => categoriasHijas.remove(item);
  void removeAtIndexFromCategoriasHijas(int index) =>
      categoriasHijas.removeAt(index);
  void insertAtIndexInCategoriasHijas(int index, String item) =>
      categoriasHijas.insert(index, item);
  void updateCategoriasHijasAtIndex(int index, Function(String) updateFn) =>
      categoriasHijas[index] = updateFn(categoriasHijas[index]);

  bool agregarCategoria = false;

  ///  State fields for stateful widgets in this component.

  // State field(s) for ChoiceChips widget.
  FormFieldController<List<String>>? choiceChipsValueController;
  String? get choiceChipsValue =>
      choiceChipsValueController?.value?.firstOrNull;
  set choiceChipsValue(String? val) =>
      choiceChipsValueController?.value = val != null ? [val] : [];
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
