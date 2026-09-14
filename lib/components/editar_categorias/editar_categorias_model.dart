import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'editar_categorias_widget.dart' show EditarCategoriasWidget;
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';

class EditarCategoriasModel extends FlutterFlowModel<EditarCategoriasWidget> {
  ///  Local state fields for this component.

  String estado = 'Guardado';

  ///  State fields for stateful widgets in this component.

  // State field(s) for Expandable widget.
  late ExpandableController expandableExpandableController;

  bool isDataUploading_uploadDataIf0 = false;
  FFUploadedFile uploadedLocalFile_uploadDataIf0 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataIf0 = '';

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // State field(s) for Checkbox widget.
  bool? checkboxValue;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    expandableExpandableController.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
