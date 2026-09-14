import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/form_field_controller.dart';
import 'add_pago_widget.dart' show AddPagoWidget;
import 'package:flutter/material.dart';

class AddPagoModel extends FlutterFlowModel<AddPagoWidget> {
  ///  State fields for stateful widgets in this component.

  final formKey = GlobalKey<FormState>();
  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // State field(s) for nombre widget.
  FocusNode? nombreFocusNode;
  TextEditingController? nombreTextController;
  String? Function(BuildContext, String?)? nombreTextControllerValidator;
  // State field(s) for email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for telefono widget.
  FocusNode? telefonoFocusNode;
  TextEditingController? telefonoTextController;
  String? Function(BuildContext, String?)? telefonoTextControllerValidator;
  // State field(s) for banco widget.
  FocusNode? bancoFocusNode;
  String? bancoDropdownValue;
  FormFieldController<String>? bancoDropdownValueController;
  List<String> bancos = [];
  // TextEditingController? bancoTextController; // Removed
  String? Function(BuildContext, String?)? bancoTextControllerValidator;
  // State field(s) for referencia widget.
  FocusNode? referenciaFocusNode;
  TextEditingController? referenciaTextController;
  String? Function(BuildContext, String?)? referenciaTextControllerValidator;
  // State field(s) for fecha widget.
  FocusNode? fechaFocusNode;
  TextEditingController? fechaTextController;
  String? Function(BuildContext, String?)? fechaTextControllerValidator;
  // State field(s) for monto widget.
  FocusNode? montoFocusNode;
  TextEditingController? montoTextController;
  String? Function(BuildContext, String?)? montoTextControllerValidator;

  bool hasProof = false;
  String? proofUrl;
  double bcvRate = 1.0;
  double initialAmountUsd = 0.0;

  // Getter centralizado para obtener el estado actual del pago
  PagoStruct get currentPayment {
    final rawMonto = double.tryParse(montoTextController?.text ?? '0') ?? 0.0;
    final bool isPagoMovil = dropDownValue == 'Pago Movil';

    double montoUsd = rawMonto;
    double montoVes = 0.0;
    double tasa = bcvRate > 0 ? bcvRate : 1.0;

    if (isPagoMovil) {
      montoVes = rawMonto;
      montoUsd = tasa > 0 ? (montoVes / tasa) : initialAmountUsd;
    }

    final ref = referenciaTextController?.text.trim() ?? '';
    final validRef = (ref.isNotEmpty && ref != 'Desconocida' && ref != 'N/A' && !ref.startsWith('http'))
        ? ref
        : 'Comprobante adjunto';

    return PagoStruct(
      nombre: nombreTextController?.text ?? '',
      email: emailTextController?.text ?? '',
      tipo: dropDownValue,
      referencia: validRef,
      comprobanteUrl: proofUrl ?? '',
      numeroTelefono: (telefonoTextController?.text.isNotEmpty == true && telefonoTextController!.text != 'Desconocido' && telefonoTextController!.text != 'N/A')
          ? telefonoTextController!.text
          : '',
      bancoEnviado: (bancoDropdownValue != null && bancoDropdownValue != 'Desconocido' && bancoDropdownValue != 'N/A')
          ? bancoDropdownValue!
          : '',
      bancoRecibido: 'El Baúl de Pandora',
      montoVes: montoVes,
      tasaAplicada: isPagoMovil ? tasa : 0.0,
      montoUsd: montoUsd,
    );
  }

  // Validación centralizada
  bool get isValid {
    debugPrint('DEBUG AddPagoModel.isValid: dropDownValue="$dropDownValue", hasProof=$hasProof');
    
    if (dropDownValue == null || dropDownValue!.isEmpty) {
      debugPrint('DEBUG AddPagoModel.isValid: false (dropDownValue nulo o vacío)');
      return false;
    }

    // Si subió un comprobante, es válido inmediatamente sin exigir formulario manual
    if (hasProof) {
      debugPrint('DEBUG AddPagoModel.isValid: true (comprobante adjunto)');
      return true;
    }
    
    // Efectivo es válido por defecto
    if (dropDownValue == 'Efectivo') {
       debugPrint('DEBUG AddPagoModel.isValid: Validando Efectivo');
       return true;
    }
    
    if (dropDownValue == 'Pago Movil') {
      debugPrint('DEBUG AddPagoModel.isValid: Validando Pago Movil');
      if (bancoDropdownValue == null || bancoDropdownValue!.isEmpty || bancoDropdownValue == 'Desconocido') {
        debugPrint('DEBUG AddPagoModel.isValid: false (banco nulo, vacío o desconocido)');
        return false;
      }
      final ref = referenciaTextController?.text.trim() ?? '';
      if (ref.isEmpty || ref == 'Desconocida') {
        debugPrint('DEBUG AddPagoModel.isValid: false (referencia vacía o desconocida)');
        return false;
      }
      final tel = telefonoTextController?.text.trim() ?? '';
      if (tel.isEmpty || tel == 'Desconocido') {
        debugPrint('DEBUG AddPagoModel.isValid: false (telefono vacío o desconocido)');
        return false;
      }
    }
    
    final monto = double.tryParse(montoTextController?.text ?? '0') ?? 0;
    final validMonto = monto > 0;
    
    debugPrint('DEBUG AddPagoModel.isValid: monto="$monto", validMonto=$validMonto');
    
    return validMonto;
  }

  @override
  void initState(BuildContext context) {
    nombreTextControllerValidator = (context, val) {
      if (val == null || val.isEmpty) {
        return 'El nombre es requerido';
      }
      return null;
    };
    emailTextControllerValidator = (context, val) {
      if (val == null || val.isEmpty) {
        return 'El email es requerido';
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
        return 'Ingrese un email válido';
      }
      return null;
    };
    telefonoTextControllerValidator = (context, val) {
      if (val == null || val.isEmpty) {
        return 'El teléfono es requerido';
      }
      return null;
    };
    bancoTextControllerValidator = (context, val) {
      if (dropDownValue == 'Pago Movil' && (bancoDropdownValue == null || bancoDropdownValue!.isEmpty)) {
        return 'El banco es requerido para Pago Móvil';
      }
      return null;
    };
    referenciaTextControllerValidator = (context, val) {
      if (dropDownValue == 'Pago Movil' && (val == null || val.isEmpty)) {
        return 'La referencia es requerida para Pago Móvil';
      }
      return null;
    };
    fechaTextControllerValidator = (context, val) {
      if (dropDownValue == 'Pago Movil' && (val == null || val.isEmpty)) {
        return 'La fecha es requerida para Pago Móvil';
      }
      return null;
    };
    montoTextControllerValidator = (context, val) {
      if (val == null || val.isEmpty) {
        return 'El monto es requerido';
      }
      if (double.tryParse(val) == null || double.parse(val) <= 0) {
        return 'Ingrese un monto válido';
      }
      return null;
    };
  }


  @override
  void dispose() {
    nombreFocusNode?.dispose();
    nombreTextController?.dispose();

    emailFocusNode?.dispose();
    emailTextController?.dispose();

    telefonoFocusNode?.dispose();
    telefonoTextController?.dispose();

    bancoFocusNode?.dispose();
    
    referenciaFocusNode?.dispose();
    referenciaTextController?.dispose();
    
    fechaFocusNode?.dispose();
    fechaTextController?.dispose();

    montoFocusNode?.dispose();
    montoTextController?.dispose();
  }
}
