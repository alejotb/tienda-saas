import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:baul_pandora/flutter_flow/custom_code/actions/calculator_currency_formatter.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_drop_down.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_widgets.dart';
import 'package:baul_pandora/flutter_flow/form_field_controller.dart';
import 'package:baul_pandora/components/payment_instructions/payment_instructions_component.dart';
import 'package:baul_pandora/components/payment_instructions/upload_proof_component.dart';
import 'add_pago_model.dart';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';


export 'add_pago_model.dart';

class AddPagoWidget extends StatefulWidget {
  const AddPagoWidget({
    super.key,
    required this.action,
    required this.onUpdate,
    this.onProofUploaded,
    required this.initialAmountUsd,
    required this.bcvRate,
    this.model,
  });

  final Future Function()? action;
  final VoidCallback onUpdate;
  final Function(String?, Map<String, dynamic>?)? onProofUploaded;
  final double initialAmountUsd;
  final double bcvRate;
  final AddPagoModel? model;

  @override
  State<AddPagoWidget> createState() => _AddPagoWidgetState();
}

class _AddPagoWidgetState extends State<AddPagoWidget> {
  late AddPagoModel _model;
  bool _comprobanteValidado = false;

  void _updateMontoField(String? value) {
    if (value == 'Pago Movil') {
      final tasa = widget.bcvRate > 0 ? widget.bcvRate : 1.0;
      _model.montoTextController?.text = (widget.initialAmountUsd * tasa).toStringAsFixed(2);
    } else {
      _model.montoTextController?.text = widget.initialAmountUsd.toStringAsFixed(2);
    }
  }

  @override
  void didUpdateWidget(AddPagoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _model.bcvRate = widget.bcvRate;
    _model.initialAmountUsd = widget.initialAmountUsd;
    final currentMonto = double.tryParse(_model.montoTextController?.text ?? '0') ?? 0.0;
    if (currentMonto <= 0.0 && widget.initialAmountUsd > 0.0) {
      _updateMontoField(_model.dropDownValue);
    }
  }

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = widget.model ?? createModel(context, () => AddPagoModel());
    _model.bcvRate = widget.bcvRate;
    _model.initialAmountUsd = widget.initialAmountUsd;
    _loadBanks();
    _model.nombreTextController ??= TextEditingController(text: currentUserDisplayName);
    _model.nombreFocusNode ??= FocusNode();
    _model.emailTextController ??= TextEditingController(text: currentUserEmail);
    _model.emailFocusNode ??= FocusNode();
    _model.telefonoTextController ??= TextEditingController();
    _model.telefonoFocusNode ??= FocusNode();
    _model.referenciaTextController ??= TextEditingController();
    _model.referenciaFocusNode ??= FocusNode();
    _model.fechaTextController ??= TextEditingController();
    _model.fechaFocusNode ??= FocusNode();
    _model.montoTextController ??= TextEditingController();
    _model.montoFocusNode ??= FocusNode();
    
