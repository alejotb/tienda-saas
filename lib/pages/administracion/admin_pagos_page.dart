import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:baul_pandora/components/top_nav/top_nav_widget.dart';
import 'package:baul_pandora/services/admin_service.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/pages/administracion/components/admin_payment_card.dart';
import 'package:baul_pandora/pages/administracion/components/admin_order_details_modal.dart';

class AdminPagosPage extends StatefulWidget {
  const AdminPagosPage({super.key});

  static String routeName = 'adminPagos';
  static String routePath = '/adminPagos';

  @override
  State<AdminPagosPage> createState() => _AdminPagosPageState();
}

class _AdminPagosPageState extends State<AdminPagosPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<PedidosRow> _ordersToConfirm = [];
  List<PedidosRow> _apartadosToConfirm = [];

  // Filtros y ordenamiento
  String _selectedMethod = 'todos';
  String _sortBy = 'date_desc'; // 'date_desc', 'date_asc', 'amount_desc', 'amount_asc'
  String _searchQuery = '';
  bool _groupByDate = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchOrdersToConfirm(),
        _fetchApartadosToConfirm(),
      ]);
    } catch (e) {
      debugPrint('Error cargando pagos: ');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchOrdersToConfirm() async {
    final orders = await AdminService.instance.getOrdersByStatus(AdminService.statusNormalConfirm);
    _ordersToConfirm = orders;
  }

  Future<void> _fetchApartadosToConfirm() async {
    final orders = await AdminService.instance.getOrdersByStatus(AdminService.statusApartadoConfirm);
    _apartadosToConfirm = orders;
  }

  void _confirmOrder(PedidosRow order) async {
    final success = await AdminService.instance.confirmOrder(order.id);
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago aprobado y pedido confirmado con éxito'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al confirmar el pago'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _promptRejectOrder(PedidosRow order) {
    final TextEditingController reasonController = TextEditingController();
    String selectedPreset = 'Referencia no encontrada';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('Rechazar Pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selecciona o escribe el motivo para notificar al cliente:',
                  style: FlutterFlowTheme.of(context).bodySmall),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedPreset,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'Referencia no encontrada', child: Text('Referencia no encontrada')),
                  DropdownMenuItem(value: 'Monto recibido incompleto', child: Text('Monto recibido incompleto')),
                  DropdownMenuItem(value: 'Comprobante ilegible / borroso', child: Text('Comprobante ilegible / borroso')),
                  DropdownMenuItem(value: 'Banco o titular no coincide', child: Text('Banco o titular no coincide')),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro motivo...')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedPreset = val);
                  }
                },
              ),
              if (selectedPreset == 'Otro') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    hintText: 'Detalla el motivo...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  maxLines: 2,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = selectedPreset == 'Otro'
                    ? (reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : 'Pago no verificado')
                    : selectedPreset;
                Navigator.of(ctx).pop();

                final success = await AdminService.instance.rejectOrder(order.id, reason: reason);
                if (context.mounted) {
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pago rechazado correctamente'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    _fetchData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al rechazar el pago'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Rechazar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(PedidosRow order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminOrderDetailsModal(pedidoId: order.id),
    );
  }

  String _extractPaymentType(PedidosRow order) {
    if (order.datosPago == null) return 'otro';
    if (order.datosPago is Map) {
      final map = order.datosPago as Map;
      final raw = (map['tipo'] ?? map['tipo_pago'] ?? map['metodo'] ?? '').toString().toLowerCase();
      if (raw.contains('movil') || raw.contains('móvil') || raw.contains('pago_movil')) return 'pago_movil';
      if (raw.contains('binance') || raw.contains('usdt')) return 'binance';
      if (raw.contains('paypal')) return 'paypal';
      if (raw.contains('zelle')) return 'zelle';
      if (raw.contains('efectivo') || raw.contains('cash')) return 'efectivo';
      if (raw.contains('transfer') || raw.contains('banco')) return 'transferencia';
      return raw;
    }
    return 'otro';
  }

  List<PedidosRow> _filterAndSortOrders(List<PedidosRow> sourceList) {
    List<PedidosRow> list = List.from(sourceList);

    // 1. Filtrar por método de pago
    if (_selectedMethod != 'todos') {
      list = list.where((order) {
        final type = _extractPaymentType(order);
        if (_selectedMethod == 'pago_movil') return type == 'pago_movil';
        if (_selectedMethod == 'binance') return type == 'binance';
        if (_selectedMethod == 'paypal') return type == 'paypal';
        if (_selectedMethod == 'zelle') return type == 'zelle';
        if (_selectedMethod == 'otros') return type != 'pago_movil' && type != 'binance' && type != 'paypal' && type != 'zelle';
        return true;
      }).toList();
    }

    // 2. Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      list = list.where((order) {
        final name = (order.nombreCliente ?? '').toLowerCase();
        final email = (order.emailCliente ?? '').toLowerCase();
        final id = order.id.toLowerCase();
        
        String ref = '';
        String telf = '';
        if (order.datosPago is Map) {
          final map = order.datosPago as Map;
          ref = (map['referencia'] ?? map['ref'] ?? '').toString().toLowerCase();
          telf = (map['numeroTelefono'] ?? map['numero_telefono'] ?? map['telefono'] ?? '').toString().toLowerCase();
        }

        return name.contains(query) ||
            email.contains(query) ||
            id.contains(query) ||
            ref.contains(query) ||
            telf.contains(query);
      }).toList();
    }

    // 3. Ordenar
    list.sort((a, b) {
      switch (_sortBy) {
        case 'date_asc':
          return a.createdAt.compareTo(b.createdAt);
        case 'amount_desc':
          final amountA = a.totalPrice ?? a.total ?? 0.0;
          final amountB = b.totalPrice ?? b.total ?? 0.0;
          return amountB.compareTo(amountA);
        case 'amount_asc':
          final amountA = a.totalPrice ?? a.total ?? 0.0;
          final amountB = b.totalPrice ?? b.total ?? 0.0;
          return amountA.compareTo(amountB);
        case 'date_desc':
        default:
          return b.createdAt.compareTo(a.createdAt);
      }
    });

    return list;
  }

  Map<String, List<PedidosRow>> _groupOrdersByDate(List<PedidosRow> orders) {
    final Map<String, List<PedidosRow>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var order in orders) {
      final orderDate = DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day);
      String groupKey;

      if (orderDate == today) {
        groupKey = 'Hoy';
      } else if (orderDate == yesterday) {
        groupKey = 'Ayer';
      } else {
        groupKey = DateFormat("EEEE, d 'de' MMMM", 'es_VE').format(order.createdAt);
        // Capitalize first letter
        if (groupKey.isNotEmpty) {
          groupKey = groupKey[0].toUpperCase() + groupKey.substring(1);
        }
      }

      grouped.putIfAbsent(groupKey, () => []).add(order);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
      body: SafeArea(
        top: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TopNavWidget(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DefaultTabController(
                      length: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cabecera con Título y Tabs
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Confirmación de Pagos',
                                  style: theme.headlineMedium.override(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh_rounded),
                                  tooltip: 'Actualizar pagos',
                                  onPressed: _fetchData,
                                ),
                              ],
                            ),
                          ),

                          // TabBar principal
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: TabBar(
                              labelColor: theme.primary,
                              unselectedLabelColor: theme.secondaryText,
                              indicatorColor: theme.primary,
                              indicatorWeight: 3,
                              labelStyle: theme.bodyMedium.override(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                              ),
                              tabs: [
                                Tab(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.shopping_bag_outlined, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Pagos Regulares (${_ordersToConfirm.length})'),
                                    ],
                                  ),
                                ),
                                Tab(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.bookmark_outline_rounded, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Abonos Apartado (${_apartadosToConfirm.length})'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Barra de Filtros, Búsqueda y Ordenamiento
                          _buildFilterToolbar(theme),

                          const Divider(height: 1),

                          // Vistas de Contenido por Tab
                          Expanded(
                            child: TabBarView(
                              children: [
                                _buildOrdersList(_ordersToConfirm, 'pagos regulares'),
                                _buildOrdersList(_apartadosToConfirm, 'abonos de apartado'),
                              ],
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

  Widget _buildFilterToolbar(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: theme.secondaryBackground,
      child: Column(
        children: [
          // Fila 1: Buscador y Menú de Ordenar
          Row(
            children: [
              // Buscador
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Buscar por cliente, ref, telf o ID...',
                      hintStyle: theme.bodySmall,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: theme.primaryBackground,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.alternate),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.alternate),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Dropdown de Ordenar
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: theme.primaryBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.alternate),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    icon: const Icon(Icons.sort_rounded, size: 20),
                    style: theme.bodySmall.override(
                      fontFamily: 'Inter',
                      color: theme.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'date_desc', child: Text('Más recientes')),
                      DropdownMenuItem(value: 'date_asc', child: Text('Más antiguos')),
                      DropdownMenuItem(value: 'amount_desc', child: Text('Mayor monto')),
                      DropdownMenuItem(value: 'amount_asc', child: Text('Menor monto')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _sortBy = val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Toggle Agrupar por Día
              Tooltip(
                message: _groupByDate ? 'Agrupado por día' : 'Lista continua',
                child: IconButton(
                  icon: Icon(
                    _groupByDate ? Icons.calendar_view_day_rounded : Icons.view_agenda_outlined,
                    color: _groupByDate ? theme.primary : theme.secondaryText,
                    size: 22,
                  ),
                  onPressed: () => setState(() => _groupByDate = !_groupByDate),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Fila 2: Chips de Filtro por Método
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMethodChip(theme, 'todos', 'Todos', Icons.all_inclusive_rounded),
                const SizedBox(width: 6),
                _buildMethodChip(theme, 'pago_movil', 'Pago Móvil', Icons.phone_android_rounded),
                const SizedBox(width: 6),
                _buildMethodChip(theme, 'binance', 'Binance', Icons.currency_bitcoin_rounded),
                const SizedBox(width: 6),
                _buildMethodChip(theme, 'paypal', 'PayPal', Icons.payment_rounded),
                const SizedBox(width: 6),
                _buildMethodChip(theme, 'zelle', 'Zelle', Icons.flash_on_rounded),
                const SizedBox(width: 6),
                _buildMethodChip(theme, 'otros', 'Otros / Efectivo', Icons.more_horiz_rounded),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChip(FlutterFlowTheme theme, String key, String label, IconData icon) {
    final bool isSelected = _selectedMethod == key;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? Colors.white : theme.secondaryText,
          ),
          const SizedBox(width: 5),
          Text(label),
        ],
      ),
      selected: isSelected,
      selectedColor: theme.primary,
      backgroundColor: theme.primaryBackground,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : theme.primaryText,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? theme.primary : theme.alternate,
        ),
      ),
      onSelected: (bool selected) {
        if (selected) {
          setState(() => _selectedMethod = key);
        }
      },
    );
  }

  Widget _buildOrdersList(List<PedidosRow> sourceOrders, String listLabel) {
    final filtered = _filterAndSortOrders(sourceOrders);

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.green.shade300),
              const SizedBox(height: 16),
              Text(
                'No hay $listLabel pendientes',
                style: FlutterFlowTheme.of(context).titleMedium.override(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                _searchQuery.isNotEmpty || _selectedMethod != 'todos'
                    ? 'No se encontraron resultados con los filtros actuales'
                    : '¡Estás al día con las confirmaciones!',
                style: FlutterFlowTheme.of(context).bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_groupByDate && _searchQuery.isEmpty) {
      final grouped = _groupOrdersByDate(filtered);
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: grouped.keys.length,
        itemBuilder: (context, index) {
          final dateKey = grouped.keys.elementAt(index);
          final ordersInGroup = grouped[dateKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        dateKey,
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Inter',
                              color: FlutterFlowTheme.of(context).primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${ordersInGroup.length} pedidos)',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            fontFamily: 'Inter',
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Divider(),
                      ),
                    ),
                  ],
                ),
              ),
              ...ordersInGroup.map(
                (order) => AdminPaymentCard(
                  key: ValueKey(order.id),
                  order: order,
                  onConfirm: () => _confirmOrder(order),
                  onReject: () => _promptRejectOrder(order),
                  onTapDetails: () => _showOrderDetails(order),
                ),
              ),
            ],
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final order = filtered[index];
        return AdminPaymentCard(
          key: ValueKey(order.id),
          order: order,
          onConfirm: () => _confirmOrder(order),
          onReject: () => _promptRejectOrder(order),
          onTapDetails: () => _showOrderDetails(order),
        );
      },
    );
  }
}
