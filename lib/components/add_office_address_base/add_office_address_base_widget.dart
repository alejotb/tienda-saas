import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_office_address_base_model.dart';
import 'package:baul_pandora/services/venezuela_location_service.dart';

class AddOfficeAddressBaseWidget extends StatefulWidget {
  const AddOfficeAddressBaseWidget({
    super.key,
    required this.action,
    required this.customDialog,
  });

  final Future Function()? action;
  final bool? customDialog;

  @override
  State<AddOfficeAddressBaseWidget> createState() => _AddOfficeAddressBaseWidgetState();
}

class _AddOfficeAddressBaseWidgetState extends State<AddOfficeAddressBaseWidget> {
  late AddOfficeAddressBaseModel _model;
  List<String> _stateSuggestions = [];
  List<String> _citySuggestions = [];
  bool _showStateSuggestions = false;
  bool _showCitySuggestions = false;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddOfficeAddressBaseModel());
    _model.officeNameTextController ??= TextEditingController();
    _model.officeNameFocusNode ??= FocusNode();
    _model.addressTextController ??= TextEditingController();
    _model.addressFocusNode ??= FocusNode();
    _model.clonableURLTextController ??= TextEditingController();
    _model.clonableURLFocusNode ??= FocusNode();
    _model.cityTextController ??= TextEditingController();
    _model.cityFocusNode ??= FocusNode();
    _model.stateTextController ??= TextEditingController();
    _model.stateFocusNode ??= FocusNode();
    
    VenezuelaLocationService().init().then((_) {
      _model.stateTextController?.addListener(() {
        final query = _model.stateTextController?.text ?? '';
        setState(() {
          _stateSuggestions = VenezuelaLocationService().getStates(query);
          _showStateSuggestions =
              query.isNotEmpty && _stateSuggestions.isNotEmpty;
          _model.cityTextController?.clear();
          _citySuggestions = [];
          _showCitySuggestions = false;
        });
      });
      _model.cityTextController?.addListener(() {
        final state = _model.stateTextController?.text ?? '';
        final query = _model.cityTextController?.text ?? '';
        setState(() {
          _citySuggestions = VenezuelaLocationService().getCities(state, query);
          _showCitySuggestions =
              query.isNotEmpty && _citySuggestions.isNotEmpty;
        });
      });
    });
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _model.formKey,
      autovalidateMode: AutovalidateMode.disabled,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
              child: TextFormField(
                controller: _model.officeNameTextController,
                focusNode: _model.officeNameFocusNode,
                autofocus: true,
                obscureText: false,
                decoration: InputDecoration(
                  labelText: 'Nombre de la Oficina',
                  labelStyle: FlutterFlowTheme.of(context).labelLarge,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).primary,
                      width: 2.0,
                    ),
                  ),
                ),
                style: FlutterFlowTheme.of(context).bodyLarge,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre de la oficina es requerido';
                  }
                  return _model.officeNameTextControllerValidator?.call(context, value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
              child: TextFormField(
                controller: _model.addressTextController,
                focusNode: _model.addressFocusNode,
                obscureText: false,
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  labelStyle: FlutterFlowTheme.of(context).labelLarge,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).primary,
                      width: 2.0,
                    ),
                  ),
                ),
                style: FlutterFlowTheme.of(context).bodyLarge,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La dirección es requerida';
                  }
                  return _model.addressTextControllerValidator?.call(context, value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
              child: TextFormField(
                controller: _model.clonableURLTextController,
                focusNode: _model.clonableURLFocusNode,
                obscureText: false,
                decoration: InputDecoration(
                  labelText: 'Dirección postal 2 (opcional)',
                  labelStyle: FlutterFlowTheme.of(context).labelLarge,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: FlutterFlowTheme.of(context).primary,
                      width: 2.0,
                    ),
                  ),
                ),
                style: FlutterFlowTheme.of(context).bodyLarge,
                validator: _model.clonableURLTextControllerValidator?.asValidator(context),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _model.stateTextController,
                    focusNode: _model.stateFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Estado',
                      labelStyle: FlutterFlowTheme.of(context).labelLarge,
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).alternate,
                            width: 2.0),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).primary,
                            width: 2.0),
                      ),
                    ),
                    style: FlutterFlowTheme.of(context).bodyLarge,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'El estado es requerido';
                      }
                      return _model.stateTextControllerValidator?.call(context, value);
                    },
                  ),
                  if (_showStateSuggestions)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: FlutterFlowTheme.of(context).alternate),
                        boxShadow: const [
                          BoxShadow(
                              blurRadius: 4,
                              color: Colors.black12,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: _stateSuggestions
                            .map((state) => ListTile(
                                  title: Text(state,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium),
                                  onTap: () {
                                    _model.stateTextController?.text = state;
                                    _model.cityTextController?.clear();
                                    setState(() {
                                      _showStateSuggestions = false;
                                      _citySuggestions = [];
                                      _showCitySuggestions = false;
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _model.cityTextController,
                    focusNode: _model.cityFocusNode,
                    decoration: InputDecoration(
                      labelText: 'Ciudad',
                      labelStyle: FlutterFlowTheme.of(context).labelLarge,
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).alternate,
                            width: 2.0),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: FlutterFlowTheme.of(context).primary,
                            width: 2.0),
                      ),
                    ),
                    style: FlutterFlowTheme.of(context).bodyLarge,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'La ciudad es requerida';
                      }
                      return _model.cityTextControllerValidator?.call(context, value);
                    },
                  ),
                  if (_showCitySuggestions)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: FlutterFlowTheme.of(context).alternate),
                        boxShadow: const [
                          BoxShadow(
                              blurRadius: 4,
                              color: Colors.black12,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: _citySuggestions
                            .map((city) => ListTile(
                                  title: Text(city,
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium),
                                  onTap: () {
                                    _model.cityTextController?.text = city;
                                    setState(() {
                                      _showCitySuggestions = false;
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FFButtonWidget(
                    onPressed: () async {
                      if (_model.formKey.currentState == null ||
                          !_model.formKey.currentState!.validate()) {
                        return;
                      }
                      await widget.action?.call();
                    },
                    text: 'Guardar dirección',
                    options: FFButtonOptions(
                      height: 44.0,
                      padding:
                          const EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                      iconPadding:
                          const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                      color: FlutterFlowTheme.of(context).primary,
                      textStyle:
                          FlutterFlowTheme.of(context).titleSmall.override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontStyle,
                              ),
                      elevation: 2.0,
                      borderSide: const BorderSide(
                        color: Colors.transparent,
                        width: 1.0,
                      ),
                      borderRadius: BorderRadius.circular(50.0),
                      hoverColor: FlutterFlowTheme.of(context).accent1,
                      hoverBorderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).primary,
                        width: 1.0,
                      ),
                      hoverTextColor: FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
