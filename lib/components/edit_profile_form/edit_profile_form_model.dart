import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'edit_profile_form_widget.dart' show EditProfileFormWidget;
import 'package:flutter/material.dart';

class EditProfileFormModel extends FlutterFlowModel<EditProfileFormWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  bool isDataUploading_uploadDataKcd34 = false;
  FFUploadedFile uploadedLocalFile_uploadDataKcd34 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataKcd34 = '';

  // State field(s) for yourName widget.
  FocusNode? yourNameFocusNode;
  TextEditingController? yourNameTextController;
  String? Function(BuildContext, String?)? yourNameTextControllerValidator;
  String? _yourNameTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'Tu nombre is required';
    }

    return null;
  }

  // State field(s) for telefono widget.
  FocusNode? telefonoFocusNode;
  TextEditingController? telefonoTextController;
  String? Function(BuildContext, String?)? telefonoTextControllerValidator;
  String? _telefonoTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return 'El teléfono es requerido';
    }
    if (val.length != 11) {
      return 'El teléfono debe tener exactamente 11 dígitos (ej: 04121234567)';
    }
    if (!RegExp(r'^\d{11}$').hasMatch(val)) {
      return 'El teléfono debe contener solo números';
    }
    return null;
  }

  @override
  void initState(BuildContext context) {
    yourNameTextControllerValidator = _yourNameTextControllerValidator;
    telefonoTextControllerValidator = _telefonoTextControllerValidator;
  }

  @override
  void dispose() {
    yourNameFocusNode?.dispose();
    yourNameTextController?.dispose();

    telefonoFocusNode?.dispose();
    telefonoTextController?.dispose();
  }
}
