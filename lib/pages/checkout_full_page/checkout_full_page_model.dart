import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/components/add_address_base/add_address_base_widget.dart';
import 'package:baul_pandora/components/add_pago/add_pago_widget.dart';
import 'package:baul_pandora/components/gradient_button/gradient_button_widget.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/components/u_i_marker/u_i_marker_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/custom_functions.dart' as functions;
import 'package:baul_pandora/index.dart';
import 'checkout_full_page_widget.dart' show CheckoutFullPageWidget;
import 'package:baul_pandora/services/agency_service.dart';
import 'package:baul_pandora/services/cart_service.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';

class CheckoutFullPageModel extends FlutterFlowModel<CheckoutFullPageWidget> {
  ///  Local state fields for this page.

  int stepNumber = 1;
  String? pedidoId;
  double pendingBalance = 0.0;
  double? saldoApartados;
  double? bcvRate;
  bool highlightErrors = false;
  String? deliveryType;
  String? selectedCourier;
  bool mostrarFormularioDireccion = false; // Nueva variable
  bool useProfileData = false; // Nueva variable para autocompletar
  String? selectedAgency;
  String? featuredAgencyCode;
  List<Agency> agenciasGuardadas = [];
  List<AgenciasEnvioRow> agencyResults = [];
  TextEditingController agencySearchController = TextEditingController();
  TextEditingController personNameController = TextEditingController();
  TextEditingController personPhoneController = TextEditingController();

  void addAgencyToGuardadas(Agency agency) {
    if (!agenciasGuardadas.any((a) => a.codigo == agency.codigo)) {
      agenciasGuardadas.add(agency);
    }
  }

  void removeAgencyFromGuardadas(String codigo) {
    agenciasGuardadas.removeWhere((a) => a.codigo == codigo);
  }

  bool get isValidLocation {
    if (deliveryType == null) {
      debugPrint('DEBUG isValidLocation: deliveryType es nulo');
      return false;
    }
    // Si es oficina, validamos que haya una dirección seleccionada (o que esté buscando)
    if (deliveryType == 'Oficina') {
      final valid = (address != null || selectedAgency != null);
      debugPrint('DEBUG isValidLocation (Oficina): valid=$valid, address=${address}, selectedAgency=$selectedAgency');
      return valid;
    }
    if (deliveryType == 'Casa') {
      final valid = address != null;
      debugPrint('DEBUG isValidLocation (Casa): valid=$valid, address=${address}');
      return valid;
    }
    if (deliveryType == 'Persona') {
      final phone = personPhoneController.text.trim();
      final name = personNameController.text.trim();
      // Ajustado de 7 a 5 dígitos mínimos
      final phoneRegex = RegExp(r'^\+?[\d\s\-()]{5,15}$');
      final valid = name.isNotEmpty && phone.isNotEmpty && phoneRegex.hasMatch(phone);
      
      debugPrint('DEBUG isValidLocation (Persona): valid=$valid');
      debugPrint('DEBUG isValidLocation (Persona): name="$name" (empty: ${name.isEmpty})');
      debugPrint('DEBUG isValidLocation (Persona): phone="$phone" (empty: ${phone.isEmpty}, matchesRegex: ${phoneRegex.hasMatch(phone)})');
      
      return valid;
    }
    debugPrint('DEBUG isValidLocation: deliveryType desconocido: $deliveryType');
    return false;
  }

  bool get isValidShipping {
    if (deliveryType == 'Persona') return true;
    return selectedCourier != null;
  }

  bool get isValidPayment => addPagoModel.isValid;


  bool get isOrderReady {
    return isValidLocation && isValidShipping && isValidPayment;
  }

  AddressStruct? address;
  void updateAddressStruct(Function(AddressStruct) updateFn) {
    updateFn(address ??= AddressStruct());
  }

  ShippingOptionsStruct? shippingOption;
  void updateShippingOptionStruct(Function(ShippingOptionsStruct) updateFn) {
    updateFn(shippingOption ??= ShippingOptionsStruct());
  }

  List<AddressStruct> direccionesGuardadas = [];
  void addToDireccionesGuardadas(AddressStruct item) =>
      direccionesGuardadas.add(item);
  void removeFromDireccionesGuardadas(AddressStruct item) =>
      direccionesGuardadas.remove(item);
  void removeAtIndexFromDireccionesGuardadas(int index) =>
      direccionesGuardadas.removeAt(index);
  void insertAtIndexInDireccionesGuardadas(int index, AddressStruct item) =>
      direccionesGuardadas.insert(index, item);
  void updateDireccionesGuardadasAtIndex(
          int index, Function(AddressStruct) updateFn) =>
      direccionesGuardadas[index] = updateFn(direccionesGuardadas[index]);

