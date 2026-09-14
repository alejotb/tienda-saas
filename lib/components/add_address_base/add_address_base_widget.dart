import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_address_base_model.dart';
export 'add_address_base_model.dart';
import 'package:baul_pandora/services/venezuela_location_service.dart';

class AddAddressBaseWidget extends StatefulWidget {
  const AddAddressBaseWidget({
    super.key,
    required this.action,
    required this.customDialog,
  });

  final Future Function()? action;
  final bool? customDialog;

  @override
  State<AddAddressBaseWidget> createState() => _AddAddressBaseWidgetState();
}

class _AddAddressBaseWidgetState extends State<AddAddressBaseWidget> {
  late AddAddressBaseModel _model;
  List<String> _stateSuggestions = [];
  List<String> _citySuggestions = [];

  final LayerLink _stateLayerLink = LayerLink();
  final LayerLink _cityLayerLink = LayerLink();
  final GlobalKey _stateKey = GlobalKey();
  final GlobalKey _cityKey = GlobalKey();
  OverlayEntry? _stateOverlayEntry;
  OverlayEntry? _cityOverlayEntry;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AddAddressBaseModel());
    _model.addressTextController ??= TextEditingController();
    _model.addressFocusNode ??= FocusNode();
    _model.clonableURLTextController ??= TextEditingController();
    _model.clonableURLFocusNode ??= FocusNode();
    _model.cityTextController ??= TextEditingController();
    _model.cityFocusNode ??= FocusNode();
    _model.stateTextController ??= TextEditingController();
    _model.stateFocusNode ??= FocusNode();

    _model.stateFocusNode?.addListener(_onStateFocusChange);
    _model.cityFocusNode?.addListener(_onCityFocusChange);

    // Inicializar servicio y configurar listeners de búsqueda
    VenezuelaLocationService().init().then((_) {
      _model.stateTextController?.addListener(() {
        final query = _model.stateTextController?.text ?? '';
        setState(() {
          _stateSuggestions = VenezuelaLocationService().getStates(query);
          _model.cityTextController?.clear();
          _citySuggestions = [];
        });
        _updateStateOverlay();
      });
      _model.cityTextController?.addListener(() {
        final state = _model.stateTextController?.text ?? '';
        final query = _model.cityTextController?.text ?? '';
        setState(() {
          _citySuggestions = VenezuelaLocationService().getCities(state, query);
        });
        _updateCityOverlay();
      });
    });
  }

  void _onStateFocusChange() {
    if (_model.stateFocusNode?.hasFocus == true) {
      _updateStateOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _hideStateOverlay();
      });
    }
  }

  void _onCityFocusChange() {
    if (_model.cityFocusNode?.hasFocus == true) {
      _updateCityOverlay();
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _hideCityOverlay();
      });
    }
  }

  double _getWidgetWidth(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300.0;
  }

  void _updateStateOverlay() {
    _hideStateOverlay();
    final query = _model.stateTextController?.text ?? '';
    if (query.isEmpty || _stateSuggestions.isEmpty || _model.stateFocusNode?.hasFocus != true) {
      return;
    }

    final overlay = Overlay.of(context);
    final width = _getWidgetWidth(_stateKey);

    _stateOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _hideStateOverlay();
              },
            ),
          ),
          CompositedTransformFollower(
            link: _stateLayerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(12),
              color: FlutterFlowTheme.of(context).secondaryBackground,
              child: Container(
                width: width,
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: FlutterFlowTheme.of(context).alternate),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: _stateSuggestions
                      .map((state) => ListTile(
                            title: Text(state,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium),
                            onTap: () {
                              _model.stateTextController?.text = state;
                              _model.cityTextController?.clear();
                              _hideStateOverlay();
                              setState(() {
                                _citySuggestions = [];
                              });
                            },
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_stateOverlayEntry!);
  }

  void _hideStateOverlay() {
    _stateOverlayEntry?.remove();
    _stateOverlayEntry = null;
  }

  void _updateCityOverlay() {
    _hideCityOverlay();
    final state = _model.stateTextController?.text ?? '';
    final query = _model.cityTextController?.text ?? '';
    if (query.isEmpty || _citySuggestions.isEmpty || _model.cityFocusNode?.hasFocus != true) {
      return;
    }

    final overlay = Overlay.of(context);
    final width = _getWidgetWidth(_cityKey);

    _cityOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _hideCityOverlay();
              },
            ),
          ),
          CompositedTransformFollower(
            link: _cityLayerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 4),
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(12),
              color: FlutterFlowTheme.of(context).secondaryBackground,
              child: Container(
                width: width,
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: FlutterFlowTheme.of(context).alternate),
                ),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: _citySuggestions
                      .map((city) => ListTile(
                            title: Text(city,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium),
                            onTap: () {
                              _model.cityTextController?.text = city;
                              _hideCityOverlay();
                            },
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_cityOverlayEntry!);
  }

  void _hideCityOverlay() {
    _cityOverlayEntry?.remove();
    _cityOverlayEntry = null;
  }

  @override
  void dispose() {
    _hideStateOverlay();
    _hideCityOverlay();
    _model.stateFocusNode?.removeListener(_onStateFocusChange);
    _model.cityFocusNode?.removeListener(_onCityFocusChange);
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Cambiado de max a min
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                child: TextFormField(
                  controller: _model.addressTextController,
                  focusNode: _model.addressFocusNode,
                  autofocus: true,
                  obscureText: false,
                  decoration: InputDecoration(
                    labelText: 'Dirección',
                    labelStyle: FlutterFlowTheme.of(context).labelLarge.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelLarge
                                .fontWeight,
                            fontStyle:
                                FlutterFlowTheme.of(context).labelLarge.fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              FlutterFlowTheme.of(context).labelLarge.fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelLarge.fontStyle,
                        ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 2.0,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4.0),
                        topRight: Radius.circular(4.0),
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).primary,
                        width: 2.0,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4.0),
                        topRight: Radius.circular(4.0),
                      ),
                    ),
                    errorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).error,
                        width: 2.0,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4.0),
                        topRight: Radius.circular(4.0),
                      ),
                    ),
                    focusedErrorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).error,
                        width: 2.0,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4.0),
                        topRight: Radius.circular(4.0),
                      ),
                    ),
                  ),
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                        font: GoogleFonts.inter(
                          fontWeight:
                              FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                      ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'La dirección es requerida';
                    }
                    return _model.addressTextControllerValidator
                        ?.call(context, value);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                child: TextFormField(
                  controller: _model.clonableURLTextController,
                  focusNode: _model.clonableURLFocusNode,
                  autofocus: true,
                  obscureText: false,
                  decoration: InputDecoration(
                    labelText: 'Dirección postal 2 (opcional)',
                    labelStyle: FlutterFlowTheme.of(context).labelLarge.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelLarge
                                .fontWeight,
                            fontStyle:
                                FlutterFlowTheme.of(context).labelLarge.fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              FlutterFlowTheme.of(context).labelLarge.fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelLarge.fontStyle,
                        ),
                    hintStyle: FlutterFlowTheme.of(context).labelLarge.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelLarge
                                .fontWeight,
                            fontStyle:
                                FlutterFlowTheme.of(context).labelLarge.fontStyle,
                          ),
                          letterSpacing: 0.0,
                          fontWeight:
                              FlutterFlowTheme.of(context).labelLarge.fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).labelLarge.fontStyle,
                        ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 2.0,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4.0),
                        topRight: Radius.circular(4.0),
                      ),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).primary,
                        width: 2.0,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4.0),
                        topRight: Radius.circular(4.0),
                      ),
                    ),
                    errorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).error,
                        width: 2.0,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4.0),
                        topRight: Radius.circular(4.0),
                      ),
                    ),
                    focusedErrorBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).error,
                        width: 2.0,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4.0),
                        topRight: Radius.circular(4.0),
                      ),
                    ),
                  ),
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                        font: GoogleFonts.inter(
                          fontWeight:
                              FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                        ),
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                      ),
                  validator: _model.clonableURLTextControllerValidator
                      .asValidator(context),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                child: CompositedTransformTarget(
                  link: _stateLayerLink,
                  child: TextFormField(
                    key: _stateKey,
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
                      return _model.stateTextControllerValidator
                          ?.call(context, value);
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
                child: CompositedTransformTarget(
                  link: _cityLayerLink,
                  child: TextFormField(
                    key: _cityKey,
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
                      return _model.cityTextControllerValidator
                          ?.call(context, value);
                    },
                  ),
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
      ),
    );
  }
}
