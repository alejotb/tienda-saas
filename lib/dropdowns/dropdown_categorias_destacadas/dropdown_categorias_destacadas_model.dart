import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'dropdown_categorias_destacadas_widget.dart'
    show DropdownCategoriasDestacadasWidget;
import 'package:flutter/material.dart';

class DropdownCategoriasDestacadasModel
    extends FlutterFlowModel<DropdownCategoriasDestacadasWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for Checkbox widget.
  Map<CategoriasRow, bool> checkboxValueMap = {};
  List<CategoriasRow> get checkboxCheckedItems =>
      checkboxValueMap.entries.where((e) => e.value).map((e) => e.key).toList();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