  List<AddressStruct> direccionesOficinaGuardadas = [];
  void addToDireccionesOficinaGuardadas(AddressStruct item) =>
      direccionesOficinaGuardadas.add(item);
  void removeFromDireccionesOficinaGuardadas(AddressStruct item) =>
      direccionesOficinaGuardadas.remove(item);
  void removeAtIndexFromDireccionesOficinaGuardadas(int index) =>
      direccionesOficinaGuardadas.removeAt(index);
  void insertAtIndexInDireccionesOficinaGuardadas(int index, AddressStruct item) =>
      direccionesOficinaGuardadas.insert(index, item);
  void updateDireccionesOficinaGuardadasAtIndex(
          int index, Function(AddressStruct) updateFn) =>
      direccionesOficinaGuardadas[index] = updateFn(direccionesOficinaGuardadas[index]);

  PagoStruct? pago;
  void updatePagoStruct(Function(PagoStruct) updateFn) {
    updateFn(pago ??= PagoStruct());
  }

  double get totalPrice {
    final bool isLiquidation = pedidoId != null;
    double baseTotal = isLiquidation ? pendingBalance : cartPrice;
    if (saldoApartados != null && saldoApartados! > 0) {
      baseTotal = baseTotal - saldoApartados!;
    }
    return baseTotal > 0 ? baseTotal : 0.0;
  }
  double get totalPagado => 0.0;

  Future<void> fetchPendingBalance() async {
    if (pedidoId == null) return;
    pendingBalance = await CartService.instance.getPendingBalance(pedidoId!);
  }

  List<dynamic> productosSeleccionados = [];

  // --- Lógica de cálculo centralizada ---

  double get cartPrice {
    return productosSeleccionados.fold(0.0, (sum, item) {
      final double price = (item['precio'] as num?)?.toDouble() ?? 0.0;
      final int qty = (item['cantidad'] as num?)?.toInt() ?? 1;
      return sum + (price * qty);
    });
  }

  double calculateTotal(double shippingPrice) {
    final bool isLiquidation = pedidoId != null;
    double baseTotal = isLiquidation ? pendingBalance : cartPrice;
    
    // Restar el saldo de apartados si existe
    if (saldoApartados != null && saldoApartados! > 0) {
      baseTotal = baseTotal - saldoApartados!;
    }
    
    return (baseTotal > 0 ? baseTotal : 0.0) + shippingPrice;
  }
  
  // ---------------------------------------

  Future<void> initializeProducts(String? productIdsJson) async {
    if (productIdsJson == null) return;
    
    final List<dynamic> selection = jsonDecode(productIdsJson);
    
    // Obtener productos necesarios desde Supabase para mapear detalles
    final productos = await ProductosTable().queryRows(
      queryFn: (q) => q,
    );
    
    // Mapear combinando los detalles con la cantidad seleccionada
    List<Map<String, dynamic>> tempProductos = [];
    for (var item in selection) {
      final idBuscado = item['id']?.toString().trim();
      
      if (idBuscado == null || idBuscado == 'null') continue;

      final p = productos.firstWhere(
        (prod) => prod.id.toString().trim() == idBuscado, 
        orElse: () => ProductosRow({}), 
      );
      
      if (p.data['id'] != null) {
        tempProductos.add({
          'id': p.id,
          'nombre': p.nombre,
          'precio': p.precio,
          'cantidad': item['cantidad'] ?? 1,
          'pedido_id': item['pedido_id'], // Capturar pedido_id si existe
        });
      }
    }
    productosSeleccionados = tempProductos;
  }
  
  // --- Lógica de validación centralizada ---

  bool validateStep1() {
    return isValidLocation && isValidShipping;
  }

  bool validateStep2() {
    return isValidPayment;
  }
  
