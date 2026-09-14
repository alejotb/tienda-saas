import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'mostrar_pedido_widget.dart' show MostrarPedidoWidget;
import 'package:flutter/material.dart';

class MostrarPedidoModel extends FlutterFlowModel<MostrarPedidoWidget> {
  ///  Local state fields for this component.

  AddressStruct? address;
  void updateAddressStruct(Function(AddressStruct) updateFn) {
    updateFn(address ??= AddressStruct());
  }

  PagoStruct? pago;
  void updatePagoStruct(Function(PagoStruct) updateFn) {
    updateFn(pago ??= PagoStruct());
  }

  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
