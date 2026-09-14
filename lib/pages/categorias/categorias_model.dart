import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'categorias_widget.dart' show CategoriasWidget;
import 'package:flutter/material.dart';

class CategoriasModel extends FlutterFlowModel<CategoriasWidget> {
  ///  Local state fields for this page.

  List<String> listaIdFavoritos = [];
  void addToListaIdFavoritos(String item) => listaIdFavoritos.add(item);
  void removeFromListaIdFavoritos(String item) => listaIdFavoritos.remove(item);
  void removeAtIndexFromListaIdFavoritos(int index) =>
      listaIdFavoritos.removeAt(index);
  void insertAtIndexInListaIdFavoritos(int index, String item) =>
      listaIdFavoritos.insert(index, item);
  void updateListaIdFavoritosAtIndex(int index, Function(String) updateFn) =>
      listaIdFavoritos[index] = updateFn(listaIdFavoritos[index]);

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Query Rows] action in categorias widget.
  List<UsuariosRow>? usuario;
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
