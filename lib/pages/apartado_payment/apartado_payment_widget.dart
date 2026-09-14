import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:baul_pandora/components/add_pago/add_pago_widget.dart';
import 'package:flutter/scheduler.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/pages/checkout_full_page/components/checkout_breadcrumbs.dart';
import 'package:baul_pandora/services/cart_service.dart';
import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/services/ai/gemini_vision_service.dart';
import 'apartado_payment_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:baul_pandora/components/payment_instructions/payment_instructions_component.dart';
import 'components/apartado_order_summary.dart';

class ApartadoPaymentPage extends StatefulWidget {
  const ApartadoPaymentPage({
    super.key,
    this.productIds,
    this.productIdsJson,
    this.productDetailsJson,
  });

  final List<String>? productIds;
  final String? productIdsJson;
  final String? productDetailsJson;

  static String routeName = 'apartadoPaymentPage';
  static String routePath = '/apartadoPaymentPage';

  @override
  State<ApartadoPaymentPage> createState() => _ApartadoPaymentPageState();
}

class _ApartadoPaymentPageState extends State<ApartadoPaymentPage> {
  late ApartadoPaymentModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String? _uploadedImageUrl;
  bool _isUploading = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ApartadoPaymentModel());

    if (widget.productIds != null) {
      _model.productIds = widget.productIds!;
    } else if (widget.productIdsJson != null) {
      try {
        _model.productIds =
            List<String>.from(jsonDecode(widget.productIdsJson!));
      } catch (e) {
        debugPrint('Error decoding productIdsJson: $e');
      }
    } else if (widget.productDetailsJson != null) {
      debugPrint(
          'DEBUG: Recibiendo productDetailsJson: ${widget.productDetailsJson}');
      try {
        final List<dynamic> details = jsonDecode(widget.productDetailsJson!);
        _model.productsDetails =
            details.map((e) => e as Map<String, dynamic>).toList();
        debugPrint(
            'DEBUG: Productos decodificados: ${_model.productsDetails.length}');
        // Construir productIds para mantener compatibilidad con el resto de la lógica si es necesario
        _model.productIds =
            _model.productsDetails.map((e) => e['id'].toString()).toList();
      } catch (e) {
        debugPrint('Error decoding productDetailsJson: $e');
      }
    }

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      await _model.calculateAmounts();
      safeSetState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            wrapWithModel(
              model: _model.topNavModel,
              updateCallback: () => safeSetState(() {}),
              child: TopNavWidget(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: CheckoutBreadcrumbs(
                                subPage: false, subPageName: 'Pago Apartado'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Apartados',
                            style: FlutterFlowTheme.of(context)
                                .headlineLarge
                                .override(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16.0,
                        runSpacing: 16.0,
                        alignment: WrapAlignment.center,
                        children: [
                          Container(
                            constraints: const BoxConstraints(maxWidth: 550.0),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      children: [
                                        wrapWithModel(
                                          model: _model.addPagoModel,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: AddPagoWidget(
                                            initialAmountUsd:
                                                _model.pendingBalance,
                                            bcvRate: _model.bcvRate,
                                            action: () async {
                                              _model
                                                  .updatePagoFromControllers();
                                              safeSetState(() {});
                                            },
                                            onUpdate: () => safeSetState(() {}),
                                            onProofUploaded: (url, aiData) {
                                              setState(() =>
                                                  _uploadedImageUrl = url);

                                              if (aiData != null) {
                                                // --- Validación del tipo de pago ---
                                                final String aiTipoPago =
                                                    aiData['tipo_pago']
                                                            ?.toString()
                                                            .toLowerCase() ??
                                                        '';
                                                final String userTipoPago =
                                                    _model.addPagoModel
                                                            .dropDownValue
                                                            ?.toLowerCase() ??
                                                        '';

                                                bool esValidoTipo = true;
                                                if (aiTipoPago ==
                                                        'pago movil' &&
                                                    userTipoPago !=
                                                        'pago movil')
                                                  esValidoTipo = false;
                                                else if (aiTipoPago ==
                                                        'binance' &&
                                                    userTipoPago != 'binance')
                                                  esValidoTipo = false;
                                                else if (aiTipoPago ==
                                                        'paypal' &&
                                                    userTipoPago != 'paypal')
                                                  esValidoTipo = false;

                                                if (!esValidoTipo) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'El comprobante subido no corresponde al tipo de pago seleccionado'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                  setState(() => _uploadedImageUrl =
                                                      null); // Invalida la subida
                                                  return;
                                                }
                                                // --- Fin Validación ---

                                                if (aiData['valido'] == true) {
                                                  // Autocompletar campos basados en aiData
                                                  _model
                                                      .addPagoModel
                                                      .referenciaTextController
                                                      ?.text = aiData[
                                                          'referencia'] ??
                                                      '';
                                                  _model
                                                          .addPagoModel
                                                          .nombreTextController
                                                          ?.text =
                                                      aiData['nombre'] ?? '';

                                                  // Manejo de moneda
                                                  if (aiData['moneda'] ==
                                                      'VES') {
                                                    _model.addPagoModel
                                                            .dropDownValue =
                                                        'Pago Movil';
                                                  }

                                                  // El monto devuelto por la IA debe ser parseado y puesto en el controlador
                                                  if (aiData['monto'] != null) {
                                                    _model
                                                            .addPagoModel
                                                            .montoTextController
                                                            ?.text =
                                                        aiData['monto']
                                                            .toString();
                                                  }

                                                  // Intentar setear el banco
                                                  if (aiData['banco'] != null) {
                                                    _model.addPagoModel
                                                            .bancoDropdownValue =
                                                        aiData['banco'];
                                                  }

                                                  // Sincronizar el modelo después de los cambios
                                                  _model
                                                      .updatePagoFromControllers();
                                                  safeSetState(() {});
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(maxWidth: 550.0),
                            child: ApartadoOrderSummary(
                              model: _model,
                              onConfirm: _processApartado,
                              onPagarMasTarde: _processApartadoPagoMasTarde,
                              isProcessing: _isProcessing,
                              comprobanteValidado: _uploadedImageUrl != null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processApartadoPagoMasTarde() async {
    setState(() => _isProcessing = true);
    try {
      final result = await CartService.instance.apartarProductos(
        itemsToProcess: _model.productsDetails,
        esPagoInmediato: false,
      );
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Tienes un día para completar el pago y asegurar tu apartado'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processApartado() async {
    setState(() => _isProcessing = true);

    debugPrint('DEBUG: Iniciando _processApartado...');
    debugPrint('DEBUG: _uploadedImageUrl: $_uploadedImageUrl');

    try {
      // 1. Validar Método de Pago
      final String dropDownValue = _model.addPagoModel.dropDownValue ?? '';
      if (dropDownValue == 'Efectivo') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago en efectivo no disponible para apartar.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // 2. Validar Monto Mínimo ($2 por cada producto individual (cantidad))
      int totalCantidad = 0;
      for (var item in _model.productsDetails) {
        totalCantidad += (item['cantidad'] as num).toInt();
      }
      if (totalCantidad == 0) {
        totalCantidad = _model.productIds.length;
      }
      if (totalCantidad == 0) {
        totalCantidad = 1; // Fallback mínimo por seguridad
      }
      final double montoMinimoUsd = totalCantidad * 2.0;

      final bool isPagoMovil =
          dropDownValue.toLowerCase().contains('movil') == true ||
              dropDownValue.toLowerCase().contains('móvil') == true;

      final double montoIngresado =
          (double.tryParse(_model.addPagoModel.montoTextController.text) ??
              0.0);
      final double bcvRate = _model.bcvRate > 0 ? _model.bcvRate : 1.0;

      if (isPagoMovil) {
        // Convertimos el mínimo a VES para comparar
        final double montoMinimoVes = montoMinimoUsd * bcvRate;
        if (montoIngresado < montoMinimoVes) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'El monto mínimo para apartar es ${formatNumber(montoMinimoVes, formatType: FormatType.decimal, decimalType: DecimalType.automatic)} VES'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isProcessing = false);
          return;
        }
      } else {
        // Comparamos directamente en USD
        if (montoIngresado < montoMinimoUsd) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'El monto mínimo para apartar es ${formatNumber(montoMinimoUsd, formatType: FormatType.decimal, decimalType: DecimalType.automatic)} USD'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isProcessing = false);
          return;
        }
      }
      // --- FIN VALIDACIONES ---

      // 3. Construir PagoStruct de forma explícita a partir de los campos del formulario
      // (Autocompletados por IA en UploadProofComponent, o llenados/corregidos manualmente)
      final double montoUsd =
          isPagoMovil ? (montoIngresado / bcvRate) : montoIngresado;
      final double montoVes = isPagoMovil ? montoIngresado : 0.0;
      final double tasaAplicada = isPagoMovil ? bcvRate : 0.0;

      final user = currentUser;
      final String nombreUsuario =
          _model.addPagoModel.nombreTextController.text.trim().isNotEmpty
              ? _model.addPagoModel.nombreTextController.text.trim()
              : (user?.displayName ?? 'Anónimo');

      final String emailUsuario =
          _model.addPagoModel.emailTextController.text.trim().isNotEmpty
              ? _model.addPagoModel.emailTextController.text.trim()
              : (user?.email ?? 'N/A');

      PagoStruct pagoFinal = PagoStruct(
        nombre: nombreUsuario,
        email: emailUsuario,
        tipo: dropDownValue,
        referencia: _model.addPagoModel.referenciaTextController.text.trim(),
        numeroTelefono: _model.addPagoModel.telefonoTextController.text.trim(),
        bancoEnviado: _model.addPagoModel.bancoDropdownValue ?? '',
        bancoRecibido: '',
        montoVes: montoVes,
        tasaAplicada: tasaAplicada,
        montoUsd: montoUsd,
      );

      // 4. Si no hay datos de pago válidos, abortamos
      if (!_model.isValidPayment) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Por favor, completa los datos de pago o sube un comprobante válido.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // 3. Crear el apartado con los datos procesados
      final result = await CartService.instance.apartarProductos(
        itemsToProcess: _model.productsDetails,
        datosPago: pagoFinal,
        comprobanteUrl: _uploadedImageUrl,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        // Navegar al Home limpiando el historial para bloquear el back
        context.goNamed('mainHomePage');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error procesando apartado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }
}
