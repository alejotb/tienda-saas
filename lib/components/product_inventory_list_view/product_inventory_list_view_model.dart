import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'product_inventory_list_view_widget.dart'
    show ProductInventoryListViewWidget;
import 'package:flutter/material.dart';

class ProductInventoryListViewModel
    extends FlutterFlowModel<ProductInventoryListViewWidget> {
  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - Query Rows] action in productInventory_listView widget.
  List<UsuariosRow>? usuario;
  // Stores action output result for [Backend Call - Query Rows] action in productInventory_listView widget.
  List<PedidosRow>? carrito;
  // Stores action output result for [Backend Call - Query Rows] action in productInventory_listView widget.
  List<PedidoItemsRow>? productosCarrito;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
