import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_widgets.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/custom_functions.dart' as functions;
import 'package:baul_pandora/flutter_flow/random_data_util.dart' as random_data;
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/pages/success_page/success_page_widget.dart';
import 'package:baul_pandora/services/cart_service.dart';
import '../checkout_full_page_model.dart';

class CheckoutFooterAction extends StatefulWidget {
  const CheckoutFooterAction({
    super.key,
    required this.model,
    this.onUpdate,
  });

  final CheckoutFullPageModel model;
  final VoidCallback? onUpdate;

  @override
  State<CheckoutFooterAction> createState() => _CheckoutFooterActionState();
}

class _CheckoutFooterActionState extends State<CheckoutFooterAction> {
  @override
  Widget build(BuildContext context) {
    return FFButtonWidget(
      onPressed: () async {
        debugPrint('DEBUG: Botón Finalizar Compra presionado');
        final currentContext = context; // Capturamos el contexto
        if (!widget.model.isOrderReady) {
          String message = 'Por favor, completa la información necesaria.';
          if (!widget.model.isValidLocation) {
            message = 'Por favor, completa la dirección de envío.';
          } else if (!widget.model.isValidShipping) {
            message = 'Por favor, selecciona un método de envío.';
          } else if (!widget.model.isValidPayment) {
            message = 'Por favor, completa los datos de pago.';
          }

          if (!mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: FlutterFlowTheme.of(currentContext).titleMedium.override(
                      font: GoogleFonts.interTight(
                        fontWeight: FlutterFlowTheme.of(currentContext).titleMedium.fontWeight,
                        fontStyle: FlutterFlowTheme.of(currentContext).titleMedium.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(currentContext).primaryText,
                      letterSpacing: 0.0,
                    ),
              ),
              duration: const Duration(milliseconds: 4000),
              backgroundColor: FlutterFlowTheme.of(currentContext).primary,
            ),
          );
          return;
        }

        // 1. Calcular Totales (solo productos)
        double subtotal = 0.0;
        for (var item in (widget.model.productosSeleccionados as List<dynamic>)) {
          final precio = (item['precio'] as num?)?.toDouble() ?? 0.0;
          final cantidad = (item['cantidad'] as num?)?.toDouble() ?? 0.0;
          subtotal += (precio * cantidad);
        }
        
        // Restar saldo de apartados si existe
        final saldoApartados = widget.model.saldoApartados ?? 0.0;
        double totalFinal = subtotal - saldoApartados;
        if (totalFinal < 0) totalFinal = 0.0;

        // 2. Formatear Dirección según el tipo de entrega
        String finalShippingAddress = '';
        if (widget.model.deliveryType == 'Casa') {
          // Buscamos la dirección destacada
          final addr = widget.model.direccionesGuardadas.firstWhere(
            (a) => a.defaultAddress == true,
            orElse: () => widget.model.address ?? widget.model.direccionesGuardadas.first,
          );
          
          final parts = [addr.address, addr.city, addr.state, addr.postalCode.toString()]
              .where((e) => e != null && e.isNotEmpty && e != '0');
          finalShippingAddress = 'Casa: ${parts.join(", ")}';
        } else if (widget.model.deliveryType == 'Oficina') {
          // Limpiar si ya tiene el prefijo para evitar duplicados
          String agencyName = widget.model.selectedAgency ?? '';
          if (agencyName.startsWith('Oficina: ')) {
            agencyName = agencyName.replaceFirst('Oficina: ', '');
          }
          final code = (widget.model.featuredAgencyCode?.isNotEmpty == true)
              ? widget.model.featuredAgencyCode!
              : (widget.model.address?.agencia ?? '');
          final codeStr = code.isNotEmpty ? ' (Cod: $code)' : '';
          finalShippingAddress = 'Oficina: $agencyName$codeStr';
        } else {
          finalShippingAddress = 'Persona: ${widget.model.personNameController.text} - Tel: ${widget.model.personPhoneController.text}';
        }

        // 3. Preparar Datos de Pago
        final paymentDetails = functions.prepararJsonPago(widget.model.pago);
        
        final isPagoMovil = (widget.model.pago?.tipo?.toLowerCase().contains('móvil') == true || 
                              widget.model.pago?.tipo?.toLowerCase().contains('movil') == true);

        // 🆕 NUEVA VALIDACIÓN DE STOCK (Centralizada)
        final mensajesAjuste = await CartService.instance.validateAndAdjustStock(
            widget.model.productosSeleccionados as List<dynamic>);

        if (mensajesAjuste.isNotEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Atención: Se han ajustado cantidades por falta de stock:\n${mensajesAjuste.join(", ")}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        // ------------------------------------

        try {
          // 1. Identificar y separar ítems
          final productosNuevos = (widget.model.productosSeleccionados as List<dynamic>)
              .where((item) => item['pedido_id'] == null)
              .toList();
          final productosApartados = (widget.model.productosSeleccionados as List<dynamic>)
              .where((item) => item['pedido_id'] != null)
              .toList();
          
          final Set<String> pedidosApartadosIds = productosApartados
              .map((p) => p['pedido_id'].toString())
              .toSet();

          List<String> todosLosPedidosIds = [];

          // 2. Procesar productos nuevos (INSERT)
          if (productosNuevos.isNotEmpty) {
            final newPedido = await SupaFlow.client.from('pedidos').insert({
              'user_id': currentUserUid.isEmpty ? null : currentUserUid,
              'status': (widget.model.pago?.tipo == 'Efectivo') ? 'pendiente_pago' : 'pagado',
              'total_price': totalFinal,
              'paid_amount_usd': isPagoMovil ? 0.0 : totalFinal, // Guardar monto USD si no es Pago Móvil
              'shipping_address': finalShippingAddress,
              'datos_pago': paymentDetails,
              'created_at': DateTime.now().toIso8601String(),
              'pedido_nombre': 'Order #${random_data.randomInteger(1000, 9999)}',
            }).select('id').single();

            final String nuevoPedidoId = newPedido['id'] as String;
            todosLosPedidosIds.add(nuevoPedidoId);

            // INSERTAR MOVIMIENTO EN INVENTARIO
            final List<Map<String, dynamic>> inventoryLogs = productosNuevos.map((item) => {
                  'producto_id': item['id'],
                  'usuario_id': currentUserUid,
                  'cantidad': -(item['cantidad'] as int),
                  'tipo_operacion': 'venta',
                  'notas': 'Venta desde carrito: Pedido #$nuevoPedidoId',
                  'created_at': DateTime.now().toIso8601String(),
            }).toList();
            await SupaFlow.client.from('inventory_logs').insert(inventoryLogs);

            final itemsToInsert = productosNuevos.map((item) => {
                  'pedido_id': nuevoPedidoId,
                  'product_id': item['id'],
                  'quantity': item['cantidad'],
                  'price_at_purchase': item['precio'],
                }).toList();
            
            await SupaFlow.client.from('pedido_items').insert(itemsToInsert);
          }

          // 3. Procesar pedidos apartados (UPDATE)
          for (final pedidoId in pedidosApartadosIds) {
            await SupaFlow.client.from('pedidos').update({
              'status': 'pagado',
            }).eq('id', pedidoId);
            todosLosPedidosIds.add(pedidoId);

            // INSERTAR MOVIMIENTO EN INVENTARIO (LIQUIDACIÓN)
            final productosApartadosPedido = productosApartados
                .where((item) => item['pedido_id'].toString() == pedidoId);
            
            final List<Map<String, dynamic>> inventoryLogsApartados = productosApartadosPedido.map((item) => {
                  'producto_id': item['id'],
                  'usuario_id': currentUserUid,
                  'cantidad': -(item['cantidad'] as int),
                  'tipo_operacion': 'liquidacion_apartado',
                  'notas': 'Liquidación de apartado: Pedido #$pedidoId',
                  'created_at': DateTime.now().toIso8601String(),
            }).toList();
            await SupaFlow.client.from('inventory_logs').insert(inventoryLogsApartados);
          }

          // 4. Registrar el Pago
          final rate = widget.model.bcvRate ?? 1.0;
          final montoIngresado = widget.model.pago?.montoUsd ?? 0.0;

          final currentUserObj = SupaFlow.client.auth.currentUser;
          String emisorNombre = widget.model.pago?.nombre ?? '';
          if (emisorNombre.isEmpty || emisorNombre == 'Anónimo') {
            if (currentUserObj != null) {
              emisorNombre = currentUserObj.userMetadata?['full_name'] as String? ?? '';
              if (emisorNombre.isEmpty) {
                try {
                  final userRow = await SupaFlow.client.from('usuarios').select('nombre').eq('id', currentUserObj.id).maybeSingle();
                  if (userRow != null && userRow['nombre'] != null) {
                    emisorNombre = userRow['nombre'] as String;
                  }
                } catch (_) {}
              }
            }
          }
          if (emisorNombre.isEmpty) emisorNombre = 'Anónimo';

          String emisorEmail = widget.model.pago?.email ?? '';
          if (emisorEmail.isEmpty || emisorEmail == 'N/A') {
            if (currentUserObj != null) {
              emisorEmail = currentUserObj.email ?? 'N/A';
            }
          }
          if (emisorEmail.isEmpty) emisorEmail = 'N/A';
          
          final pagoResult = await SupaFlow.client.from('pagos').insert({
            'monto': totalFinal,
            'amount_usd_calculated': isPagoMovil ? (montoIngresado / rate) : montoIngresado,
            'amount_ves': isPagoMovil ? montoIngresado : (montoIngresado * rate),
            'exchange_rate_applied': rate,
            'tipo': widget.model.pago?.tipo,
            'referencia': widget.model.pago?.referencia,
            'comprobante_url': widget.model.pago?.comprobanteUrl,
            'nombre_emisor': emisorNombre,
            'email_emisor': emisorEmail,
            'estado': 'pendiente',
            'fecha_pago': DateTime.now().toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            'telefono_emisor': widget.model.pago?.numeroTelefono,
            'banco_emisor': widget.model.pago?.bancoEnviado,
            'banco_receptor': 'El Baúl de Pandora',
            'moneda': isPagoMovil ? 'VES' : 'USD',
            'pedido_id': todosLosPedidosIds.isNotEmpty ? todosLosPedidosIds.first : null,
          }).select('id').single();

          final String nuevoPagoId = pagoResult['id'] as String;

          // 5. Vincular Pago con Pedidos (Tabla intermedia: pagos_pedidos)
          final relacionesPagoPedido = todosLosPedidosIds.map((pedidoId) => {
            'pago_id': nuevoPagoId,
            'pedido_id': pedidoId,
          }).toList();

          await SupaFlow.client.from('pago_pedidos').insert(relacionesPagoPedido);

          // ... (resto del código: limpiar carrito, preferencias, redirigir)


          // 4. Limpiar del carrito solo los productos comprados
          final productosCompradosIds = productosNuevos.map((p) => p['id'].toString()).toList();
          await CartService.instance.removePurchasedItems(productosCompradosIds);
          setState(() {});
          
          // 5. Persistir preferencias del usuario (Direcciones)
          await widget.model.saveUserPreferences();

          // 5. Redirigir al éxito
          context.pushNamed(
            SuccessPageWidget.routeName,
            queryParameters: {
              'orderTotal': serializeParam(totalFinal, ParamType.double),
            }.withoutNulls,
          );
        } catch (e, stackTrace) {
          debugPrint('DEBUG: Error capturado al procesar el nuevo pedido: $e');
          debugPrint('DEBUG: StackTrace: $stackTrace');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al procesar el pedido: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 6),
              ),
            );
          }
        }

        safeSetState(() {});
      },

      text: 'Finalizar Compra',
      options: FFButtonOptions(
        width: double.infinity,
        height: 48.0,
        padding: const EdgeInsets.all(0.0),
        iconPadding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
        color: FlutterFlowTheme.of(context).primary,
        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
              font: GoogleFonts.interTight(
                fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
              ),
              letterSpacing: 0.0,
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
    );
  }
}
