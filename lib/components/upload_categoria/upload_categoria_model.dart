import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/components/crear_categorias_generales/crear_categorias_generales_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'upload_categoria_widget.dart' show UploadCategoriaWidget;
import 'package:flutter/material.dart';

class UploadCategoriaModel extends FlutterFlowModel<UploadCategoriaWidget> {
  ///  Local state fields for this component.

  List<CategoriaStruct> categoriaNueva = [];
  void addToCategoriaNueva(CategoriaStruct item) => categoriaNueva.add(item);
  void removeFromCategoriaNueva(CategoriaStruct item) =>
      categoriaNueva.remove(item);
  void removeAtIndexFromCategoriaNueva(int index) =>
      categoriaNueva.removeAt(index);
  void insertAtIndexInCategoriaNueva(int index, CategoriaStruct item) =>
      categoriaNueva.insert(index, item);
  void updateCategoriaNuevaAtIndex(
          int index, Function(CategoriaStruct) updateFn) =>
      categoriaNueva[index] = updateFn(categoriaNueva[index]);

  List<int> categoriaNum = [];
  void addToCategoriaNum(int item) => categoriaNum.add(item);
  void removeFromCategoriaNum(int item) => categoriaNum.remove(item);
  void removeAtIndexFromCategoriaNum(int index) => categoriaNum.removeAt(index);
  void insertAtIndexInCategoriaNum(int index, int item) =>
      categoriaNum.insert(index, item);
  void updateCategoriaNumAtIndex(int index, Function(int) updateFn) =>
      categoriaNum[index] = updateFn(categoriaNum[index]);

  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // Model for crear_categoriasGenerales component.
  late CrearCategoriasGeneralesModel crearCategoriasGeneralesModel2;
  // Stores action output result for [Backend Call - Insert Row] action in Button widget.
  CategoriasRow? categoriaGeneralNueva;

  @override
  void initState(BuildContext context) {
    crearCategoriasGeneralesModel2 =
        createModel(context, () => CrearCategoriasGeneralesModel());
  }

  @override
  void dispose() {
    crearCategoriasGeneralesModel2.dispose();
  }
}
