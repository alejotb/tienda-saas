import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/services/cart_service.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'components/checkout_breadcrumbs.dart';
import 'components/checkout_address_section.dart';
import 'components/checkout_shipping_section.dart';
import 'components/checkout_payment_section.dart';
import 'components/checkout_order_summary.dart';
import 'components/checkout_info_header.dart';
import 'components/checkout_progress_bar.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_animations.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/custom_functions.dart' as functions;
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'checkout_full_page_model.dart';
import 'package:file_picker/file_picker.dart';
export 'checkout_full_page_model.dart';

class CheckoutFullPageWidget extends StatefulWidget {
  const CheckoutFullPageWidget({
    super.key,
    required this.subPage,
    String? subPageName,
    String? pedidoId,
    this.productIdsJson,
    this.totalPagado,
    this.bcvRate,
  })  : subPageName = subPageName ?? 'Product Details',
        pedidoId = pedidoId;

  final bool? subPage;
  final String subPageName;
  final String? pedidoId;
  final String? productIdsJson;
  final String? totalPagado;
  final String? bcvRate;

  static String routeName = 'checkout_FullPage';
  static String routePath = '/checkoutFullPage';

  @override
  State<CheckoutFullPageWidget> createState() => _CheckoutFullPageWidgetState();
}

class _CheckoutFullPageWidgetState extends State<CheckoutFullPageWidget>
    with TickerProviderStateMixin {
  late CheckoutFullPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CheckoutFullPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (widget.productIdsJson != null) {
        await _model.initializeProducts(widget.productIdsJson);
        safeSetState(() {});
      }

      _model.stepNumber = 1;
      _model.pedidoId = widget.pedidoId;
      if (widget.totalPagado != null) {
        _model.saldoApartados = double.tryParse(widget.totalPagado!);
      }
      debugPrint('DEBUG: bcvRate recibido en Checkout: ${widget.bcvRate}');
      if (widget.bcvRate != null) {
        _model.bcvRate = double.tryParse(widget.bcvRate!);
      }
      if (_model.pedidoId != null) {
        await _model.fetchPendingBalance();
      }
      safeSetState(() {});

      if (!loggedIn) {
        if (FFAppState().listaDirecciones.isNotEmpty) {
          _model.direccionesGuardadas =
              FFAppState().listaDirecciones.toList().cast<AddressStruct>();
          safeSetState(() {});
        } else {
          return;
        }
      } else {
        _model.usuarioRow = await UsuariosTable().queryRows(
          queryFn: (q) => q.eq(
            'id',
            currentUserUid,
          ),
        );
        if (_model.usuarioRow!.firstOrNull!.datosDireccion.isNotEmpty) {
          _model.direccionesGuardadas = functions
              .jsonToAddressList(
                  _model.usuarioRow!.firstOrNull!.datosDireccion.toList())
              .toList()
              .cast<AddressStruct>();
          safeSetState(() {});
        }

        final user = _model.usuarioRow!.firstOrNull;
        if (user != null) {
          if (_model.personNameController.text.isEmpty && user.nombre != null) {
            _model.personNameController.text = user.nombre!;
          }
          if (_model.personPhoneController.text.isEmpty &&
              user.telefono != null) {
            _model.personPhoneController.text = user.telefono!;
          }
          safeSetState(() {});
        }
      }
    });

    _model.expandableExpandableController1 =
        ExpandableController(initialExpanded: true)
          ..addListener(() => safeSetState(() {}));
    _model.expandableExpandableController2 =
        ExpandableController(initialExpanded: false)
          ..addListener(() => safeSetState(() {}));
    animationsMap.addAll({
      'rowOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          VisibilityEffect(duration: 1.ms),
          FadeEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: 0.0,
            end: 1.0,
          ),
          MoveEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 600.0.ms,
            begin: const Offset(0.0, -70.0),
            end: const Offset(0.0, 0.0),
          ),
        ],
      ),
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              wrapWithModel(
                model: _model.topNavModel,
                updateCallback: () => safeSetState(() {}),
                child: const TopNavWidget(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckoutBreadcrumbs(
                        subPage: widget.subPage,
                        subPageName: widget.subPageName,
                      ).animateOnPageLoad(
                          animationsMap['rowOnPageLoadAnimation']!),
                      Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            16.0, 16.0, 16.0, 44.0),
                        child: Wrap(
                          spacing: 16.0,
                          runSpacing: 16.0,
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          direction: Axis.horizontal,
                          runAlignment: WrapAlignment.start,
                          verticalDirection: VerticalDirection.down,
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              constraints: const BoxConstraints(
                                maxWidth: 670.0,
                              ),
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                boxShadow: const [
                                  BoxShadow(
                                    blurRadius: 4.0,
                                    color: Color(0x33000000),
                                    offset: Offset(
                                      0.0,
                                      2.0,
                                    ),
                                  )
                                ],
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CheckoutProgressBar(
                                      currentStep: _model.stepNumber,
                                    ),
                                    const CheckoutInfoHeader(),
                                    _buildStepContent(),
                                  ],
                                ),
                              ),
                            ),
                            CheckoutOrderSummary(
                              shippingOption: _model.shippingOption,
                              model: _model,
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
      ),
    );
  }

  Widget _buildStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        switch (_model.stepNumber) {
          1 => _buildStep1(),
          2 => _buildStep2(),
          3 => _buildStep3(),
          _ => Container(),
        },
        const SizedBox(height: 24),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      children: [
        CheckoutShippingSection(
          model: _model,
          onUpdate: () => safeSetState(() {}),
        ),
        if (_model.deliveryType == 'Casa')
          CheckoutAddressSection(
            model: _model,
            onUpdate: () => safeSetState(() {}),
          ),
      ],
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckoutPaymentSection(
            model: _model,
            onUpdate: () => safeSetState(() {}),
            action: () async {
              _model.pago = _model.addPagoModel.currentPayment;
              debugPrint('DEBUG PAGO CREADO: ${_model.pago.toString()}');

              debugPrint('DEBUG VARIABLE GUARDADA: _model.pago');
              safeSetState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return _buildConfirmationStep();
  }

  Widget _buildNavigationButtons() {
    bool canGoBack = _model.stepNumber > 1;
    bool canGoNext = _model.stepNumber < 3;

    bool isCurrentStepValid = false;
    if (_model.stepNumber == 1) {
      isCurrentStepValid = _model.validateStep1();
    } else if (_model.stepNumber == 2) {
      isCurrentStepValid = _model.validateStep2();
    } else {
      isCurrentStepValid = true;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (canGoBack)
          TextButton(
            onPressed: () {
              setState(() {
                _model.stepNumber--;
                _model.highlightErrors = false;
              });
            },
            child: Text(
              'Atrás',
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Inter',
                    color: FlutterFlowTheme.of(context).primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          )
        else
          const SizedBox(width: 0),
        if (canGoNext)
          ElevatedButton(
            onPressed: () async {
              if (isCurrentStepValid) {
                // Si estamos pasando del paso 2 al 3, asegurar sincronización de datos de pago
                if (_model.stepNumber == 2) {
                  _model.pago = _model.addPagoModel.currentPayment;
                  debugPrint('DEBUG PAGO CREADO: ${_model.pago.toString()}');

                  debugPrint(
                      'DEBUG: Datos de pago sincronizados antes de avanzar: ${_model.pago.toString()}');
                  safeSetState(() {});
                }
                // Si estamos pasando del paso 1 al 2, persistir direcciones
                if (_model.stepNumber == 1 && loggedIn) {
                  await UsuariosTable().update(
                    data: {
                      'datos_direccion': functions
                          .addressesToJSONList(_model.direccionesGuardadas),
                    },
                    matchingRows: (rows) => rows.eq('id', currentUserUid),
                  );
                }

                setState(() {
                  _model.stepNumber++;
                  _model.highlightErrors = false;
                });
              } else {
                setState(() {
                  _model.highlightErrors = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _model.stepNumber == 1
                          ? 'Por favor, completa la dirección y el método de envío.'
                          : 'Por favor, completa los datos de pago o sube el comprobante.',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentStepValid
                  ? FlutterFlowTheme.of(context).primary
                  : FlutterFlowTheme.of(context).alternate,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Siguiente',
              style: FlutterFlowTheme.of(context).titleSmall.override(
                    fontFamily: 'Inter',
                    color: Colors.white,
                  ),
            ),
          )
        else
          const SizedBox(width: 0),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    debugPrint('DEBUG PASO 3: _model.pago es ${_model.pago?.toString()}');
    debugPrint(
        'DEBUG PASO 3: addPagoModel dropDown: ${_model.addPagoModel.dropDownValue}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmación',
          style: FlutterFlowTheme.of(context)
              .titleLarge
              .override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: FlutterFlowTheme.of(context).alternate),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Información de envío',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Inter', fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                (_model.deliveryType == 'Persona')
                    ? 'Entrega en Persona'
                    : (_model.deliveryType == 'Casa')
                        ? 'Dirección: ${_model.address?.address ?? 'No definida'}'
                        : 'Agencia: ${_model.selectedAgency?.isNotEmpty == true ? _model.selectedAgency : 'No seleccionada'}',
                style: FlutterFlowTheme.of(context).bodySmall,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text('Información de pago',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                      fontFamily: 'Inter', fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_model.pago != null) ...[
                Text('Método: ${_model.pago!.tipo}',
                    style: FlutterFlowTheme.of(context).bodySmall),
                if (_model.pago!.bancoEnviado.isNotEmpty)
                  Text('Banco: ${_model.pago!.bancoEnviado}',
                      style: FlutterFlowTheme.of(context).bodySmall),
                if (_model.pago!.referencia.isNotEmpty)
                  Text('Referencia: ${_model.pago!.referencia}',
                      style: FlutterFlowTheme.of(context).bodySmall),
                if (_model.pago!.numeroTelefono.isNotEmpty)
                  Text('Teléfono: ${_model.pago!.numeroTelefono}',
                      style: FlutterFlowTheme.of(context).bodySmall),
                Text('¿Estás seguro de que deseas finalizar la compra?',
                    style: FlutterFlowTheme.of(context).bodySmall),
              ] else
                Text('No seleccionado',
                    style: FlutterFlowTheme.of(context).bodySmall),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: FlutterFlowTheme.of(context).bodySmall.override(
                  fontFamily: 'Inter',
                  color: FlutterFlowTheme.of(context).secondaryText)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: FlutterFlowTheme.of(context)
                  .bodyMedium
                  .override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
