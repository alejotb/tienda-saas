import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'tarjeta_producto_widget.dart' show TarjetaProductoWidget;
import 'package:flutter/material.dart';

class TarjetaProductoModel extends FlutterFlowModel<TarjetaProductoWidget> {
  ///  Local state fields for this component.

  int? indexImages = 0;
  List<String> combinedImages = [];

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - Insert Row] action in addToCart widget.
  PedidosRow? nuevoPedidoPhone2;
  // Stores action output result for [Backend Call - Insert Row] action in Container widget.
  PedidosRow? nuevoPedidoPhone2Copy;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
