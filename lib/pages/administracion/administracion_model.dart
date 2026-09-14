import 'package:baul_pandora/backend/api_requests/api_calls.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/index.dart';
import 'administracion_widget.dart' show AdministracionWidget;
import 'package:flutter/material.dart';

enum AdminView {
  general,
  pagos,
  despachos,
  products,
  orders,
  users,
  discounts,
  audit,
}

class AdministracionModel extends FlutterFlowModel<AdministracionWidget> {
  AdminView currentView = AdminView.general;

  List<String> prueba = [];
  void addToPrueba(String item) => prueba.add(item);
  void removeFromPrueba(String item) => prueba.remove(item);
  void removeAtIndexFromPrueba(int index) => prueba.removeAt(index);
  void insertAtIndexInPrueba(int index, String item) => prueba.insert(index, item);
  void updatePruebaAtIndex(int index, Function(String) updateFn) => prueba[index] = updateFn(prueba[index]);

  ApiCallResponse? resWoo;
  ApiCallResponse? pedidosWoo;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
