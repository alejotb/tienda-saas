import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/services/admin_service.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/pages/administracion/components/admin_order_mini_table.dart';
import 'package:baul_pandora/pages/administracion/components/admin_order_details_modal.dart';

class AdminDespachosPage extends StatefulWidget {
  const AdminDespachosPage({super.key});

  static String routeName = 'adminDespachos';
  static String routePath = '/adminDespachos';

  @override
  State<AdminDespachosPage> createState() => _AdminDespachosPageState();
}

class _AdminDespachosPageState extends State<AdminDespachosPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isLoading = true;
  List<PedidosRow> _confirmedOrders = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final orders = await AdminService.instance.getOrdersByStatus(AdminService.statusConfirmed);
      _confirmedOrders = orders;
    } catch (e) {
      debugPrint('Error cargando despachos: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _markAsDelivered(PedidosRow order) async {
    final success = await AdminService.instance.markAsDelivered(order.id);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido marcado como entregado')),
        );
        _fetchData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al marcar como entregado'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showOrderDetails(PedidosRow order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AdminOrderDetailsModal(pedidoId: order.id),
    );
  }

  Widget _buildActionButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        top: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopNavWidget(),
            Expanded(
              child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
                      child: Text(
                        'Pedidos a Despachar',
                        style: FlutterFlowTheme.of(context).headlineMedium,
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _confirmedOrders.isEmpty 
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text("No hay pedidos listos para despachar", style: TextStyle(fontSize: 16)),
                              )
                            )
                          : AdminOrderMiniTable<PedidosRow>(
                              title: 'Confirmados / Envíos',
                              items: _confirmedOrders,
                              columns: [
                                AdminTableColumn(header: 'Cliente', getValue: (o) => o.nombreCliente ?? 'Sin nombre', flex: 2),
                                AdminTableColumn(header: 'Dirección', getValue: (o) => o.shippingAddress?.toString() ?? 'No asignada', flex: 3),
                                AdminTableColumn(header: 'Total', getValue: (o) => '\$${o.totalPrice?.toStringAsFixed(2) ?? '0.00'}', flex: 1),
                              ],
                              actionButton: _buildActionButton(Icons.delivery_dining, Colors.blue),
                              onActionPressed: _markAsDelivered,
                              onOrderTap: (order) => _showOrderDetails(order),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
