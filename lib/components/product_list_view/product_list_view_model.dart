import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'product_list_view_widget.dart' show ProductListViewWidget;
import 'package:flutter/material.dart';

class ProductListViewModel extends FlutterFlowModel<ProductListViewWidget> {
  ///  Local state fields for this component.

  bool? favorited = true;

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - Query Rows] action in product_listView widget.
  List<UsuariosRow>? usuario;
  // Stores action output result for [Backend Call - Query Rows] action in product_listView widget.
  List<PedidosRow>? carrito;
  // Stores action output result for [Backend Call - Query Rows] action in product_listView widget.
  List<PedidoItemsRow>? productosCarrito;
  // Stores action output result for [Backend Call - Insert Row] action in addToCart widget.
  PedidosRow? nuevoPedidoPhone;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
