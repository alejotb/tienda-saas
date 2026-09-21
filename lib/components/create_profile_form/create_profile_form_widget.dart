import 'dart:typed_data';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/backend/supabase/storage/storage.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_widgets.dart';
import 'package:baul_pandora/flutter_flow/upload_data.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateProfileFormModel extends FlutterFlowModel {
  final formKey = GlobalKey<FormState>();
  TextEditingController? yourNameTextController;
  TextEditingController? telefonoTextController;
  String? Function(String?)? yourNameTextControllerValidator;
  String? Function(String?)? telefonoTextControllerValidator;
  FocusNode? yourNameFocusNode;
  FocusNode? telefonoFocusNode;
  bool isDataUploading = false;
  FFUploadedFile uploadedLocalFile = FFUploadedFile(bytes: Uint8List(0));
  String uploadedFileUrl = '';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    yourNameTextController?.dispose();
    yourNameFocusNode?.dispose();
    telefonoTextController?.dispose();
    telefonoFocusNode?.dispose();
  }
}

class CreateProfileFormWidget extends StatefulWidget {
  const CreateProfileFormWidget({
    super.key,
    this.fromPage,
    this.onProfileSaved,
  });

  final String? fromPage;
  final Function(String? returnPath)? onProfileSaved;

  @override
  State<CreateProfileFormWidget> createState() => _CreateProfileFormWidgetState();
}

class _CreateProfileFormWidgetState extends State<CreateProfileFormWidget> {
  late CreateProfileFormModel _model;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CreateProfileFormModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 44.0, 0.0, 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () async {
                    final selectedMedia = await selectMediaWithSourceBottomSheet(
                      context: context,
                      storageFolderPath: 'fotos_perfil/$currentUserUid/',
                      allowPhoto: true,
                    );
                    if (selectedMedia != null &&
                        selectedMedia.every((m) => validateFileFormat(m.storagePath, context))) {
                      setState(() => _model.isDataUploading = true);
                      var downloadUrls = <String>[];
                      try {
                        downloadUrls = await uploadSupabaseStorageFiles(
                          bucketName: 'images',
                          selectedFiles: selectedMedia,
                        );
                      } finally {
                        setState(() => _model.isDataUploading = false);
                      }
                      if (downloadUrls.length == selectedMedia.length) {
                        setState(() {
                          _model.uploadedFileUrl = downloadUrls.first;
                        });
                      }
                    }
                  },
                  child: Container(
                    width: 100.0,
                    height: 100.0,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).alternate,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Container(
                        width: 90.0,
                        height: 90.0,
                        clipBehavior: Clip.antiAlias,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: _model.uploadedFileUrl.isNotEmpty
                            ? CachedNetworkImage(imageUrl: _model.uploadedFileUrl, fit: BoxFit.cover)
                            : Image.asset('assets/images/guestUser.png', fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Form(
            key: _model.formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 16.0),
                  child: TextFormField(
                    controller: _model.yourNameTextController ??= TextEditingController(),
                    focusNode: _model.yourNameFocusNode ??= FocusNode(),
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => _model.telefonoFocusNode?.requestFocus(),
                    decoration: InputDecoration(labelText: 'Nombre'),
                    validator: _model.yourNameTextControllerValidator,
                    ),
                    ),
                    Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 16.0),
                    child: TextFormField(
                    controller: _model.telefonoTextController ??= TextEditingController(),
                    focusNode: _model.telefonoFocusNode ??= FocusNode(),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(labelText: 'Teléfono'),
                    validator: _model.telefonoTextControllerValidator,
                    ),
                    ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
            child: FFButtonWidget(
              onPressed: () async {
                if (!(_model.formKey.currentState?.validate() ?? false)) return;
                setState(() => _isSaving = true);
                try {
                  await UsuariosTable().update(
                    data: {
                      'nombre_completo': _model.yourNameTextController.text,
                      'telefono': _model.telefonoTextController.text,
                      'photo_path': _model.uploadedFileUrl,
                    },
                    matchingRows: (rows) => rows.eq('id', currentUserUid),
                  );
                  if (widget.onProfileSaved != null) {
                    widget.onProfileSaved!(widget.fromPage);
                  }
                } catch (e) {
                  debugPrint('ERROR: $e');
                } finally {
                  if (mounted) setState(() => _isSaving = false);
                }
              },
              text: 'Crear perfil',
              options: FFButtonOptions(height: 44.0, color: FlutterFlowTheme.of(context).primary),
            ),
          ),
        ],
      ),
    );
  }
}
