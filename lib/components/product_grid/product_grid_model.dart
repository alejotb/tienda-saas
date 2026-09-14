import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'product_grid_widget.dart' show ProductGridWidget;
import 'package:flutter/material.dart';

class ProductGridModel extends FlutterFlowModel<ProductGridWidget> {
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
  List<String> combinedImages = [];

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - Query Rows] action in productGrid widget.
  List<UsuariosRow>? usuario;
  // Stores action output result for [Backend Call - Insert Row] action in addToCart widget.
  PedidosRow? nuevoPedido;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
