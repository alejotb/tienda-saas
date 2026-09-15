import 'package:flutter/material.dart';
import 'package:baul_pandora/services/notification_service.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/services/cart_service.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';

class AdminOrdersView extends StatefulWidget {
  const AdminOrdersView({super.key});

  @override
  State<AdminOrdersView> createState() => _AdminOrdersViewState();
}

class _AdminOrdersViewState extends State<AdminOrdersView> {
  String _selectedStatus = 'todos';
  String _searchQuery = '';
  bool _isLoading = true;

  int _currentPage = 1;
  int _pageSize = 20;
  int _totalElements = 0;
  List<PedidosRow> _orders = [];

  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'todos', 'label': 'Todos'},
    {'value': 'carrito', 'label': 'En Carrito'},
    {'value': 'apartado', 'label': 'Apartados'},
    {'value': 'pagado', 'label': 'Pagados'},
    {'value': 'confirmado', 'label': 'Confirmados'},
    {'value': 'rechazado', 'label': 'Rechazados'},
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
    }
    setState(() => _isLoading = true);

    try {
      final from = (_currentPage - 1) * _pageSize;
      final to = from + _pageSize - 1;

      dynamic query = SupaFlow.client.from('pedidos').select('*');
      dynamic countQuery = SupaFlow.client.from('pedidos').select('*');

      if (FFAppState().activeStoreId.isNotEmpty) {
        query = query.eq('tienda_id', FFAppState().activeStoreId);
        countQuery = countQuery.eq('tienda_id', FFAppState().activeStoreId);
      }

      if (_selectedStatus != 'todos') {
        query = query.eq('status', _selectedStatus);
        countQuery = countQuery.eq('status', _selectedStatus);
      }

      if (_searchQuery.isNotEmpty) {
        query = query.or('id.ilike.%$_searchQuery%,email_cliente.ilike.%$_searchQuery%,nombre_cliente.ilike.%$_searchQuery%');
        countQuery = countQuery.or('id.ilike.%$_searchQuery%,email_cliente.ilike.%$_searchQuery%,nombre_cliente.ilike.%$_searchQuery%');
      }

      final countRes = await countQuery.count(CountOption.exact);
      final int total = countRes.count ?? 0;

      final dataRes = await query
          .order('fecha_creacion', ascending: false)
          .range(from, to);

      final pageOrders = (dataRes as List).map((r) => PedidosRow(r)).toList();

      if (mounted) {
        setState(() {
          _orders = pageOrders;
          _totalElements = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando pedidos: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando pedidos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _goToPage(int page) {
    final totalPages = (_totalElements / _pageSize).ceil() == 0 ? 1 : (_totalElements / _pageSize).ceil();
    if (page < 1 || page > totalPages || page == _currentPage) return;
    setState(() => _currentPage = page);
    _loadOrders();
  }

  void _changePageSize(int newSize) {
    if (newSize == _pageSize) return;
    setState(() {
      _pageSize = newSize;
      _currentPage = 1;
    });
    _loadOrders();
  }

  Future<void> _updatePaymentStatus(String paymentId, String orderId, String newStatus) async {
    try {
      await SupaFlow.client.from('pagos').update({'estado': newStatus}).eq('id', paymentId);
      
      // Sincronizar el saldo pendiente y actualizar el estado del pedido si es necesario
      await CartService.instance.syncPendingBalance(orderId);
      
      // Enviar notificación al usuario si el pago fue aprobado o rechazado
      final user = await SupaFlow.client.from('pedidos').select('user_id').eq('id', orderId).single();
      final userId = user['user_id'];
      
      if (userId != null) {
        if (newStatus == 'aprobado' || newStatus == 'confirmado') {
          await NotificationService.instance.send(
            userId, 
            'Pago Aprobado ✅', 
            'Tu pago ha sido verificado exitosamente. Tu pedido está en proceso.',
            type: 'pago'
          );
        } else if (newStatus == 'rechazado' || newStatus == 'con_error') {
          await NotificationService.instance.send(
            userId, 
            'Pago Rechazado ❌', 
            'Hubo un problema con tu comprobante de pago. Por favor, verifica los datos y vuelve a intentarlo.',
            type: 'pago'
          );
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pago ${newStatus == 'aprobado' || newStatus == 'confirmado' ? 'aprobado' : 'con error'}')),
        );
      }
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el pago: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await PedidosTable().update(
        matchingRows: (rows) => rows.eq('id', orderId),
        data: {'status': newStatus},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Estado actualizado a $newStatus')),
        );
      }
      _loadOrders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el estado: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Centro de Operaciones de Pedidos',
            style: theme.headlineMedium.override(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Filters Bar
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  onSubmitted: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                      _currentPage = 1;
                    });
                    _loadOrders();
                  },
                  onChanged: (val) {
                    if (val.trim() != _searchQuery) {
                      _searchQuery = val.trim();
                      _currentPage = 1;
                      _loadOrders();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por ID de pedido o Email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.secondaryBackground,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.secondaryBackground,
                  ),
                  items: _statusOptions.map((opt) => DropdownMenuItem<String>(
                    value: opt['value'] as String, 
                    child: Text(opt['label'] as String),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStatus = val;
                        _currentPage = 1;
                      });
                      _loadOrders();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Orders Table Container
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.alternate),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildOrdersTable(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildPaginationBar(theme, isDesktop),
        ],
      ),
    );
  }

  Widget _buildOrdersTable() {
    if (_orders.isEmpty) {
      return const Center(child: Text('No hay pedidos que coincidan con el filtro'));
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: FlutterFlowTheme.of(context).primaryBackground,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pedido / Cliente', style: FlutterFlowTheme.of(context).titleSmall.override(fontWeight: FontWeight.bold)),
              Text('Total', style: FlutterFlowTheme.of(context).titleSmall.override(fontWeight: FontWeight.bold)),
              Text('Estado', style: FlutterFlowTheme.of(context).titleSmall.override(fontWeight: FontWeight.bold)),
              Text('Acciones', style: FlutterFlowTheme.of(context).titleSmall.override(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: _orders.length,
            separatorBuilder: (context, index) => Divider(color: FlutterFlowTheme.of(context).alternate),
            itemBuilder: (context, index) {
              final order = _orders[index];
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.nombreCliente ?? 'Sin nombre',
                                    style: FlutterFlowTheme.of(context).bodyMedium.override(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${order.userId == null ? 'Invitado' : 'Usuario Registrado'} • ${order.emailCliente ?? 'Sin email'}',
                                    style: FlutterFlowTheme.of(context).bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '\$${order.totalPrice?.toStringAsFixed(2) ?? '0.00'}',
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context).bodyMedium.override(fontWeight: FontWeight.w600),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: _buildStatusDropdown(order.id, order.status ?? 'carrito'),
                            ),
                            Expanded(
                              flex: 1,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined, size: 20),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Abriendo detalle del pedido ${order.id}...')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (order.status == 'apartado' || order.status == 'pendiente_pago')
                        _buildPaymentVerificationSection(order),
                    ],
                  );
                },
              ),
            ),
          ],
        );
  }

  Widget _buildPaymentVerificationSection(PedidosRow order) {
    return Container(
      width: double.infinity,
      color: FlutterFlowTheme.of(context).primaryBackground.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: SupaFlow.client.from('pagos').select().eq('pedido_id', order.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final payments = snapshot.data!;
          if (payments.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Sin registros de pago', style: TextStyle(fontSize: 12, color: Colors.grey)),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              Text('Pagos Registrados', style: FlutterFlowTheme.of(context).bodySmall.override(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...payments.map((pago) {
                final st = pago['estado'] ?? pago['status'] ?? '';
                final isPend = st == 'pendiente' || st == 'pendiente_revision' || st == 'por_revisar';
                return _buildPaymentItem(
                  pago,
                  order.id,
                  isPend,
                  pago['ai_data'],
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> pago, String orderId, bool isPending, Map<String, dynamic>? aiData) {
    Color semaphoreColor = Colors.orange;
    String semaphoreText = '';

    if (aiData != null) {
      if (aiData['valido'] == true) {
        semaphoreColor = Colors.green;
        semaphoreText = 'Válido ✅';
      } else if (aiData['valido'] == false) {
        semaphoreColor = Colors.red;
        semaphoreText = 'Inválido ❌';
      }
    }

    final estadoLabel = pago['estado'] ?? pago['status'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${pago['moneda']} ${pago['monto']} - ${pago['referencia'] ?? 'S/R'} ($estadoLabel)',
                  style: FlutterFlowTheme.of(context).bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (semaphoreText.isNotEmpty) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: semaphoreColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: semaphoreColor),
                  ),
                  child: Text(
                    semaphoreText,
                    style: TextStyle(color: semaphoreColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              if (isPending) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                  tooltip: 'Aprobar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _updatePaymentStatus(pago['id'], orderId, 'confirmado'),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                  tooltip: 'Rechazar',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => _updatePaymentStatus(pago['id'], orderId, 'con_error'),
                ),
              ],
            ],
          ),
          if (aiData != null && isPending)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🔍 Análisis IA:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    Text('Monto: ${aiData['monto']} | Ref: ${aiData['referencia']} | Banco: ${aiData['banco'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(String orderId, String currentStatus) {
    return DropdownButton<String>(
      value: _statusOptions.any((opt) => opt['value'] == currentStatus) 
          ? currentStatus 
          : 'carrito',
      underline: const SizedBox(),
      isExpanded: true,
      items: _statusOptions.map((opt) => DropdownMenuItem<String>(
        value: opt['value'] as String, 
        child: Text(
          opt['label'] as String, 
          style: FlutterFlowTheme.of(context).bodySmall.override(
            color: _getStatusColor(opt['value'] as String),
            fontWeight: FontWeight.bold,
          ),
        ),
      )).toList(),
      onChanged: (val) {
        if (val != null) _updateOrderStatus(orderId, val);
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'carrito': return Colors.grey;
      case 'pendiente_pago': return Colors.orange;
      case 'apartado': return Colors.blue;
      case 'pagado': return Colors.green;
      case 'enviado': return Colors.purple;
      case 'cancelado': return Colors.red;
      default: return Colors.black;
    }
  }

  Widget _buildPaginationBar(FlutterFlowTheme theme, bool isDesktop) {
    final totalPages = (_totalElements / _pageSize).ceil() == 0 ? 1 : (_totalElements / _pageSize).ceil();
    final startItem = _totalElements == 0 ? 0 : (_currentPage - 1) * _pageSize + 1;
    final endItem = ((_currentPage - 1) * _pageSize + _orders.length).clamp(0, _totalElements);

    final canGoPrev = _currentPage > 1;
    final canGoNext = _currentPage < totalPages;

    final infoWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Mostrar: ',
          style: TextStyle(fontSize: 12, color: theme.secondaryText),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: theme.alternate),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _pageSize,
              isDense: true,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.primaryText),
              items: const [
                DropdownMenuItem(value: 10, child: Text('10')),
                DropdownMenuItem(value: 20, child: Text('20')),
                DropdownMenuItem(value: 50, child: Text('50')),
                DropdownMenuItem(value: 100, child: Text('100')),
              ],
              onChanged: (val) {
                if (val != null) _changePageSize(val);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Mostrando $startItem-$endItem de $_totalElements',
          style: TextStyle(fontSize: 12, color: theme.secondaryText, fontWeight: FontWeight.w500),
        ),
      ],
    );

    final navButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.first_page_rounded, size: 20),
          onPressed: canGoPrev ? () => _goToPage(1) : null,
          tooltip: 'Primera página',
          color: theme.primaryText,
          disabledColor: theme.secondaryText.withValues(alpha: 0.3),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded, size: 20),
          onPressed: canGoPrev ? () => _goToPage(_currentPage - 1) : null,
          tooltip: 'Página anterior',
          color: theme.primaryText,
          disabledColor: theme.secondaryText.withValues(alpha: 0.3),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$_currentPage / $totalPages',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.primary,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded, size: 20),
          onPressed: canGoNext ? () => _goToPage(_currentPage + 1) : null,
          tooltip: 'Página siguiente',
          color: theme.primaryText,
          disabledColor: theme.secondaryText.withValues(alpha: 0.3),
        ),
        IconButton(
          icon: const Icon(Icons.last_page_rounded, size: 20),
          onPressed: canGoNext ? () => _goToPage(totalPages) : null,
          tooltip: 'Última página',
          color: theme.primaryText,
          disabledColor: theme.secondaryText.withValues(alpha: 0.3),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.alternate),
      ),
      child: isDesktop
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                infoWidget,
                navButtons,
              ],
            )
          : Column(
              children: [
                infoWidget,
                const SizedBox(height: 4),
                navButtons,
              ],
            ),
    );
  }
}
