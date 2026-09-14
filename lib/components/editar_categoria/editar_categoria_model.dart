import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'editar_categoria_widget.dart' show EditarCategoriaWidget;
import 'package:flutter/material.dart';

class EditarCategoriaModel extends FlutterFlowModel<EditarCategoriaWidget> {
  ///  Local state fields for this component.

  CategoriaStruct? categoriaNueva;
  void updateCategoriaNuevaStruct(Function(CategoriaStruct) updateFn) {
    updateFn(categoriaNueva ??= CategoriaStruct());
  }

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

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
