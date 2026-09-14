import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/form_field_controller.dart';
import 'pedido_grid_widget.dart' show PedidoGridWidget;
import 'package:flutter/material.dart';

class PedidoGridModel extends FlutterFlowModel<PedidoGridWidget> {
  ///  Local state fields for this component.

  List<String> itemsFavoritos = [];
  void addToItemsFavoritos(String item) => itemsFavoritos.add(item);
  void removeFromItemsFavoritos(String item) => itemsFavoritos.remove(item);
  void removeAtIndexFromItemsFavoritos(int index) =>
      itemsFavoritos.removeAt(index);
  void insertAtIndexInItemsFavoritos(int index, String item) =>
      itemsFavoritos.insert(index, item);
  void updateItemsFavoritosAtIndex(int index, Function(String) updateFn) =>
      itemsFavoritos[index] = updateFn(itemsFavoritos[index]);

  int? indexImages = 0;

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - Query Rows] action in pedidoGrid widget.
  List<UsuariosRow>? usuario;
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
