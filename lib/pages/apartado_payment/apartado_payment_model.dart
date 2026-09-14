import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/components/add_pago/add_pago_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/services/exchange_rate_service.dart';
import 'apartado_payment_widget.dart' show ApartadoPaymentPage;

class ApartadoPaymentModel extends FlutterFlowModel<ApartadoPaymentPage> {
  /// Local state fields for this page.
  
  List<String> productIds = [];
  List<Map<String, dynamic>> productsDetails = [];
  double totalAmount = 0.0;
  double feeToPay = 0.0;
  double pendingBalance = 0.0;
  double bcvRate = 0.0;

  // Para gestión de pago
  PagoStruct? pago;
  String? comprobanteUrl;

  // Models
  late AddPagoModel addPagoModel;
  late TopNavModel topNavModel;

  void updatePagoFromControllers() {
    double montoIngresado = double.tryParse(addPagoModel.montoTextController.text) ?? 0.0;
    
    // Fuerza VES para Pago Movil, de lo contrario trata como USD
    bool esVes = addPagoModel.dropDownValue == 'Pago Movil';

    // Obtener datos del usuario actual
    final user = currentUser;
    final String nombreUsuario = addPagoModel.nombreTextController.text.trim().isNotEmpty
        ? addPagoModel.nombreTextController.text.trim()
        : (user?.displayName ?? 'Anónimo');
    
    final String emailUsuario = addPagoModel.emailTextController.text.trim().isNotEmpty
        ? addPagoModel.emailTextController.text.trim()
        : (user?.email ?? 'N/A');

    pago = PagoStruct(
      nombre: nombreUsuario,
      email: emailUsuario,
      tipo: addPagoModel.dropDownValue,
      referencia: addPagoModel.referenciaTextController.text.trim(),
      numeroTelefono: addPagoModel.telefonoTextController.text.trim(),
      bancoEnviado: addPagoModel.bancoDropdownValue ?? '',
      bancoRecibido: '',
      // Si es VES, guardamos montoVes, tasa y calculamos Usd. Si no, montoUsd es el monto ingresado.
      montoVes: esVes ? montoIngresado : 0.0,
      tasaAplicada: esVes ? bcvRate : 0.0,
      montoUsd: esVes ? (montoIngresado / (bcvRate > 0 ? bcvRate : 1.0)) : montoIngresado,
    );
  }

  bool get isValidPayment {
    final type = addPagoModel.dropDownValue;
    if (type == null) return false;

    if (type == 'Efectivo') {
      return true; // In apartados we might allow cash as a placeholder
    }

    if (type == 'Pago Movil') {
      return (addPagoModel.bancoDropdownValue?.isNotEmpty ?? false) &&
             addPagoModel.referenciaTextController.text.trim().isNotEmpty;
    }

    if (type == 'Binance' || type == 'Pay Pal') {
      return addPagoModel.emailTextController.text.trim().isNotEmpty &&
             addPagoModel.emailTextController.text.contains('@');
    }

    return false;
  }

  @override
  void initState(BuildContext context) {
    addPagoModel = createModel(context, () => AddPagoModel());
    topNavModel = createModel(context, () => TopNavModel());
    updateBcvRate();
  }

  Future<void> updateBcvRate() async {
    bcvRate = await ExchangeRateService.instance.getBcvRate();
  }

  @override
  void dispose() {
    addPagoModel.dispose();
    topNavModel.dispose();
  }

  Future<void> calculateAmounts() async {
    debugPrint('DEBUG: Iniciando calculateAmounts. productIds: $productIds');
    double total = 0.0;
    double totalCantidad = 0.0;
    
    // Si ya tenemos detalles (con cantidades), los usamos.
    if (productsDetails.isNotEmpty) {
      debugPrint('DEBUG: Usando productsDetails precargados con cantidades.');
      for (var prod in productsDetails) {
        double precio = (prod['precio'] as num).toDouble();
        int cantidad = (prod['cantidad'] as num).toInt();
        total += precio * cantidad;
        totalCantidad += cantidad;
      }
    } else {
      // Fallback a lógica antigua si no vienen detalles.
      productsDetails = [];
      final Map<String, int> counts = {};
      for (var id in productIds) {
        counts[id] = (counts[id] ?? 0) + 1;
      }

      for (var entry in counts.entries) {
        String id = entry.key;
        int cantidad = entry.value;
        
        final response = await SupaFlow.client.from('productos').select('nombre, precio').eq('id', id);
        
        if (response != null && (response as List).isNotEmpty) {
          final prod = response[0];
          double precio = (prod['precio'] as num).toDouble();
          productsDetails.add({
            'nombre': prod['nombre'],
            'precio': precio,
            'cantidad': cantidad,
          });
          total += precio * cantidad;
          totalCantidad += cantidad;
        }
      }
    }
    
    totalAmount = total;
    // Tarifa: 2$ por cada producto individual (cantidad)
    feeToPay = totalCantidad * 2.0;
    pendingBalance = feeToPay;
    debugPrint('DEBUG: calculateAmounts finalizado. Total: $totalAmount, Fee: $feeToPay, Balance: $pendingBalance, Productos: ${productsDetails.length}, Total Cantidad: $totalCantidad');
  }
}
