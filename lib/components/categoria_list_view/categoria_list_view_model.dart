import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'categoria_list_view_widget.dart' show CategoriaListViewWidget;
import 'package:flutter/material.dart';

class CategoriaListViewModel extends FlutterFlowModel<CategoriaListViewWidget> {
  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - Query Rows] action in categoria_listView widget.
  List<UsuariosRow>? usuario;
  // Stores action output result for [Backend Call - Query Rows] action in categoria_listView widget.
  List<PedidosRow>? carrito;
  // Stores action output result for [Backend Call - Query Rows] action in categoria_listView widget.
  List<PedidoItemsRow>? productosCarrito;
  // State field(s) for Checkbox widget.
  bool? checkboxValue;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
