import 'package:baul_pandora/backend/supabase/database/tables/pedido_items.dart';
import 'package:baul_pandora/backend/supabase/database/tables/pedidos.dart';
import 'package:baul_pandora/backend/supabase/database/tables/productos.dart';
import 'package:baul_pandora/backend/supabase/database/tables/usuarios.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/services/woocommerce_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminGeneralView extends StatefulWidget {
  const AdminGeneralView({super.key});

  @override
  State<AdminGeneralView> createState() => _AdminGeneralViewState();
}

class _AdminGeneralViewState extends State<AdminGeneralView> {
  double _totalSales = 0.0;
  int _pendingOrders = 0;
  int _newUsersCount = 0;
  int _totalProductsCount = 0;
  List<Map<String, dynamic>> _topProducts = [];
  bool _isLoading = true;
  bool _isSyncing = false;



  @override

  void initState() {

    super.initState();

    _loadDashboardData();

  }



  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchSalesData(),
        _fetchUsersData(),
        _fetchTopProducts(),
        _fetchProductCount(),
      ]);

    } catch (e) {

      debugPrint('Error loading dashboard data: $e');

    } finally {

      setState(() => _isLoading = false);

    }

  }



  Future<void> _fetchProductCount() async {

    final products = await ProductosTable().queryRows(queryFn: (q) => q);

    setState(() {

      _totalProductsCount = products.length;

    });

  }



  Future<void> _fetchSalesData() async {

    final paidOrders = await PedidosTable().queryRows(

      queryFn: (q) => q.inFilter('status', ['pendiente', 'pagado', 'confirmado', 'completado']),

    );

    

    final pendingOrders = await PedidosTable().queryRows(

      queryFn: (q) => q.inFilter('status', ['pendiente', 'pendiente_pago', 'pagado', 'pendiente_apartados', 'apartado']),

    );



    double sum = 0;

    for (var order in paidOrders) {

      sum += order.totalPrice ?? 0.0;

    }



    setState(() {

      _totalSales = sum;

      _pendingOrders = pendingOrders.length;

    });

  }



  Future<void> _fetchUsersData() async {

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

    final newUsers = await UsuariosTable().queryRows(

      queryFn: (q) => q.gte('created_at', thirtyDaysAgo.toIso8601String()),

    );



    setState(() {

      _newUsersCount = newUsers.length;

    });

  }



  Future<void> _fetchTopProducts() async {
    // 1. Get all order IDs that are confirmed or completed
    final validOrders = await PedidosTable().queryRows(
      queryFn: (q) => q.filter('status', 'in', ['confirmado', 'completado']),
    );

    if (validOrders.isEmpty) {
      setState(() {
        _topProducts = [];
      });
      return;
    }

    final validOrderIds = validOrders.map((o) => o.id).toList();

    // 2. Get only items belonging to those valid orders
    final items = await PedidoItemsTable().queryRows(
      queryFn: (q) => q.filter('pedido_id', 'in', validOrderIds),
    );

    Map<String, int> productCounts = {};
    for (var item in items) {
      if (item.productId != null) {
        productCounts[item.productId!] = (productCounts[item.productId!] ?? 0) + (item.quantity?.toInt() ?? 1);
      }
    }

    var sortedEntries = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Map<String, dynamic>> topList = [];
    for (var entry in sortedEntries.take(5)) {
      final productList = await ProductosTable().queryRows(
        queryFn: (q) => q.eq('id', entry.key),
      );

      if (productList.isNotEmpty) {
        final product = productList.first;
        topList.add({
          'name': product.nombre,
          'quantity': entry.value,
          'image': ((product.imagePath?.length ?? 0) > 0)
              ? product.imagePath?.firstOrNull ?? ''
              : '',
        });
      }
    }

    setState(() {
      _topProducts = topList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading 
      ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel de Control',
                  style: FlutterFlowTheme.of(context).headlineMedium.override(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // KPI Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Determine how many columns based on available width
                    int crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
                    double spacing = 16;
                    // Calculate width per card
                    double cardWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        _buildKpiCard('Ventas Totales', '\$${_totalSales.toStringAsFixed(2)}', Icons.attach_money_rounded, Colors.green, cardWidth),
                        _buildKpiCard('Pedidos Pendientes', '$_pendingOrders', Icons.pending_actions_rounded, Colors.orange, cardWidth),
                        _buildKpiCard('Nuevos Usuarios (30d)', '$_newUsersCount', Icons.person_add_alt_1_rounded, Colors.blue, cardWidth),
                        _buildKpiCard('Total Productos', '$_totalProductsCount', Icons.inventory_2_rounded, Colors.teal, cardWidth),
                      ],
                    );
                  }
                ),

                const SizedBox(height: 32),

                Text(
                  'Productos Más Vendidos',
                  style: FlutterFlowTheme.of(context).titleLarge.override(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _topProducts.isEmpty 
                  ? const Text('No hay datos de ventas disponibles')
                  : Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(8),
                          itemCount: _topProducts.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final product = _topProducts[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(product['image'] ?? ''),
                              ),
                              title: Text(product['name'], style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                              trailing: Text(
                                '${product['quantity']} unidades',
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                const SizedBox(height: 32),
                
                // Quick Actions
                Text(
                  'Acciones Rápidas',
                  style: FlutterFlowTheme.of(context).titleLarge.override(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_isSyncing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      '⏳ Sincronizando catálogo directamente en la base de datos de Supabase...',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            fontFamily: 'Inter',
                            color: FlutterFlowTheme.of(context).primary,
                            fontWeight: FontWeight.w600,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSyncing ? null : () async {
                      setState(() {
                        _isSyncing = true;
                      });
                      try {
                        final result = await WooCommerceSyncService().syncAllProducts();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result.message,
                                style: const TextStyle(fontSize: 13, height: 1.3),
                              ),
                              backgroundColor: result.success ? const Color(0xFF16A34A) : Colors.red,
                              duration: const Duration(seconds: 5),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                        _loadDashboardData();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error en sincronización: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setState(() {
                            _isSyncing = false;
                          });
                        }
                      }
                    },
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.sync),
                    label: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar Inventario Ahora'),

                    style: ElevatedButton.styleFrom(

                      padding: const EdgeInsets.symmetric(vertical: 16),

                      backgroundColor: FlutterFlowTheme.of(context).primary,

                      foregroundColor: FlutterFlowTheme.of(context).primaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.pushNamed('adminAuditoria'),
                    icon: const Icon(Icons.manage_history_rounded),
                    label: const Text('Ver Auditoría de Movimientos'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: FlutterFlowTheme.of(context).primaryText,
                      side: BorderSide(color: FlutterFlowTheme.of(context).alternate),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),

          ),

    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, double width) {

    return SizedBox(

      width: width,

      child: Container(

        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(

          color: FlutterFlowTheme.of(context).secondaryBackground,

          borderRadius: BorderRadius.circular(16),

          border: Border.all(color: FlutterFlowTheme.of(context).alternate),

        ),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Icon(icon, color: color, size: 32),

            const SizedBox(height: 12),

            Text(title, style: FlutterFlowTheme.of(context).bodySmall),

            const SizedBox(height: 4),

            Text(value, style: FlutterFlowTheme.of(context).titleLarge.override(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

