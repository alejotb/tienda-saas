import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/components/empty_state/empty_state_widget.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/index.dart';
import 'main_home_page_widget.dart' show MainHomePageWidget;
import 'package:flutter/material.dart';

class MainHomePageModel extends FlutterFlowModel<MainHomePageWidget> {
  ///  Local state fields for this page.

  bool get isAdmin => FFAppState().isAdmin;

  List<String> nombreCategorias = [];
  void addToNombreCategorias(String item) => nombreCategorias.add(item);
  void removeFromNombreCategorias(String item) => nombreCategorias.remove(item);
  void removeAtIndexFromNombreCategorias(int index) =>
      nombreCategorias.removeAt(index);
  void insertAtIndexInNombreCategorias(int index, String item) =>
      nombreCategorias.insert(index, item);
  void updateNombreCategoriasAtIndex(int index, Function(String) updateFn) =>
      nombreCategorias[index] = updateFn(nombreCategorias[index]);

  String? selectedCategoryId;
  String? selectedCategoryName;
  String? carritoActual;


  List<String> favoritos = [];
  void addToFavoritos(String item) => favoritos.add(item);
  void removeFromFavoritos(String item) => favoritos.remove(item);
  void removeAtIndexFromFavoritos(int index) => favoritos.removeAt(index);
  void insertAtIndexInFavoritos(int index, String item) =>
      favoritos.insert(index, item);
  void updateFavoritosAtIndex(int index, Function(String) updateFn) =>
      favoritos[index] = updateFn(favoritos[index]);

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Query Rows] action in mainHomePage widget.
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
