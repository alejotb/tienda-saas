import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'tarjeta_pedidos_widget.dart' show TarjetaPedidosWidget;
import 'package:flutter/material.dart';

class TarjetaPedidosModel extends FlutterFlowModel<TarjetaPedidosWidget> {
  ///  Local state fields for this component.

  PagoStruct? pago;
  void updatePagoStruct(Function(PagoStruct) updateFn) {
    updateFn(pago ??= PagoStruct());
  }

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