  // ---------------------------------------

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Query Rows] action in checkout_FullPage widget.
  List<UsuariosRow>? usuarioRow;
  // Model for topNav component.
  late TopNavModel topNavModel;
  // Model for gradientButton component.
  late GradientButtonModel gradientButtonModel;
  // State field(s) for Expandable widget.
  late ExpandableController expandableExpandableController1;

  // Model for addAddress_Base component.
  late AddAddressBaseModel addAddressBaseModel;
  // Model for UI_Marker component.
  late UIMarkerModel uIMarkerModel1;
  // State field(s) for Expandable widget.
  late ExpandableController expandableExpandableController2;

  // Model for addPago component.
  late AddPagoModel addPagoModel;
  // Model for UI_Marker component.
  late UIMarkerModel uIMarkerModel2;
  // Stores action output result for [Backend Call - Query Rows] action in Button widget.
  List<PedidoItemsRow>? itemsCarrito;

  @override
  void initState(BuildContext context) {
    topNavModel = createModel(context, () => TopNavModel());
    gradientButtonModel = createModel(context, () => GradientButtonModel());
    addAddressBaseModel = createModel(context, () => AddAddressBaseModel());
    uIMarkerModel1 = createModel(context, () => UIMarkerModel());
    addPagoModel = createModel(context, () => AddPagoModel());
    uIMarkerModel2 = createModel(context, () => UIMarkerModel());
  }

  @override
  void dispose() {
    topNavModel.dispose();
    gradientButtonModel.dispose();
    expandableExpandableController1.dispose();
    addAddressBaseModel.dispose();
    uIMarkerModel1.dispose();
    expandableExpandableController2.dispose();
    addPagoModel.dispose();
    uIMarkerModel2.dispose();
  }

  Future<void> deleteAddress(AddressStruct addr) async {
    try {
      removeFromDireccionesGuardadas(addr);
      FFAppState().listaDirecciones = direccionesGuardadas.toList().cast<AddressStruct>();
      
      // Si la dirección eliminada era la seleccionada actualmente, deseleccionarla
      if (address == addr || selectedAgency == addr.addressName || featuredAgencyCode == addr.agencia) {
        address = null;
        selectedAgency = null;
        featuredAgencyCode = null;
      }

      if (currentUserUid.isNotEmpty) {
        final dataToSave = direccionesGuardadas.map((a) => functions.addressToJSON(a)).toList();
        await UsuariosTable().update(
          data: {'datos_direccion': dataToSave},
          matchingRows: (rows) => rows.eq('id', currentUserUid),
        );
        debugPrint('DEBUG: Dirección eliminada exitosamente en Supabase. Quedan ${dataToSave.length}');
      }
    } catch (e) {
      debugPrint('Error deleting address: $e');
    }
  }

  Future<void> saveUserPreferences() async {
    try {
      debugPrint('DEBUG: Iniciando saveUserPreferences con validación local.');

      bool changed = false;

      // 2. Manejar Direcciones usando el estado local como fuente de verdad
      if (deliveryType == 'Casa' && address != null) {
        address!.tipoDireccion = 'casa';
        final cleanAddr = address!.address.trim().toLowerCase();
        final cleanCity = address!.city.trim().toLowerCase();
        if (!direccionesGuardadas.any((a) => a.tipoDireccion == 'casa' && a.address.trim().toLowerCase() == cleanAddr && a.city.trim().toLowerCase() == cleanCity)) {
          addToDireccionesGuardadas(address!);
          changed = true;
          debugPrint('DEBUG: Añadiendo a estado local: ${address?.address}');
        }
      } else if (deliveryType == 'Oficina' && selectedAgency != null) {
        final cleanCode = (featuredAgencyCode ?? '').trim();
        final cleanName = selectedAgency!.trim().toLowerCase();

        bool exists = direccionesGuardadas.any((a) =>
            a.tipoDireccion == 'agencia' &&
            ((cleanCode.isNotEmpty && a.agencia.trim() == cleanCode) ||
             (a.addressName.trim().toLowerCase() == cleanName)));

        if (!exists) {
          final agencyAddress = AddressStruct(
            addressName: selectedAgency,
            address: address?.address.isNotEmpty == true ? address!.address : selectedAgency,
            tipoDireccion: 'agencia',
            agencia: cleanCode,
          );
          addToDireccionesGuardadas(agencyAddress);
          changed = true;
          debugPrint('DEBUG: Añadiendo agencia a estado local: $selectedAgency (Cod: $cleanCode)');
        } else {
          // Si ya existe pero no tenía código guardado, actualizarlo
          for (var a in direccionesGuardadas) {
            if (a.tipoDireccion == 'agencia' &&
                (a.addressName.trim().toLowerCase() == cleanName || a.agencia.trim() == cleanCode)) {
              if (a.agencia.isEmpty && cleanCode.isNotEmpty) {
                a.agencia = cleanCode;
                changed = true;
              }
            }
          }
          debugPrint('DEBUG: Agencia ya existe en estado local.');
        }
      }

      // 3. Actualizar Supabase solo si hubo cambios en el estado local
      if (changed && currentUserUid.isNotEmpty) {
        final dataToSave = direccionesGuardadas.map((a) => functions.addressToJSON(a)).toList();
        await UsuariosTable().update(
          data: {'datos_direccion': dataToSave},
          matchingRows: (rows) => rows.eq('id', currentUserUid),
        );
        debugPrint('DEBUG: Guardado exitoso en Supabase con ${dataToSave.length} direcciones.');
      } else {
        debugPrint('DEBUG: No hubo cambios en direcciones, no se actualizó Supabase.');
      }
    } catch (e) {
      debugPrint('Error saving user preferences: $e');
    }
  }
}
