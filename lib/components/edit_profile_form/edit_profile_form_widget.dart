import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/backend/supabase/storage/storage.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_icon_button.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_widgets.dart';
import 'package:baul_pandora/flutter_flow/upload_data.dart';
import 'package:baul_pandora/index.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'edit_profile_form_model.dart';
export 'edit_profile_form_model.dart';

class EditProfileFormWidget extends StatefulWidget {
  const EditProfileFormWidget({
    super.key,
    required this.editProfile,
    this.fromPage,
    this.onProfileSaved,
  });

  final bool? editProfile;
  final String? fromPage;
  final Function(String? returnPath)? onProfileSaved;

  @override
  State<EditProfileFormWidget> createState() => _EditProfileFormWidgetState();
}

class _EditProfileFormWidgetState extends State<EditProfileFormWidget> {
  late EditProfileFormModel _model;
  bool _isSaving = false;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditProfileFormModel());

    _model.yourNameFocusNode ??= FocusNode();

    _model.telefonoFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UsuariosRow>>(
      future: UsuariosTable().querySingleRow(
        queryFn: (q) => q.eq(
          'id',
          currentUserUid,
        ),
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Center(
            child: SizedBox(
              width: 50.0,
              height: 50.0,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  FlutterFlowTheme.of(context).primary,
                ),
              ),
            ),
          );
        }
        List<UsuariosRow> columnUsuariosRowList = snapshot.data!;

        final columnUsuariosRow = columnUsuariosRowList.isNotEmpty
            ? columnUsuariosRowList.first
            : null;

        return Column(
          mainAxisSize: MainAxisSize.max,
          children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 0.0, 0.0),
                child: FlutterFlowIconButton(
                  borderColor: Colors.transparent,
                  borderRadius: 30.0,
                  borderWidth: 1.0,
                  buttonSize: 50.0,
                  icon: Icon(
                    Icons.close_rounded,
                    color: FlutterFlowTheme.of(context).primaryText,
                    size: 30.0,
                  ),
                  onPressed: () async {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                child: Text(
                  widget.editProfile == true
                      ? 'Edit Profile'
                      : 'Create Your Profile',
                  style: FlutterFlowTheme.of(context)
                      .headlineMedium
                      .override(
                        font: GoogleFonts.interTight(
                          fontWeight: FlutterFlowTheme.of(context)
                              .headlineMedium
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .headlineMedium
                              .fontStyle,
                        ),
                        color: FlutterFlowTheme.of(context).primaryText,
                        fontSize: 22.0,
                        letterSpacing: 0.0,
                        fontWeight: FlutterFlowTheme.of(context)
                            .headlineMedium
                            .fontWeight,
                        fontStyle: FlutterFlowTheme.of(context)
                            .headlineMedium
                            .fontStyle,
                      ),
                ),
              ),
              const SizedBox(width: 50.0), // Espaciador para centrar el título
            ],
          ),
        ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 44.0, 0.0, 16.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          final selectedMedia =
                              await selectMediaWithSourceBottomSheet(
                            context: context,
                            storageFolderPath: 'fotos_perfil/$currentUserUid/',
                            allowPhoto: true,
                          );
                          if (selectedMedia != null &&
                              selectedMedia.every((m) =>
                                  validateFileFormat(m.storagePath, context))) {
                            safeSetState(() =>
                                _model.isDataUploading_uploadDataKcd34 = true);
                            var selectedUploadedFiles = <FFUploadedFile>[];

                            var downloadUrls = <String>[];
                            try {
                              selectedUploadedFiles = selectedMedia
                                  .map((m) => FFUploadedFile(
                                        name: m.storagePath.split('/').last,
                                        bytes: m.bytes,
                                        height: m.dimensions?.height,
                                        width: m.dimensions?.width,
                                        blurHash: m.blurHash,
                                        originalFilename: m.originalFilename,
                                      ))
                                  .toList();

                              downloadUrls = await uploadSupabaseStorageFiles(
                                bucketName: 'images',
                                selectedFiles: selectedMedia,
                              );
                            } finally {
                              _model.isDataUploading_uploadDataKcd34 = false;
                            }
                            if (selectedUploadedFiles.length ==
                                    selectedMedia.length &&
                                downloadUrls.length == selectedMedia.length) {
                              safeSetState(() {
                                _model.uploadedLocalFile_uploadDataKcd34 =
                                    selectedUploadedFiles.first;
                                _model.uploadedFileUrl_uploadDataKcd34 =
                                    downloadUrls.first;
                              });
                            } else {
                              safeSetState(() {});
                              return;
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
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              child: (  // Conditional display
                                _model.uploadedFileUrl_uploadDataKcd34.isNotEmpty
                                  ? CachedNetworkImage(
                                      fadeInDuration: const Duration(milliseconds: 500),
                                      fadeOutDuration: const Duration(milliseconds: 500),
                                      imageUrl: _model.uploadedFileUrl_uploadDataKcd34,
                                      fit: BoxFit.cover,
                                    ) : (columnUsuariosRow?.photoPath != null && columnUsuariosRow!.photoPath!.isNotEmpty)
                                      ? CachedNetworkImage(
                                          fadeInDuration: const Duration(milliseconds: 500),
                                          fadeOutDuration: const Duration(milliseconds: 500),
                                          imageUrl: columnUsuariosRow!.photoPath!,
                                          fit: BoxFit.cover,
                                        ) : Image.asset( // Placeholder
                                          'assets/images/guestUser.png',
                                          width: 90.0,
                                          height: 90.0,
                                          fit: BoxFit.cover,
                                        )
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_model.uploadedFileUrl_uploadDataKcd34.isNotEmpty || (columnUsuariosRow?.photoPath != null && columnUsuariosRow!.photoPath!.isNotEmpty))
                        Positioned(
                          right: 0,
                          top: 0,
                          child: InkWell(
                            onTap: () async {
                              final currentPhoto = _model.uploadedFileUrl_uploadDataKcd34.isNotEmpty
                                  ? _model.uploadedFileUrl_uploadDataKcd34
                                  : columnUsuariosRow!.photoPath!;
                              
                              await deleteSupabaseFileFromPublicUrl(currentPhoto);
                              await UsuariosTable().update(
                                data: {'photo_path': ''},
                                matchingRows: (rows) => rows.eq('id', currentUserUid),
                              );
                              safeSetState(() {
                                _model.uploadedFileUrl_uploadDataKcd34 = '';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Form(
              key: _model.formKey,
              autovalidateMode: AutovalidateMode.disabled,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 16.0),
                child: TextFormField(
                  controller: _model.yourNameTextController ??=
                      TextEditingController(
                    text: columnUsuariosRow?.nombre != null &&
                            columnUsuariosRow?.nombre != ''
                        ? columnUsuariosRow?.nombre
                        : '',
                  ),
                  focusNode: _model.yourNameFocusNode,
                  textCapitalization: TextCapitalization.words,
                  obscureText: false,
                  decoration: InputDecoration(
                    labelText: 'Tu nombre',
                    labelStyle:
                        FlutterFlowTheme.of(context).labelMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontStyle,
                              ),
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontStyle,
                            ),
                    hintStyle:
                        FlutterFlowTheme.of(context).labelMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .fontStyle,
                              ),
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .fontStyle,
                            ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).primary,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).error,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).error,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                    contentPadding:
                        const EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 0.0, 24.0),
                  ),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        font: GoogleFonts.inter(
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                  cursorColor: FlutterFlowTheme.of(context).primary,
                  validator: _model.yourNameTextControllerValidator
                      .asValidator(context),
                  inputFormatters: [
                    if (!isAndroid && !isiOS)
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        return TextEditingValue(
                          selection: newValue.selection,
                          text: newValue.text
                              .toCapitalization(TextCapitalization.words),
                        );
                      }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 12.0),
              child: TextFormField(
                controller: _model.telefonoTextController ??=
                    TextEditingController(
                  text: columnUsuariosRow?.telefono != null &&
                          columnUsuariosRow?.telefono != ''
                      ? columnUsuariosRow?.telefono
                      : '',
                ),
                focusNode: _model.telefonoFocusNode,
                textCapitalization: TextCapitalization.sentences,
                obscureText: false,
                decoration: InputDecoration(
                  labelText: 'Tu teléfono',
                  labelStyle: FlutterFlowTheme.of(context).labelMedium.override(
                        font: GoogleFonts.inter(
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).labelMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelMedium.fontStyle,
                      ),
                  hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
                        font: GoogleFonts.inter(
                          fontWeight: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontWeight,
                          fontStyle: FlutterFlowTheme.of(context)
                              .labelMedium
                              .fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).labelMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelMedium.fontStyle,
                      ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).primary,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).error,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).error,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  filled: true,
                  fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                  contentPadding:
                      const EdgeInsetsDirectional.fromSTEB(20.0, 24.0, 0.0, 24.0),
                ),
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
                 textAlign: TextAlign.start,
                 cursorColor: FlutterFlowTheme.of(context).primary,
                 validator:
                     _model.telefonoTextControllerValidator.asValidator(context),
                 inputFormatters: [
                   FilteringTextInputFormatter.digitsOnly,
                   if (!isAndroid && !isiOS)
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return TextEditingValue(
                        selection: newValue.selection,
                        text: newValue.text
                            .toCapitalization(TextCapitalization.sentences),
                      );
                    }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
              child: FFButtonWidget(
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    if (_isSaving) return;
                    if (!(_model.formKey.currentState?.validate() ?? false)) return;

                    // 1. Capturar referencias ANTES de la operación asíncrona
                    final messenger = ScaffoldMessenger.of(context);
                    final theme = FlutterFlowTheme.of(context);
                    final router = GoRouter.of(context); 
                    
                    setState(() => _isSaving = true);
                    
                    debugPrint('LOG: Iniciando proceso de guardado.');

                    try {
                      // Operación asíncrona
                      final String newPhotoPath = _model.uploadedFileUrl_uploadDataKcd34.isNotEmpty
                          ? _model.uploadedFileUrl_uploadDataKcd34
                          : (columnUsuariosRow?.photoPath ?? '');

                      if (_model.uploadedFileUrl_uploadDataKcd34.isNotEmpty &&
                          columnUsuariosRow?.photoPath != null &&
                          columnUsuariosRow!.photoPath!.isNotEmpty) {
                        debugPrint('LOG: Intentando eliminar foto anterior: ${columnUsuariosRow!.photoPath!}');
                        try {
                          await deleteSupabaseFileFromPublicUrl(columnUsuariosRow!.photoPath!);
                          debugPrint('LOG: Foto anterior eliminada correctamente.');
                        } catch (e) {
                          debugPrint('ERROR eliminando foto anterior: $e');
                        }
                      }
                      
                      await UsuariosTable().update(
                        data: {
                          'nombre_completo': _model.yourNameTextController.text,
                          'telefono': _model.telefonoTextController.text,
                          'photo_path': newPhotoPath,
                        },
                        matchingRows: (rows) => rows.eq('id', currentUserUid),
                      );
                      
                      debugPrint('LOG: Update exitoso.');

                      // 2. Verificar si sigue montado ANTES de usar referencias de UI
                      if (!mounted) return;

                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Perfil actualizado con éxito!'),
                          backgroundColor: theme.primary,
                        ),
                      );

                      // Cerrar el modal después de guardar
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                      
                    } catch (e) {
                      debugPrint('ERROR: $e');
                      if (mounted) setState(() => _isSaving = false);
                    }
                  },
                text: 'Guardar cambios',
                options: FFButtonOptions(
                  height: 44.0,
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        fontFamily: 'Inter Tight',
                        color: Colors.white,
                      ),
                  borderRadius: BorderRadius.circular(50.0),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
