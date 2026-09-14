import 'package:baul_pandora/backend/schema/structs/pago_struct.dart';
import 'package:baul_pandora/components/gradient_button/gradient_button_widget.dart';
import 'package:baul_pandora/components/loading_list/loading_list_widget.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_model.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/services/cart_service.dart';
import 'package:baul_pandora/services/exchange_rate_service.dart';
import 'package:flutter/material.dart';

class FullCartViewModel extends ChangeNotifier {
  /// Local state fields
  List<Map<String, dynamic>> itemsSinStock = [];
  bool isValidating = false;
  String activeTab = 'carrito'; // 'carrito' or 'apartados'

  List<dynamic> apartados = [];
  bool isLoadingApartados = false;
  Set<String> apartadosSeleccionados = {};

  Set<String> selectedItemIds = {};
  double selectedTotal = 0.0;
  List<Map<String, dynamic>> selectedItemsDetails = [];
  double bcvRate = 0.0;

  double get bcvRateGetter => bcvRate;
  double get subtotal => selectedTotal + precioTotalApartadosSeleccionados;
  double get totalPagado => totalPagadoApartados;
  double get total => totalCarritoApartados;

  // Modelos de componentes
  late TopNavModel topNavModel;
  late GradientButtonModel gradientButtonModel;
  late LoadingListModel loadingListModel;

  void initState(BuildContext context) {
    topNavModel = createModel(context, () => TopNavModel());
    gradientButtonModel = createModel(context, () => GradientButtonModel());
    loadingListModel = createModel(context, () => LoadingListModel());
    updateBcvRate();
  }

