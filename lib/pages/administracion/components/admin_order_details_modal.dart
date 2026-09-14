import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:intl/intl.dart';
import 'package:baul_pandora/services/admin_service.dart';

class AdminOrderDetailsModal extends StatelessWidget {
  final String pedidoId;

  const AdminOrderDetailsModal({super.key, required this.pedidoId});

  Future<Map<String, dynamic>> _fetchOrderFullDetails() async {
    // 1. Get basic order info
    final orderList = await PedidosTable().querySingleRow(queryFn: (q) => q.eq('id', pedidoId));
    final order = orderList.isNotEmpty ? orderList.first : null;

    // 2. Get items
    final items = await PedidoItemsTable().queryRows(queryFn: (q) => q.eq('pedido_id', pedidoId));
    
    // Get product names for each item
    List<Map<String, dynamic>> detailedItems = [];
    for (var item in items) {
      final prodRows = await ProductosTable().queryRows(queryFn: (q) => q.eq('id', item.productId!));
      final prod = prodRows.isNotEmpty ? prodRows.first : null;
      detailedItems.add({
        'nombre': prod?.nombre ?? 'Producto desconocido',
        'cantidad': item.quantity,
        'precio': item.priceAtPurchase,
      });
    }

    // 3. Get payment info and AI data
    final payment = await SupaFlow.client
        .from('pagos')
        .select()
        .eq('pedido_id', pedidoId)
        .maybeSingle();

    return {
      'order': order,
      'items': detailedItems,
      'payment': payment,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchOrderFullDetails(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Error al cargar detalles del pedido'));
        }

        final order = snapshot.data!['order'] as PedidosRow?;
        if (order == null) {
          return const Center(child: Text('Pedido no encontrado'));
        }
        
        final items = snapshot.data!['items'] as List<Map<String, dynamic>>;
        final payment = snapshot.data!['payment'] as Map<String, dynamic>?;
        final aiData = payment?['ai_data'] as Map<String, dynamic>?;

        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).primaryBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).alternate,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detalles del Pedido',
                      style: FlutterFlowTheme.of(context).titleLarge,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.status?.toUpperCase() ?? 'S/E',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Customer Section
                _buildSectionTitle(context, 'Información del Cliente'),
                _buildDetailRow(context, 'Cliente', order.nombreCliente ?? 'No disponible'),
                _buildDetailRow(context, 'Email', order.emailCliente ?? 'No disponible'),
                _buildDetailRow(context, 'Fecha', DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)),
                const SizedBox(height: 16),

                // Shipping Section
                _buildSectionTitle(context, 'Datos de Envío'),
                _buildDetailRow(context, 'Dirección', order.shippingAddress?.toString() ?? 'No disponible'),
                const SizedBox(height: 16),

                // Items Section
                _buildSectionTitle(context, 'Productos'),
                Container(
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        title: Text(item['nombre'], style: FlutterFlowTheme.of(context).bodyMedium),
                        trailing: Text(
                          '${item['cantidad']} x \$${item['precio']}',
                          style: FlutterFlowTheme.of(context).bodySmall,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Payment & AI Section
                _buildSectionTitle(context, 'Información de Pago'),
                if (payment == null) ...[
                  const Text('No hay registro de pago para este pedido', style: TextStyle(color: Colors.grey)),
                ] else ...[
                  _buildDetailRow(context, 'Monto', '\$${payment['monto']}'),
                  _buildDetailRow(context, 'Moneda', payment['moneda']),
                  if (payment['comprobante_url'] != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: InkWell(
                        onTap: () => _launchURL(payment['comprobante_url']),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: FlutterFlowTheme.of(context).primary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.image, size: 20),
                              const SizedBox(width: 8),
                              Text('Ver comprobante', style: FlutterFlowTheme.of(context).bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (aiData != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.psychology, size: 18, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text('Análisis IA (Gemini)', style: FlutterFlowTheme.of(context).bodySmall.override(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(),
                          _buildAiRow('Estado', aiData['valido'] == true ? 'Válido' : 'Sospechoso'),
                          _buildAiRow('Monto Detectado', '\$${aiData['monto']}'),
                          _buildAiRow('Referencia', aiData['referencia'] ?? 'No detectada'),
                          _buildAiRow('Fecha', aiData['fecha'] ?? 'No detectada'),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                    ],
                  ),
                ),
                ), // Closes Expanded
                // Botones de acciA3n
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final success = await AdminService.instance.confirmOrder(pedidoId);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido confirmado')));
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Confirmar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final success = await AdminService.instance.rejectOrder(pedidoId, reason: 'Error en la comprobación del pago');
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido rechazado')));
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Rechazar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: FlutterFlowTheme.of(context).titleSmall.override(
          fontFamily: 'Inter',
          fontWeight: FontWeight.bold,
          color: FlutterFlowTheme.of(context).primary,
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: FlutterFlowTheme.of(context).bodySmall),
          Text(value.toString(), style: FlutterFlowTheme.of(context).bodyMedium.override(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildAiRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _launchURL(String url) {
    // Implementación simplificada para el ejemplo
    // En una app real usaríamos url_launcher
    print('Lanzando URL del comprobante: $url');
  }
}
