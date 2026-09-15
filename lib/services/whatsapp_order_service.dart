import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/flutter_flow/random_data_util.dart' as random_data;

class WhatsAppOrderCustomerInfo {
  final String name;
  final String phone;
  final String deliveryType; // 'domicilio' o 'retiro'
  final String? address;
  final String paymentMethod;
  final String? paymentReference;
  final String? notes;

  WhatsAppOrderCustomerInfo({
    required this.name,
    required this.phone,
    this.deliveryType = 'domicilio',
    this.address,
    required this.paymentMethod,
    this.paymentReference,
    this.notes,
  });
}

class WhatsAppOrderItem {
  final String id;
  final String nombre;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  WhatsAppOrderItem({
    required this.id,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory WhatsAppOrderItem.fromMap(Map<String, dynamic> map) {
    final qty = (map['cantidad'] as num?)?.toInt() ?? 1;
    final price = (map['precio'] as num?)?.toDouble() ?? 0.0;
    final sub = (map['subtotal'] as num?)?.toDouble() ?? (qty * price);

    return WhatsAppOrderItem(
      id: map['id']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? 'Producto',
      cantidad: qty,
      precioUnitario: price,
      subtotal: sub,
    );
  }
}

class WhatsAppOrderService {
  static final WhatsAppOrderService instance = WhatsAppOrderService._internal();
  WhatsAppOrderService._internal();

  /// Limpia y formatea el número de WhatsApp para enlace universal wa.me
  String cleanPhoneNumber(String rawPhone) {
    String cleaned = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');

    // Formato Venezuela (0412, 0414, 0424, 0416, 0426) -> 58412...
    if (cleaned.startsWith('0') && cleaned.length == 11) {
      cleaned = '58${cleaned.substring(1)}';
    } else if (cleaned.length == 10 && (cleaned.startsWith('412') || cleaned.startsWith('414') || cleaned.startsWith('424') || cleaned.startsWith('416') || cleaned.startsWith('426'))) {
      cleaned = '58$cleaned';
    }

    return cleaned;
  }

  /// Construye el mensaje de texto estructurado y formateado para WhatsApp
  String formatOrderMessage({
    required String storeName,
    required String orderNumber,
    required List<WhatsAppOrderItem> items,
    required double totalUsd,
    double? bcvRate,
    required WhatsAppOrderCustomerInfo customer,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('🛍️ *NUEVO PEDIDO - $storeName*');
    buffer.writeln('📋 *Pedido:* #$orderNumber');
    buffer.writeln('📅 *Fecha:* ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    buffer.writeln('----------------------------------');
    buffer.writeln('📦 *PRODUCTOS:*');

    for (final item in items) {
      buffer.writeln('• ${item.cantidad}x ${item.nombre} (\$${item.precioUnitario.toStringAsFixed(2)} c/u) = *\$${item.subtotal.toStringAsFixed(2)}*');
    }

    buffer.writeln('----------------------------------');
    buffer.writeln('💰 *TOTAL:* \$${totalUsd.toStringAsFixed(2)} USD');

    if (bcvRate != null && bcvRate > 0) {
      final totalBs = totalUsd * bcvRate;
      buffer.writeln('🇻🇪 *Equivalente en Bs:* Bs. ${totalBs.toStringAsFixed(2)} (Tasa: $bcvRate)');
    }

    buffer.writeln('----------------------------------');
    buffer.writeln('📍 *DATOS DE ENTREGA & CLIENTE:*');
    buffer.writeln('👤 *Nombre:* ${customer.name}');
    buffer.writeln('📞 *Teléfono:* ${customer.phone}');
    buffer.writeln('🚚 *Tipo:* ${customer.deliveryType == 'retiro' ? 'Retiro en Tienda' : 'Envío a Domicilio'}');

    if (customer.deliveryType != 'retiro' && customer.address != null && customer.address!.isNotEmpty) {
      buffer.writeln('🏠 *Dirección:* ${customer.address}');
    }

    buffer.writeln('💳 *Método de Pago:* ${customer.paymentMethod}');

    if (customer.paymentReference != null && customer.paymentReference!.isNotEmpty) {
      buffer.writeln('🔢 *Referencia:* ${customer.paymentReference}');
    }

    if (customer.notes != null && customer.notes!.isNotEmpty) {
      buffer.writeln('📝 *Notas:* ${customer.notes}');
    }

    buffer.writeln('----------------------------------');
    buffer.writeln('✅ *¡Por favor confirma la disponibilidad y datos de pago para procesar mi orden!*');

    return buffer.toString();
  }

  /// Crea el pedido en Supabase vinculado a la tienda y abre WhatsApp
  Future<bool> submitAndOpenWhatsApp({
    required String storeId,
    required String storeName,
    required String? storePhone,
    required List<WhatsAppOrderItem> items,
    required double totalUsd,
    double? bcvRate,
    required WhatsAppOrderCustomerInfo customer,
  }) async {
    final orderNum = random_data.randomInteger(1000, 9999).toString();

    // 1. Guardar el pedido en Supabase
    String? pedidoId;
    try {
      final paymentDetails = {
        'metodo': customer.paymentMethod,
        'referencia': customer.paymentReference ?? '',
        'canal': 'whatsapp',
        'cliente_nombre': customer.name,
        'cliente_telefono': customer.phone,
        'notas': customer.notes ?? '',
      };

      final shippingAddress = {
        'nombre_receptor': customer.name,
        'telefono': customer.phone,
        'tipo_entrega': customer.deliveryType,
        'direccion': customer.address ?? 'Retiro en Tienda',
      };

      final newPedido = await SupaFlow.client.from('pedidos').insert({
        'user_id': currentUserUid.isNotEmpty ? currentUserUid : null,
        'tienda_id': storeId.isNotEmpty ? storeId : null,
        'status': 'pendiente',
        'total_price': totalUsd,
        'paid_amount_usd': 0.0,
        'shipping_address': shippingAddress,
        'datos_pago': paymentDetails,
        'pedido_nombre': 'Order #$orderNum (WhatsApp)',
        'created_at': DateTime.now().toIso8601String(),
      }).select('id').single();

      pedidoId = newPedido['id']?.toString();

      // Guardar ítems del pedido
      if (pedidoId != null) {
        final itemsToInsert = items.map((item) => {
          'pedido_id': pedidoId,
          'product_id': item.id,
          'quantity': item.cantidad,
          'price_at_purchase': item.precioUnitario,
        }).toList();

        await SupaFlow.client.from('pedido_items').insert(itemsToInsert);
      }
    } catch (e) {
      debugPrint('Nota: Guardado de pedido WhatsApp en Supabase: $e');
    }

    // 2. Formatear y abrir WhatsApp
    final message = formatOrderMessage(
      storeName: storeName,
      orderNumber: orderNum,
      items: items,
      totalUsd: totalUsd,
      bcvRate: bcvRate,
      customer: customer,
    );

    final rawPhone = (storePhone != null && storePhone.isNotEmpty) ? storePhone : '584120000000';
    final targetPhone = cleanPhoneNumber(rawPhone);
    final url = 'https://wa.me/$targetPhone?text=${Uri.encodeComponent(message)}';

    try {
      final uri = Uri.parse(url);
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error abriendo enlace de WhatsApp: $e');
      return false;
    }
  }
}