  Future<void> updateBcvRate() async {
    try {
      bcvRate = await ExchangeRateService.instance.getBcvRate();
    } catch (e) {
      debugPrint('Error updating BCV rate: $e');
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    topNavModel.dispose();
    gradientButtonModel.dispose();
    loadingListModel.dispose();
    super.dispose();
  }

  // Helper para notificar cambios
  void updatePage(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  // Métodos de lógica de selección de carrito
  void toggleSelection(String productId) {
    debugPrint('DEBUG: Seleccionado en Carrito: $productId');
    if (selectedItemIds.contains(productId)) {
      selectedItemIds.remove(productId);
    } else {
      selectedItemIds.add(productId);
    }
    updateSelectedTotal();
    notifyListeners();
    updatePage(() {});
  }

  void selectAll(List<String> allIds) {
    selectedItemIds = allIds.toSet();
    updateSelectedTotal();
    notifyListeners();
    updatePage(() {});
  }

  void deselectAll() {
    selectedItemIds.clear();
    updateSelectedTotal();
    notifyListeners();
    updatePage(() {});
  }

  bool isAllSelected(List<String> allIds) {
    return allIds.isNotEmpty && selectedItemIds.length == allIds.length;
  }

  Future<void> updateSelectedTotal() async {
    debugPrint(
        'DEBUG: Iniciando updateSelectedTotal. Items seleccionados: $selectedItemIds');
    if (selectedItemIds.isEmpty) {
      selectedTotal = 0.0;
      selectedItemsDetails = [];
      notifyListeners();
      return;
    }

    try {
      final itemsInCart = FFAppState()
          .itemsCarrito
          .where((i) => selectedItemIds.contains(i.idProducto))
          .toList();
      debugPrint('DEBUG: Items en carrito filtrados: ${itemsInCart.length}');

      final idsString = '(${selectedItemIds.map((id) => '"$id"').join(',')})';
      debugPrint('DEBUG: Query productos para IDs: $idsString');
      final response = await SupaFlow.client
          .from('productos')
          .select('id, nombre, precio')
          .filter('id', 'in', idsString);

      Map<String, dynamic> productDataMap = {};
      for (var row in (response as List)) {
        productDataMap[row['id']] = row;
      }
      debugPrint('DEBUG: Productos encontrados: ${productDataMap.length}');

      double total = 0.0;
      List<Map<String, dynamic>> details = [];

      for (var item in itemsInCart) {
        final product = productDataMap[item.idProducto];
        if (product != null) {
          double price = (product['precio'] as num).toDouble();
          int qty = item.cantidad;
          total += price * qty;

          details.add({
            'id': product['id'], // Added ID
            'nombre': product['nombre'],
            'precio': price,
            'cantidad': qty,
            'subtotal': price * qty,
          });
        }
      }

      selectedTotal = total;
      selectedItemsDetails = details;
      debugPrint(
          'DEBUG: selectedItemsDetails actualizados: $selectedItemsDetails');
    } catch (e) {
      debugPrint('Error updating selected total: $e');
    } finally {
      notifyListeners();
      updatePage(() {});
    }
  }

  List<Map<String, dynamic>> get selectedApartadosDetails {
    final List<Map<String, dynamic>> details = [];
    debugPrint('DEBUG: apartadosSeleccionados: $apartadosSeleccionados');
    for (var apartado in apartados) {
      if (apartado['items'] != null) {
        for (var item in (apartado['items'] as List)) {
          debugPrint('DEBUG: Verificando item: ${item['id']}');
          if (apartadosSeleccionados.contains(item['id'].toString())) {
            debugPrint('DEBUG: Item seleccionado encontrado: ${item['id']}');
            details.add({
              'id': item['product_id'], // Usar product_id aquí
              'nombre': item['nombre'],
              'precio': item['precio'],
              'cantidad': item['cantidad'],
              'subtotal': item['precio'] * item['cantidad'],
              'pedido_id': apartado['pedido_id'],
            });
          }
        }
      }
    }
    debugPrint('DEBUG: selectedApartadosDetails: $details');
    return details;
  }

  List<Map<String, dynamic>> get allSelectedDetails {
    return [...selectedItemsDetails, ...selectedApartadosDetails];
  }

  double get totalPagadoApartados {
    double total = 0.0;
    Set<String> affectedPedidoIds = {};

    // Find all orders that have at least one item selected
    for (var apartado in apartados) {
      if (apartado['items'] != null) {
        for (var item in (apartado['items'] as List)) {
          if (apartadosSeleccionados.contains(item['id'].toString())) {
            affectedPedidoIds.add(apartado['pedido_id'].toString());
          }
        }
      }
    }

    // Sum the 'monto_pagado' of those unique orders
    for (var apartado in apartados) {
      if (affectedPedidoIds.contains(apartado['pedido_id'].toString())) {
        total += (apartado['monto_pagado'] as num).toDouble();
      }
    }

    return total;
  }

  double get precioTotalApartadosSeleccionados {
    double total = 0.0;
    for (var apartado in apartados) {
      if (apartado['items'] != null) {
        for (var item in (apartado['items'] as List)) {
          if (apartadosSeleccionados.contains(item['id'].toString())) {
            total +=
                (item['precio'] as num).toDouble() * (item['cantidad'] as int);
          }
        }
      }
    }
    return total;
  }

  double get totalCarritoApartados =>
      (selectedTotal + precioTotalApartadosSeleccionados) -
      totalPagadoApartados;

  // Métodos de lógica de apartados
  void toggleApartadoSeleccion(String itemId) {
    debugPrint('DEBUG: Seleccionado en Apartado: $itemId');
    debugPrint('DEBUG: toggleApartadoSeleccion llamado para item: $itemId');
    if (apartadosSeleccionados.contains(itemId)) {
      apartadosSeleccionados.remove(itemId);
    } else {
      apartadosSeleccionados.add(itemId);
    }
    debugPrint(
        'DEBUG: apartadosSeleccionados tras toggle: $apartadosSeleccionados');
    notifyListeners();
    updatePage(() {});
  }

  void selectAllApartados() {
    for (var apartado in apartados) {
      if (apartado['items'] != null) {
        for (var item in (apartado['items'] as List)) {
          final int maxQty = item['stock'] ?? 0;
          if (maxQty > 0) {
            apartadosSeleccionados.add(item['id'].toString());
          }
        }
      }
    }
    notifyListeners();
    updatePage(() {});
  }

  void deselectAllApartados() {
    apartadosSeleccionados.clear();
    notifyListeners();
    updatePage(() {});
  }

  bool areAllApartadosSelected() {
    int totalItems = 0;
    for (var apartado in apartados) {
      if (apartado['items'] != null) {
        totalItems += (apartado['items'] as List).length;
      }
    }
    return totalItems > 0 && apartadosSeleccionados.length == totalItems;
  }

  Future<void> validateCartStock(BuildContext context) async {
    isValidating = true;
    updatePage(() {});
    try {
      // 1. Obtener ítems del carrito con stock actual
      final cartItems = FFAppState().itemsCarrito;

      // 2. Llamar a CartService para validar stock y obtener estados
      final itemsMap = cartItems
          .map((item) => {
                'id': item.idProducto,
                'cantidad': item.cantidad,
              })
          .toList();

      final stockInfo = await CartService.instance.checkStockLevels(itemsMap);

      // 3. Filtrar los que tienen stock 0
      itemsSinStock =
          stockInfo.where((item) => (item['stock'] as int) == 0).toList();
      debugPrint(
          'DEBUG: Productos sin stock detectados: ${itemsSinStock.length}');

      // LOG DEPURACIÓN: Mostrar stock de todos los productos en carrito
      stockInfo.forEach((item) {
        debugPrint(
            'DEBUG Stock Log: Producto: ${item['nombre']}, Stock Disponible: ${item['stock']}');
      });

      final ajustes =
          await CartService.instance.validateAndAdjustStock(itemsMap);

      if (ajustes.isNotEmpty) {
        debugPrint('Ajustes de stock realizados: $ajustes');

        // Actualizar el estado con las cantidades ajustadas
        for (var item in FFAppState().itemsCarrito) {
          final ajuste = itemsMap.firstWhere(
            (map) => map['id'] == item.idProducto,
            orElse: () => {'cantidad': item.cantidad},
          );
          item.cantidad = ajuste['cantidad'] as int;
        }

        // Notificar al usuario
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Atención: Se han ajustado cantidades por falta de stock:\n${ajustes.join(", ")}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }

        // Recalcular totales
        updateSelectedTotal();
      }
    } catch (e) {
      debugPrint('Error validating stock: $e');
    } finally {
      isValidating = false;
      notifyListeners();
      updatePage(() {});
    }
  }

  // Métodos de lógica de apartados locales
  void updateApartadoItemLocal(String apartadoId, String itemId, int delta) {
    debugPrint(
        'DEBUG: Iniciando actualización para apartado: $apartadoId, item: $itemId, delta: $delta');

    // Buscar el apartado y el ítem
    for (var apartado in apartados) {
      if (apartado['pedido_id'] == apartadoId) {
        var items = (apartado['items'] as List);
        debugPrint(
            'DEBUG: Apartado encontrado. Items actuales: ${items.length}');

        var item = items.cast<Map<String, dynamic>>().firstWhere(
              (i) => i['id'] == itemId,
              orElse: () => {},
            );

        if (item.isEmpty) {
          debugPrint('DEBUG: Item no encontrado en el apartado');
          return;
        }

        int nuevaCantidad = item['cantidad'] + delta;

        // Validar límites
        int min = item['cantidad_original'] ?? 0;
        int max = item['stock'] ?? 0;

        debugPrint(
            'DEBUG: Cantidad actual: ${item['cantidad']}, Nueva: $nuevaCantidad, Min: $min, Max: $max');

        if (nuevaCantidad >= min && nuevaCantidad <= max) {
          item['cantidad'] = nuevaCantidad;
          debugPrint(
              'DEBUG: Cantidad actualizada exitosamente. Nueva cantidad: ${item['cantidad']}');

          // FORZAR NOTIFICACIÓN DE CAMBIO creando una nueva lista para que Flutter detecte el cambio en memoria
          apartados = List.from(apartados);

          notifyListeners();
          updatePage(() {});
        } else {
          debugPrint(
              'DEBUG: La nueva cantidad $nuevaCantidad viola los límites [$min, $max]');
        }
        break;
      }
    }
  }

  Future<void> loadApartados() async {
    isLoadingApartados = true;
    updatePage(() {});
    try {
      apartados = await CartService.instance.fetchApartados();
    } catch (e) {
      debugPrint('Error loading apartados: $e');
    } finally {
      isLoadingApartados = false;
      updatePage(() {});
    }
  }

  Future<Map<String, dynamic>> apartarProductos(
      {List<String>? productIdsSeleccionados}) async {
    // Si se pasan IDs, los usamos, si no usamos los del set del modelo
    final ids = productIdsSeleccionados ?? selectedItemIds.toList();
    return await CartService.instance
        .apartarProductos(productIdsSeleccionados: ids);
  }

  Future<Map<String, dynamic>> pagarApartado({
    required String pedidoId,
    required PagoStruct pago,
    String? comprobante,
  }) async {
    return await CartService.instance.completeApartadoPayment(
      pedidoIdOriginal: pedidoId,
      productIdsSeleccionados: apartadosSeleccionados.toList(),
      pago: pago,
      comprobanteUrl: comprobante,
    );
  }
}
