import 'package:baul_pandora/app_state.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/backend/schema/structs/carrito_struct.dart';
import 'package:baul_pandora/backend/schema/structs/index.dart';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class CartService {
  static final CartService instance = CartService._internal();
  CartService._internal();

  /// Agrega un producto al carrito.
  Future<void> addItem(String productId, double price,
      {int quantity = 1}) async {
    final appState = FFAppState();
    _updateLocalCart(productId, quantity);

    if (loggedIn) {
      try {
        String pedidoId = await _getOrCreateActiveCartId();
        final response = await SupaFlow.client
            .from('pedido_items')
            .select()
            .eq('pedido_id', pedidoId)
            .eq('product_id', productId)
            .maybeSingle();

        if (response != null) {
          await SupaFlow.client
              .from('pedido_items')
              .update({'quantity': (response['quantity'] ?? 0) + quantity}).eq(
                  'id', response['id']);
        } else {
          await SupaFlow.client.from('pedido_items').insert({
            'pedido_id': pedidoId,
            'product_id': productId,
            'quantity': quantity,
            'price_at_purchase': price,
          });
        }
      } catch (e) {
        debugPrint('Error adding item: $e');
      }
    }
  }

  /// Actualiza la cantidad de un producto dentro de un apartado.
  Future<void> updateApartadoItem(String itemId, int newQuantity) async {
    try {
      if (newQuantity > 0) {
        await SupaFlow.client
            .from('pedido_items')
            .update({'quantity': newQuantity}).eq('id', itemId);
      } else {
        await SupaFlow.client.from('pedido_items').delete().eq('id', itemId);
      }
      debugPrint('Apartado item updated successfully: $itemId, $newQuantity');
    } catch (e) {
      debugPrint('Error updating apartado item: $e');
    }
  }

  /// Resta una unidad de un producto.
  Future<void> decrementItem(String productId, double price) async {
    final appState = FFAppState();
    _updateLocalCart(productId, -1);

    if (loggedIn && appState.carritoActual.isNotEmpty) {
      try {
        final response = await SupaFlow.client
            .from('pedido_items')
            .select()
            .eq('pedido_id', appState.carritoActual)
            .eq('product_id', productId)
            .maybeSingle();

        if (response != null) {
          int currentQty = response['quantity'] ?? 0;
          if (currentQty > 1) {
            await SupaFlow.client
                .from('pedido_items')
                .update({'quantity': currentQty - 1}).eq('id', response['id']);
          } else {
            await SupaFlow.client
                .from('pedido_items')
                .delete()
                .eq('id', response['id']);
          }
        }
      } catch (e) {
        debugPrint('Error decrementing item: $e');
      }
    }
  }

  /// Elimina un producto completamente.
  Future<void> removeItem(String productId, double price) async {
    final appState = FFAppState();
    List<CarritoStruct> currentItems = List.from(appState.itemsCarrito);
    int index = currentItems.indexWhere((item) => item.idProducto == productId);

    if (index != -1) {
      currentItems.removeAt(index);
      appState.itemsCarrito = currentItems;
    }

    if (loggedIn && appState.carritoActual.isNotEmpty) {
      try {
        await SupaFlow.client
            .from('pedido_items')
            .delete()
            .eq('pedido_id', appState.carritoActual)
            .eq('product_id', productId);
      } catch (e) {
        debugPrint('Error removing item: $e');
      }
    }
  }

  Future<double> getPendingBalance(String pedidoId) async {
    try {
      final response = await SupaFlow.client
          .from('pedidos')
          .select('saldo_pendiente')
          .eq('id', pedidoId)
          .maybeSingle();

      return (response?['saldo_pendiente'] as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('Error fetching pending balance: $e');
      return 0.0;
    }
  }

  /// Sincroniza el saldo pendiente de un pedido en la base de datos.
  Future<void> syncPendingBalance(String pedidoId) async {
    try {
      // 1. Calcular el total bruto del pedido sumando sus items
      final items = await SupaFlow.client
          .from('pedido_items')
          .select('price_at_purchase, quantity')
          .eq('pedido_id', pedidoId);

      double totalPedido = 0.0;
      for (var item in (items as List)) {
        totalPedido += (item['price_at_purchase'] as num).toDouble() *
            (item['quantity'] as int);
      }

      // 2. Sumar todos los pagos APROBADOS / CONFIRMADOS para este pedido
      final pagos = await SupaFlow.client
          .from('pagos')
          .select('monto')
          .eq('pedido_id', pedidoId)
          .inFilter('estado', ['aprobado', 'confirmado']);

      double totalPagado = 0.0;
      for (var pago in (pagos as List)) {
        totalPagado += (pago['monto'] as num).toDouble();
      }

      double balance = totalPedido - totalPagado;

      // 3. Actualizar la tabla de pedidos
      await SupaFlow.client
          .from('pedidos')
          .update({'saldo_pendiente': balance}).eq('id', pedidoId);

      // 4. Si el balance es <= 0, marcar el pedido como pagado
      if (balance <= 0) {
        await SupaFlow.client
            .from('pedidos')
            .update({'status': 'pagado'}).eq('id', pedidoId);
      }
    } catch (e) {
      debugPrint('Error syncing pending balance: $e');
    }
  }

  /// Obtiene los niveles de stock actuales para una lista de productos.
  Future<List<Map<String, dynamic>>> checkStockLevels(
      List<dynamic> items) async {
    final productIds =
        items.map((item) => item['id'].toString()).toSet().toList();

    final stockData = await SupaFlow.client
        .from('productos')
        .select('id, nombre, stock')
        .filter('id', 'in', productIds);

    return (stockData as List).map((item) {
      final int stock = (item['stock'] as num?)?.toInt() ?? 0;

      debugPrint(
          'DEBUG StockCheck (NUEVA LOGICA): ID: ${item['id']}, Nombre: ${item['nombre']}, Stock Físico Disponible: $stock');

      return {
        'id': item['id'],
        'nombre': item['nombre'],
        'stock': stock, // Ahora solo usamos stock físico
      };
    }).toList();
  }

  /// Valida el stock de los ítems en el carrito y ajusta las cantidades si es necesario.
  /// Retorna un mensaje con los ajustes realizados, o una cadena vacía si no hubo ajustes.
  Future<List<String>> validateAndAdjustStock(List<dynamic> items) async {
    debugPrint(
        'DEBUG: Iniciando validateAndAdjustStock con ${items.length} items.');
    final productIds =
        items.map((item) => item['id'].toString()).toSet().toList();

    final stockData = await SupaFlow.client
        .from('productos')
        .select('id, nombre, stock, stock_reservado')
        .filter('id', 'in', productIds);

    debugPrint('DEBUG: Stock data recibida: $stockData');

    final stockMap = {for (var item in (stockData as List)) item['id']: item};
    List<String> mensajesAjuste = [];

    for (var item in items) {
      final productStock = stockMap[item['id']];
      if (productStock == null) {
        debugPrint('DEBUG: Producto no encontrado en stockMap: ${item['id']}');
        continue;
      }

      final int stockDisponible = (productStock['stock'] as num?)?.toInt() ?? 0;
      final int cantidadCarrito = item['cantidad'] as int;

      debugPrint(
          'DEBUG: Validando: ${productStock['nombre']} (ID: ${item['id']})');
      debugPrint(
          'DEBUG: Cantidad carrito: $cantidadCarrito, Stock Físico Total: $stockDisponible');

      // Lógica actualizada:
      // Usamos solo el stock físico. Si la cantidad en carrito supera el stock, ajustamos al máximo físico.
      final int cantidadAjustada = stockDisponible <= 0
          ? 0
          : (cantidadCarrito > stockDisponible
              ? stockDisponible
              : cantidadCarrito);

      if (cantidadCarrito != cantidadAjustada) {
        debugPrint(
            'DEBUG: Ajustando cantidad para ${productStock['nombre']} de $cantidadCarrito a $cantidadAjustada');
        item['cantidad'] = cantidadAjustada;
        mensajesAjuste
            .add('${productStock['nombre']} (ajustado a $cantidadAjustada)');
      } else {
        debugPrint('DEBUG: Cantidad válida para ${productStock['nombre']}');
      }
    }

    return mensajesAjuste;
  }

  Future<Map<String, dynamic>> apartarProductos({
    List<String>? productIdsSeleccionados,
    List<Map<String, dynamic>>? itemsToProcess,
    PagoStruct? datosPago,
    String? comprobanteUrl,
    bool esPagoInmediato = true,
  }) async {
    final appState = FFAppState();

    final currentUser = SupaFlow.client.auth.currentUser;
    if (currentUser == null) {
      return {
        'success': false,
        'message': 'Debes estar registrado para apartar productos'
      };
    }

    List<CarritoStruct> itemsToProcessList = [];
    if (itemsToProcess != null) {
      itemsToProcessList = itemsToProcess
          .map((item) => CarritoStruct(
                idProducto: item['id'].toString(),
                cantidad: (item['cantidad'] as num).toInt(),
              ))
          .toList();
    } else {
      itemsToProcessList = productIdsSeleccionados != null
          ? appState.itemsCarrito
              .where(
                  (item) => productIdsSeleccionados.contains(item.idProducto))
              .toList()
          : appState.itemsCarrito;
    }

    if (itemsToProcessList.isEmpty)
      return {'success': false, 'message': 'Carrito vacío'};

    try {
      double totalPedido = 0.0;
      for (var item in itemsToProcessList) {
        final prod = await SupaFlow.client
            .from('productos')
            .select('precio')
            .eq('id', item.idProducto)
            .single();
        totalPedido += (prod['precio'] as num).toDouble() * item.cantidad;
      }

      double fee = itemsToProcessList.length * 2.0;

      final newPedido = await SupaFlow.client
          .from('pedidos')
          .insert({
            'user_id': currentUser.id,
            'status': 'apartado',
            'total_price': totalPedido,
            'saldo_pendiente': totalPedido - (datosPago?.montoUsd ?? 0.0),
            'paid_amount_usd': datosPago?.montoUsd ?? 0.0,
            'fecha_expiracion': DateTime.now()
                .add(Duration(days: esPagoInmediato ? 30 : 1))
                .toIso8601String(),
          })
          .select()
          .single();

      String pedidoId = newPedido['id'];

      // Register the reservation payment
      if (datosPago != null || comprobanteUrl != null) {
        debugPrint('DEBUG: Insertando pago...');

        final currentUserObj = SupaFlow.client.auth.currentUser;
        String emisorNombre = datosPago?.nombre ?? 'Anónimo';
        if (emisorNombre == 'Anónimo' || emisorNombre.isEmpty) {
          if (currentUserObj != null) {
            emisorNombre =
                currentUserObj.userMetadata?['full_name'] as String? ?? '';
            if (emisorNombre.isEmpty) {
              try {
                final userRow = await SupaFlow.client
                    .from('usuarios')
                    .select()
                    .eq('id', currentUserObj.id)
                    .maybeSingle();
                if (userRow != null) {
                  emisorNombre = (userRow['nombre_completo'] ?? userRow['nombre'] ?? '') as String;
                }
              } catch (_) {}
            }
          }
        }
        if (emisorNombre.isEmpty) emisorNombre = 'Anónimo';

        String emisorEmail = datosPago?.email ?? 'N/A';
        if (emisorEmail == 'N/A' || emisorEmail.isEmpty) {
          if (currentUserObj != null) {
            emisorEmail = currentUserObj.email ?? 'N/A';
          }
        }
        if (emisorEmail.isEmpty) emisorEmail = 'N/A';

        // Estructura de inserción base
        Map<String, dynamic> datosInsercion = {
          'pedido_id': pedidoId,
          'monto': datosPago?.montoUsd ??
              0.0, // La restricción NOT NULL de 'monto' se satisface con el USD
          'amount_usd_calculated': datosPago?.montoUsd ?? 0.0,
          'referencia': datosPago?.referencia ?? 'S/R',
          'nombre_emisor': emisorNombre,
          'email_emisor': emisorEmail,
          'telefono_emisor': datosPago?.numeroTelefono ?? 'N/A',
          'banco_emisor': datosPago?.bancoEnviado ?? 'Desconocido',
          'comprobante_url': comprobanteUrl,
          'estado': 'pendiente',
        };

        // Si es pago en VES, añadimos la info histórica
        if (datosPago != null && datosPago.montoVes > 0) {
          datosInsercion['amount_ves'] = datosPago.montoVes;
          datosInsercion['exchange_rate_applied'] = datosPago.tasaAplicada;
          datosInsercion['moneda'] = 'VES';
        } else {
          datosInsercion['moneda'] = 'USD';
        }

        await SupaFlow.client.from('pagos').insert(datosInsercion);
        debugPrint('DEBUG: Pago insertado exitosamente');
      }

      for (var item in itemsToProcessList) {
        final prod = await SupaFlow.client
            .from('productos')
            .select('precio, stock, stock_reservado')
            .eq('id', item.idProducto)
            .single();

        await SupaFlow.client.from('pedido_items').insert({
          'pedido_id': pedidoId,
          'product_id': item.idProducto,
          'quantity': item.cantidad,
          'price_at_purchase': (prod['precio'] as num).toDouble(),
        });

        // Actualizar stock: Sumar a reservado y restar de disponible
        int currentStock = (prod['stock'] as num).toInt();
        int currentReserved = (prod['stock_reservado'] as num).toInt();

        await SupaFlow.client.from('productos').update({
          'stock': currentStock - item.cantidad,
          'stock_reservado': currentReserved + item.cantidad,
        }).eq('id', item.idProducto);
      }

      // SIEMPRE limpiar el carrito
      await _removeFromCart(
          itemsToProcessList.map((e) => e.idProducto).toList());

      return {
        'success': true,
        'message': 'Apartado creado con éxito',
        'pedidoId': pedidoId
      };
    } catch (e, stackTrace) {
      debugPrint('Error detallado en apartarProductos: $e');
      debugPrint('StackTrace: $stackTrace');
      return {'success': false, 'message': 'Error al procesar apartado: $e'};
    }
  }

  Future<Map<String, dynamic>> completeApartadoPayment({
    required String pedidoIdOriginal,
    required List<String> productIdsSeleccionados,
    required PagoStruct pago,
    String? comprobanteUrl,
  }) async {
    if (!loggedIn)
      return {'success': false, 'message': 'Debes estar autenticado'};

    try {
      // 1. Obtener pedido para saber el total y saldo actual
      final pedido = await SupaFlow.client
          .from('pedidos')
          .select('total_price, paid_amount_usd')
          .eq('id', pedidoIdOriginal)
          .single();
      double total = (pedido['total_price'] as num).toDouble();
      double currentPaid = (pedido['paid_amount_usd'] as num).toDouble();

      double nuevoMontoUsd = pago.montoUsd;
      double nuevoTotalPagado = currentPaid + nuevoMontoUsd;
      double nuevoSaldoPendiente = total - nuevoTotalPagado;

      final currentUserObj = SupaFlow.client.auth.currentUser;
      String emisorNombre = pago.nombre;
      if (emisorNombre.isEmpty || emisorNombre == 'Anónimo') {
        if (currentUserObj != null) {
          emisorNombre =
              currentUserObj.userMetadata?['full_name'] as String? ?? '';
          if (emisorNombre.isEmpty) {
            try {
              final userRow = await SupaFlow.client
                  .from('usuarios')
                  .select()
                  .eq('id', currentUserObj.id)
                  .maybeSingle();
              if (userRow != null) {
                emisorNombre = (userRow['nombre_completo'] ?? userRow['nombre'] ?? '') as String;
              }
            } catch (_) {}
          }
        }
      }
      if (emisorNombre.isEmpty) emisorNombre = 'Anónimo';

      String emisorEmail = pago.email;
      if (emisorEmail.isEmpty || emisorEmail == 'N/A') {
        if (currentUserObj != null) {
          emisorEmail = currentUserObj.email ?? 'N/A';
        }
      }
      if (emisorEmail.isEmpty) emisorEmail = 'N/A';

      // 2. Insertar el pago vinculado al pedido ORIGINAL
      await SupaFlow.client.from('pagos').insert({
        'pedido_id': pedidoIdOriginal,
        'amount_ves': pago.montoVes,
        'exchange_rate_applied': pago.tasaAplicada,
        'amount_usd_calculated': nuevoMontoUsd,
        'comprobante_url': comprobanteUrl,
        'referencia': pago.referencia,
        'banco_emisor': pago.bancoEnviado,
        'nombre_emisor': emisorNombre,
        'email_emisor': emisorEmail,
        'estado': 'pendiente',
      });

      // 3. Actualizar pedido con nuevo saldo
      await SupaFlow.client.from('pedidos').update({
        'paid_amount_usd': nuevoTotalPagado,
        'saldo_pendiente': nuevoSaldoPendiente,
      }).eq('id', pedidoIdOriginal);

      // 4. Actualizar Stock: de "Reservado" a "Vendido"
      for (var prodId in productIdsSeleccionados) {
        final item = await SupaFlow.client
            .from('pedido_items')
            .select('quantity')
            .eq('pedido_id', pedidoIdOriginal)
            .eq('product_id', prodId)
            .single();

        final qty = item['quantity'] as int;
        final prod = await SupaFlow.client
            .from('productos')
            .select('stock, stock_reservado')
            .eq('id', prodId)
            .single();

        int currentStock = prod['stock'] ?? 0;
        int currentReserved = prod['stock_reservado'] ?? 0;

        await SupaFlow.client.from('productos').update({
          'stock': currentStock - qty,
          'stock_reservado': currentReserved > 0 ? currentReserved - qty : 0,
        }).eq('id', prodId);
      }

      return {'success': true, 'message': 'Pago procesado y saldo actualizado'};
    } catch (e) {
      debugPrint('Error completeApartadoPayment: $e');
      return {'success': false, 'message': 'Error al procesar el pago'};
    }
  }

  Future<List<Map<String, dynamic>>> fetchApartados() async {
    if (!loggedIn) return [];
    try {
      final user = SupaFlow.client.auth.currentUser!;
      final pedidos = await SupaFlow.client
          .from('pedidos')
          .select(
              'id, saldo_pendiente, pedido_items(id, product_id, quantity, price_at_purchase, productos(nombre, stock))')
          .eq('user_id', user.id)
          .eq('status', 'apartado');

      // Transform the response to match the structure expected by the UI
      return (pedidos as List<dynamic>).map((pedido) {
        // Calcular el total del pedido para obtener el monto pagado
        final items = pedido['pedido_items'] as List<dynamic>;
        double totalPedido = 0.0;
        for (var item in items) {
          totalPedido += (item['price_at_purchase'] as num).toDouble() *
              (item['quantity'] as int);
        }
        double saldoPendiente = (pedido['saldo_pendiente'] as num).toDouble();
        double totalPagado = totalPedido - saldoPendiente;

        return {
          'pedido_id': pedido['id'],
          'saldo_pendiente': saldoPendiente,
          'monto_pagado': totalPagado, // Nuevo campo
          'items': (pedido['pedido_items'] as List<dynamic>).map((item) {
            final producto = item['productos'] ?? {};
            return {
              'id': item['id'],
              'product_id': item['product_id'],
              'nombre': producto['nombre'] ?? 'Producto desconocido',
              'cantidad': item['quantity'],
              'cantidad_original': item[
                  'quantity'], // Guardamos la cantidad original para el límite mínimo
              'precio': item['price_at_purchase'],
              'stock': producto['stock'] ?? 0, // Stock actual
            };
          }).toList(),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching apartados: $e');
      return [];
    }
  }

  /// Finaliza la compra de un pedido, actualiza el stock y limpia el carrito.
  Future<Map<String, dynamic>> finalizarPedido({
    required String pedidoId,
    required double totalFinal,
    required String finalShippingAddress,
    required Map<String, dynamic> paymentDetails,
    required String orderStatus,
  }) async {
    try {
      // 1. Actualizar el Pedido en Supabase
      await SupaFlow.client.from('pedidos').update({
        'status': orderStatus,
        'total_price': totalFinal,
        'shipping_address': finalShippingAddress,
        'datos_pago': paymentDetails,
        'created_at': DateTime.now().toIso8601String(),
      }).eq('id', pedidoId);

      // 2. Actualizar Stock de los productos
      final items = await SupaFlow.client
          .from('pedido_items')
          .select('product_id, quantity')
          .eq('pedido_id', pedidoId);

      for (var item in (items as List)) {
        final prodId = item['product_id'];
        final qty = item['quantity'] as int;

        final prod = await SupaFlow.client
            .from('productos')
            .select('stock, stock_reservado')
            .eq('id', prodId)
            .single();

        int currentStock = prod['stock'] ?? 0;
        int currentReserved = prod['stock_reservado'] ?? 0;

        await SupaFlow.client.from('productos').update({
          'stock': currentStock - qty,
          'stock_reservado': currentReserved > 0 ? currentReserved - qty : 0,
        }).eq('id', prodId);
      }

      // 3. Limpiar Carrito
      await clearCart();
      debugPrint(
          'DEBUG: Cart items after payment: ${FFAppState().itemsCarrito.map((e) => e.idProducto).toList()}');

      return {'success': true, 'message': 'Pedido finalizado con éxito'};
    } catch (e) {
      debugPrint('Error finalizarPedido: $e');
      return {'success': false, 'message': 'Error al finalizar el pedido: $e'};
    }
  }

  Future<String?> uploadPaymentProof(
      dynamic fileOrBytes, String pedidoId) async {
    try {
      final fileName =
          'pagos/${pedidoId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      if (fileOrBytes is Uint8List) {
        await SupaFlow.client.storage.from('comprobantes').uploadBinary(
              fileName,
              fileOrBytes,
              fileOptions:
                  const FileOptions(contentType: 'image/jpeg', upsert: true),
            );
      } else if (fileOrBytes is File) {
        await SupaFlow.client.storage.from('comprobantes').upload(
              fileName,
              fileOrBytes,
              fileOptions:
                  const FileOptions(contentType: 'image/jpeg', upsert: true),
            );
      }
      return SupaFlow.client.storage
          .from('comprobantes')
          .getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Error uploadPaymentProof: $e');
      return null;
    }
  }

  Future<String?> uploadPaymentProofBytes(
      Uint8List bytes, String pedidoId) async {
    return uploadPaymentProof(bytes, pedidoId);
  }

  Future<void> deletePaymentProof(String url) async {
    try {
      final uri = Uri.parse(url);
      final path = uri.pathSegments
          .last; // Asumiendo que la estructura es .../comprobantes/pagos/filename
      // Necesitamos extraer el path correcto. Si getPublicUrl devuelve la ruta completa,
      // extraer el path del archivo desde la URL.
      // Suponiendo que el bucket es 'comprobantes' y la estructura es pagos/nombre_archivo.jpg
      final fileName = url.split('/').last;
      await SupaFlow.client.storage
          .from('comprobantes')
          .remove(['pagos/$fileName']);
      debugPrint('Comprobante eliminado: $fileName');
    } catch (e) {
      debugPrint('Error al eliminar comprobante: $e');
    }
  }

  Future<void> clearCart() async {
    final appState = FFAppState();
    appState.itemsCarrito = [];
    appState.itemsCarritoActual = [];
    if (loggedIn && appState.carritoActual.isNotEmpty) {
      try {
        await SupaFlow.client
            .from('pedido_items')
            .delete()
            .eq('pedido_id', appState.carritoActual);
        await SupaFlow.client
            .from('pedidos')
            .delete()
            .eq('id', appState.carritoActual)
            .eq('status', 'carrito');
      } catch (e) {
        debugPrint('Error clearing remote cart: $e');
      }
    }
    appState.carritoActual = '';
  }

  Future<void> removePurchasedItems(List<String> productIds) async {
    final appState = FFAppState();

    // 1. Eliminar localmente solo los productos comprados
    appState.itemsCarrito = appState.itemsCarrito
        .where((item) => !productIds.contains(item.idProducto))
        .toList();

    appState.itemsCarritoActual = appState.itemsCarritoActual
        .where((id) => !productIds.contains(id))
        .toList();

    // 2. Eliminar de Supabase (carrito activo)
    if (loggedIn && appState.carritoActual.isNotEmpty) {
      try {
        if (productIds.isNotEmpty) {
          await SupaFlow.client
              .from('pedido_items')
              .delete()
              .eq('pedido_id', appState.carritoActual)
              .inFilter('product_id', productIds);
        }

        // Verificar si quedan items en el carrito en la BD
        final remainingItems = await SupaFlow.client
            .from('pedido_items')
            .select('id')
            .eq('pedido_id', appState.carritoActual);

        if ((remainingItems as List).isEmpty) {
          // Si no quedan items, eliminamos el pedido con status 'carrito' para no dejar basura
          await SupaFlow.client
              .from('pedidos')
              .delete()
              .eq('id', appState.carritoActual)
              .eq('status', 'carrito');
          appState.carritoActual = '';
        }
      } catch (e) {
        debugPrint('Error removing purchased items from remote cart: $e');
      }
    } else if (appState.itemsCarrito.isEmpty) {
      appState.carritoActual = '';
    }
  }

  Future<void> fetchRemoteCart() async {
    final appState = FFAppState();
    final user = SupaFlow.client.auth.currentUser;
    if (user == null) return;

    try {
      // BUSCAMOS si ya existe un carrito activo en la DB en lugar de forzar la creación
      final response = await SupaFlow.client
          .from('pedidos')
          .select('id')
          .eq('user_id', user.id)
          .eq('status', 'carrito')
          .maybeSingle();

      if (response == null) {
        appState.carritoActual = "";
        appState.itemsCarrito = [];
        return;
      }

      String pedidoId = response['id'];
      appState.carritoActual = pedidoId;

      final items = await SupaFlow.client
          .from('pedido_items')
          .select()
          .eq('pedido_id', pedidoId);

      if ((items as List).isEmpty) {
        appState.itemsCarrito = [];
        return;
      }

      List<CarritoStruct> remoteItems = (items).map((row) {
        return CarritoStruct(
          idProducto: row['product_id'] as String,
          cantidad: row['quantity'] as int,
        );
      }).toList();

      appState.itemsCarrito = remoteItems;
    } catch (e) {
      debugPrint('Error fetching remote cart: $e');
    }
  }

  Future<void> syncGuestCartToRemote() async {
    final appState = FFAppState();
    final localItems = List<CarritoStruct>.from(appState.itemsCarrito);
    if (localItems.isEmpty) {
      await fetchRemoteCart();
      return;
    }

    try {
      final user = SupaFlow.client.auth.currentUser;
      if (user == null) return;

      // Verificamos si ya existe un carrito activo para no crear uno duplicado
      final existingCart = await SupaFlow.client
          .from('pedidos')
          .select('id')
          .eq('user_id', user.id)
          .eq('status', 'carrito')
          .maybeSingle();

      String pedidoId;
      if (existingCart != null) {
        pedidoId = existingCart['id'];
      } else {
        final newPedido = await SupaFlow.client
            .from('pedidos')
            .insert({
              'user_id': user.id,
              'status': 'carrito',
              'created_at': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        pedidoId = newPedido['id'];
      }

      appState.carritoActual = pedidoId;

      List<Map<String, dynamic>> itemsToInsert = localItems
          .map((item) => {
                'pedido_id': pedidoId,
                'product_id': item.idProducto,
                'quantity': item.cantidad,
              })
          .toList();

      await SupaFlow.client.from('pedido_items').insert(itemsToInsert);
      await fetchRemoteCart();
      debugPrint('Guest cart synced successfully');
    } catch (e) {
      debugPrint('Error syncing guest cart: $e');
    }
  }

  Future<void> _removeFromCart(List<String> productIds) async {
    final appState = FFAppState();

    // 1. Eliminar localmente
    appState.itemsCarrito = appState.itemsCarrito
        .where((i) => !productIds.contains(i.idProducto))
        .toList();

    // 2. Eliminar en Supabase (carrito activo)
    if (appState.carritoActual.isNotEmpty) {
      try {
        await SupaFlow.client
            .from('pedido_items')
            .delete()
            .eq('pedido_id', appState.carritoActual)
            .inFilter('product_id', productIds);
      } catch (e) {
        debugPrint('Error removing items from remote cart: $e');
      }
    }
  }

  void _updateLocalCart(String productId, int quantityChange) {
    final appState = FFAppState();
    List<CarritoStruct> currentItems = List.from(appState.itemsCarrito);
    int index = currentItems.indexWhere((item) => item.idProducto == productId);
    if (index != -1) {
      currentItems[index].cantidad += quantityChange;
      if (currentItems[index].cantidad <= 0) currentItems.removeAt(index);
    } else if (quantityChange > 0) {
      currentItems
          .add(CarritoStruct(idProducto: productId, cantidad: quantityChange));
    }
    appState.itemsCarrito = currentItems;
  }

  Future<String> _getOrCreateActiveCartId() async {
    final appState = FFAppState();
    if (appState.carritoActual.isNotEmpty) return appState.carritoActual;
    final user = SupaFlow.client.auth.currentUser!;

    try {
      // 1. Primero verificamos si ya existe un carrito activo en la DB
      final existingCart = await SupaFlow.client
          .from('pedidos')
          .select('id')
          .eq('user_id', user.id)
          .eq('status', 'carrito')
          .maybeSingle();

      if (existingCart != null) {
        String id = existingCart['id'];
        appState.carritoActual = id;
        return id;
      }

      // 2. Si no existe, recién ahí creamos uno nuevo
      final newPedido = await SupaFlow.client
          .from('pedidos')
          .insert({'user_id': user.id, 'status': 'carrito'})
          .select()
          .single();
      appState.carritoActual = newPedido['id'];
      return newPedido['id'];
    } catch (e) {
      debugPrint(
          'Error creating active cart (possible foreign key violation): $e');
      throw Exception(
          'User not found in database. Please re-login or contact support.');
    }
  }
}
