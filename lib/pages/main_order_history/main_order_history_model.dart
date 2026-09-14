import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/index.dart';
import 'main_order_history_widget.dart' show MainOrderHistoryWidget;
import 'package:flutter/material.dart';

class MainOrderHistoryModel extends FlutterFlowModel<MainOrderHistoryWidget> {
  ///  Local state fields for this page.

  List<String> filtro = [];
  void addToFiltro(String item) => filtro.add(item);
  void removeFromFiltro(String item) => filtro.remove(item);
  void removeAtIndexFromFiltro(int index) => filtro.removeAt(index);
  void insertAtIndexInFiltro(int index, String item) =>
      filtro.insert(index, item);
  void updateFiltroAtIndex(int index, Function(String) updateFn) =>
      filtro[index] = updateFn(filtro[index]);

  ///  State fields for stateful widgets in this page.

  // Model for topNav component.
  late TopNavModel topNavModel;

  @override
  void initState(BuildContext context) {
    topNavModel = createModel(context, () => TopNavModel());
  }

  @override
  void dispose() {
    topNavModel.dispose();
  }
}