    // Inicializar monto por defecto
    if (_model.montoTextController!.text.isEmpty || _model.montoTextController!.text == '0.00' || _model.montoTextController!.text == '0') {
      _updateMontoField(_model.dropDownValue);
    }

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final userRow = await UsuariosTable().queryRows(
          queryFn: (q) => q.eq('id', currentUserUid),
        );
        if (userRow.isNotEmpty) {
          final user = userRow.first;
          if (_model.nombreTextController!.text.isEmpty && user.nombre != null) {
            _model.nombreTextController!.text = user.nombre!;
          }
          if (_model.telefonoTextController!.text.isEmpty && user.telefono != null) {
            _model.telefonoTextController!.text = user.telefono!;
          }
          safeSetState(() {});
        }
      }
    });
  }

  Future<void> _loadBanks() async {
    final String response = await rootBundle.loadString('assets/jsons/banks.json');
    final data = jsonDecode(response);
    setState(() {
      _model.bancos = (data['banks'] as List).map((bank) => bank['name'] as String).toList();
    });
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 10.0, 0.0, 0.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Wrap(
              spacing: 20.0,
              runSpacing: 10.0,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Selecciona el tipo de pago',
                  style: FlutterFlowTheme.of(context).bodyLarge,
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  child: FlutterFlowDropDown<String>(
                    controller: _model.dropDownValueController ??=
                        FormFieldController<String>(null),
                    options: const ['Efectivo', 'Pago Movil', 'Binance', 'Pay Pal'],
                    onChanged: (val) {
                      safeSetState(() => _model.dropDownValue = val);
                      _updateMontoField(val);
                      widget.onUpdate();
                    },
                    width: 200.0,
                    height: 40.0,
                    textStyle: FlutterFlowTheme.of(context).bodyMedium,
                    hintText: 'Select...',
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: FlutterFlowTheme.of(context).secondaryText,
                      size: 24.0,
                    ),
                    fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                    elevation: 2.0,
                    borderColor: Colors.transparent,
                    borderWidth: 0.0,
                    borderRadius: 8.0,
                    margin: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
                    hidesUnderline: true,
                    isOverButton: false,
                    isSearchable: false,
                    isMultiSelect: false,
                  ),
                ),
              ],
            ),
            if (_model.dropDownValue != null && _model.dropDownValue != 'Efectivo')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  children: [
                    PaymentInstructionsComponent(paymentType: _model.dropDownValue),
                  ],
                ),
              ),
            if (_model.dropDownValue != null && _model.dropDownValue != 'Efectivo')
              Form(
                key: _model.formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    const SizedBox(height: 16),
                    UploadProofComponent(
                      fallbackAmount: _model.dropDownValue == 'Pago Movil'
                          ? widget.initialAmountUsd * (widget.bcvRate > 0 ? widget.bcvRate : 1.0)
                          : widget.initialAmountUsd,
                      onProofUploaded: (url, aiData) {
                        if (url == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error al subir la imagen, intente de nuevo'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          setState(() => _comprobanteValidado = false);
                          return;
                        }
                        
                        // Guardamos la URL
                        if (aiData != null) {
                            final refVal = aiData['referencia']?.toString().trim() ?? '';
                            if (refVal.isNotEmpty && refVal != 'Desconocida' && refVal != 'N/A' && !refVal.startsWith('http')) {
                              _model.referenciaTextController?.text = refVal;
                            }
                            if (aiData['banco'] != null && _model.bancos.contains(aiData['banco'])) {
                              _model.bancoDropdownValue = aiData['banco'].toString();
                              _model.bancoDropdownValueController?.value = aiData['banco'].toString();
                            }
                            final telVal = aiData['telefono']?.toString().trim() ?? '';
                            if (telVal.isNotEmpty && telVal != 'Desconocido' && telVal != 'N/A') {
                              _model.telefonoTextController?.text = telVal;
                            }
                            if (aiData['monto'] != null && aiData['ai_verified'] != false) {
                               double rawMonto = (aiData['monto'] as num).toDouble();
                               bool isUserVes = _model.dropDownValue?.toLowerCase().contains('movil') == true || 
                                                _model.dropDownValue?.toLowerCase().contains('móvil') == true ||
                                                _model.dropDownValue?.toLowerCase().contains('transferencia') == true;
                               String aiMoneda = aiData['moneda']?.toString().toUpperCase() ?? 'USD';
                               double finalMonto = rawMonto;
                               double bcv = widget.bcvRate > 0 ? widget.bcvRate : 1.0;
                               
                               if (aiMoneda == 'USD' && isUserVes) {
                                 finalMonto = rawMonto * bcv;
                                } else if (aiMoneda == 'VES' && !isUserVes) {
                                 finalMonto = rawMonto / bcv;
                                }
                               _model.montoTextController?.text = finalMonto.toStringAsFixed(2);
                            } else {
                               _updateMontoField(_model.dropDownValue);
                            }
                        } else {
                          _updateMontoField(_model.dropDownValue);
                        }
                        
                        setState(() {
                          _comprobanteValidado = true;
                          _model.hasProof = true;
                          _model.proofUrl = url;
                        });
                        widget.onProofUploaded?.call(url, aiData);
                        widget.onUpdate();
                      },
                    ),
                    if (_comprobanteValidado) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified, color: Colors.green, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Comprobante listo para procesar',
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                      fontFamily: 'Inter',
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _comprobanteValidado = false;
                                _model.hasProof = false;
                                _model.proofUrl = null;
                              });
                              widget.onUpdate();
                            },
                            icon: const Icon(Icons.edit_note, size: 18),
                            label: const Text('Llenar manualmente'),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      Text(
                        'Datos del pago (manual):',
                        style: FlutterFlowTheme.of(context).titleMedium.override(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // --- 1. PAGO MOVIL ---
                      if (_model.dropDownValue == 'Pago Movil') ...[
                          FlutterFlowDropDown<String>(
                            controller: _model.bancoDropdownValueController ??= FormFieldController<String>(null),
                            options: _model.bancos,
                            onChanged: (val) => safeSetState(() => _model.bancoDropdownValue = val),
                            width: double.infinity,
                            height: 50.0,
                            textStyle: FlutterFlowTheme.of(context).bodyMedium,
                            hintText: 'Seleccione el banco emisor',
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: FlutterFlowTheme.of(context).secondaryText, size: 24.0),
                            fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                            elevation: 2.0,
                            borderColor: FlutterFlowTheme.of(context).alternate,
                            borderWidth: 2.0,
                            borderRadius: 8.0,
                            margin: const EdgeInsetsDirectional.fromSTEB(12.0, 4.0, 12.0, 4.0),
                            hidesUnderline: true,
                            isSearchable: true,
                          ),
                          if (!_comprobanteValidado && _model.bancoDropdownValue == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Debe seleccionar un banco',
                                style: FlutterFlowTheme.of(context).bodySmall.override(
                                  fontFamily: 'Inter',
                                  color: FlutterFlowTheme.of(context).error,
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _model.telefonoTextController,
                            focusNode: _model.telefonoFocusNode,
                            decoration: const InputDecoration(labelText: 'Teléfono emisor (Pago Móvil)', hintText: '04141234567'),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                            validator: _model.telefonoTextControllerValidator.asValidator(context),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _model.referenciaTextController,
                            focusNode: _model.referenciaFocusNode,
                            decoration: const InputDecoration(labelText: 'Número de Referencia (últimos dígitos)'),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                            validator: _model.referenciaTextControllerValidator.asValidator(context),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _model.fechaTextController,
                            focusNode: _model.fechaFocusNode,
                            readOnly: true,
                            onTap: () async {
                              final datePickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                              );
                              if (datePickedDate != null) {
                                safeSetState(() {
                                  _model.fechaTextController?.text =
                                      "${datePickedDate.day.toString().padLeft(2, '0')}/${datePickedDate.month.toString().padLeft(2, '0')}/${datePickedDate.year}";
                                });
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Fecha del pago',
                              suffixIcon: Icon(Icons.calendar_month),
                            ),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _model.montoTextController,
                            focusNode: _model.montoFocusNode,
                            inputFormatters: [CalculatorCurrencyFormatter()],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Monto pagado en Bs. (VES)'),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                            validator: _model.montoTextControllerValidator.asValidator(context),
                          ),
                        ],

                        // --- 2. BINANCE PAY ---
                        if (_model.dropDownValue == 'Binance') ...[
                          TextFormField(
                            controller: _model.nombreTextController,
                            focusNode: _model.nombreFocusNode,
                            decoration: const InputDecoration(labelText: 'Nombre / Nickname en Binance'),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _model.emailTextController,
                            focusNode: _model.emailFocusNode,
                            decoration: const InputDecoration(labelText: 'Binance Pay ID o Correo de Binance'),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                            validator: _model.emailTextControllerValidator.asValidator(context),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _model.referenciaTextController,
                            focusNode: _model.referenciaFocusNode,
                            decoration: const InputDecoration(labelText: 'Order ID / TxID de Binance'),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _model.montoTextController,
                            focusNode: _model.montoFocusNode,
                            inputFormatters: [CalculatorCurrencyFormatter()],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Monto pagado (USDT)'),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                            validator: _model.montoTextControllerValidator.asValidator(context),
                          ),
                        ],

                        // --- 3. PAYPAL ---
                        if (_model.dropDownValue == 'Pay Pal') ...[
                          TextFormField(
                            controller: _model.nombreTextController,
                            focusNode: _model.nombreFocusNode,
                            decoration: const InputDecoration(labelText: 'Nombre del titular de la cuenta PayPal'),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _model.emailTextController,
                            focusNode: _model.emailFocusNode,
                            decoration: const InputDecoration(labelText: 'Correo electrónico de PayPal'),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                            validator: _model.emailTextControllerValidator.asValidator(context),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _model.referenciaTextController,
                            focusNode: _model.referenciaFocusNode,
                            decoration: const InputDecoration(labelText: 'ID de Transacción de PayPal'),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _model.montoTextController,
                            focusNode: _model.montoFocusNode,
                            inputFormatters: [CalculatorCurrencyFormatter()],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Monto enviado (USD)'),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                            validator: _model.montoTextControllerValidator.asValidator(context),
                          ),
                        ],

                        // --- 4. OTROS / GENERAL ---
                        if (_model.dropDownValue != null &&
                            _model.dropDownValue != 'Pago Movil' &&
                            _model.dropDownValue != 'Binance' &&
                            _model.dropDownValue != 'Pay Pal' &&
                            _model.dropDownValue != 'Efectivo') ...[
                          TextFormField(
                            controller: _model.nombreTextController,
                            focusNode: _model.nombreFocusNode,
                            decoration: const InputDecoration(labelText: 'Nombre del titular'),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _model.emailTextController,
                            focusNode: _model.emailFocusNode,
                            decoration: const InputDecoration(labelText: 'Correo electrónico'),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _model.telefonoTextController,
                            focusNode: _model.telefonoFocusNode,
                            decoration: const InputDecoration(labelText: 'Teléfono de contacto'),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _model.referenciaTextController,
                            focusNode: _model.referenciaFocusNode,
                            decoration: const InputDecoration(labelText: 'Número de Referencia'),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _model.montoTextController,
                            focusNode: _model.montoFocusNode,
                            inputFormatters: [CalculatorCurrencyFormatter()],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Monto'),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                            validator: _model.montoTextControllerValidator.asValidator(context),
                          ),
                        ],
                    ],
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(0.0, 24.0, 0.0, 0.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FFButtonWidget(
                              onPressed: () async {
                                if (!_comprobanteValidado) {
                                  if (_model.formKey.currentState != null && !_model.formKey.currentState!.validate()) {
                                    return;
                                  }
                                }

                                if (!_model.isValid) {
                                  String msg = 'Por favor, complete todos los campos obligatorios.';
                                  if (_model.dropDownValue == 'Pago Movil') {
                                    if (_model.bancoDropdownValue == null || _model.bancoDropdownValue!.isEmpty || _model.bancoDropdownValue == 'Desconocido') {
                                      msg = 'Por favor seleccione el banco emisor.';
                                    } else if (_model.telefonoTextController?.text.trim().isEmpty ?? true) {
                                      msg = 'Por favor ingrese el número de teléfono emisor.';
                                    } else if (_model.referenciaTextController?.text.trim().isEmpty ?? true) {
                                      msg = 'Por favor ingrese el número de referencia.';
                                    }
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(msg),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                debugPrint('DEBUG ADD PAGO: Monto a guardar: ${_model.montoTextController?.text}');
                                await widget.action?.call();
                                if (!mounted) return;
                                widget.onUpdate.call(); // Forzar actualización del padre
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text('Pago guardado exitosamente'),
                                        ],
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              text: 'Guardar pago',
                              options: FFButtonOptions(
                                height: 44.0,
                                padding: const EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                                color: FlutterFlowTheme.of(context).primary,
                                textStyle: FlutterFlowTheme.of(context).titleSmall,
                                borderRadius: BorderRadius.circular(50.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
