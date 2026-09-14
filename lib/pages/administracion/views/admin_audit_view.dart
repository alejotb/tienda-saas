import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/backend/supabase/database/tables/inventory_logs.dart';
import 'package:baul_pandora/services/woocommerce_sync_service.dart';

class AdminAuditView extends StatefulWidget {
  const AdminAuditView({super.key});

  @override
  State<AdminAuditView> createState() => _AdminAuditViewState();
}

class _AdminAuditViewState extends State<AdminAuditView> {
  List<InventoryLogsRow> _logs = [];
  final Map<String, ProductosRow> _productsMap = {};
  final Map<String, UsuariosRow> _usersMap = {};

  bool _isLoading = true;
  bool _isSyncing = false;
  String _selectedFilter = 'todos'; // 'todos', 'woo', 'app', 'ajustes'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int _currentPage = 1;
  int _pageSize = 25;
  int _totalElements = 0;

  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _syncAndRefresh() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _isLoading = true;
    });

    try {
      debugPrint('🛒 Sincronizando pedidos desde WooCommerce...');
      final syncResult = await WooCommerceSyncService().syncOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              syncResult.success 
                  ? syncResult.message 
                  : 'Sincronización finalizada con observaciones: ${syncResult.message}',
            ),
            backgroundColor: syncResult.success ? const Color(0xFF059669) : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error en sincronización de pedidos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al sincronizar pedidos de WooCommerce: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
      await _loadLogs(isRefresh: true);
    }
  }

  Future<void> _loadLogs({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
    }
    setState(() => _isLoading = true);

    try {
      final from = (_currentPage - 1) * _pageSize;
      final to = from + _pageSize - 1;

      // Base queries para conteo y datos paginados
      dynamic query = SupaFlow.client.from('inventory_logs').select('*');
      dynamic countQuery = SupaFlow.client.from('inventory_logs').select('*');

      if (_selectedFilter == 'woo') {
        query = query.inFilter('tipo_operacion', ['venta_woo', 'reembolso_woo']);
        countQuery = countQuery.inFilter('tipo_operacion', ['venta_woo', 'reembolso_woo']);
      } else if (_selectedFilter == 'app') {
        query = query.eq('tipo_operacion', 'venta');
        countQuery = countQuery.eq('tipo_operacion', 'venta');
      } else if (_selectedFilter == 'ajustes') {
        query = query.inFilter('tipo_operacion', ['entrada', 'salida', 'ajuste']);
        countQuery = countQuery.inFilter('tipo_operacion', ['entrada', 'salida', 'ajuste']);
      }

      if (_searchQuery.isNotEmpty) {
        query = query.ilike('notas', '%$_searchQuery%');
        countQuery = countQuery.ilike('notas', '%$_searchQuery%');
      }

      final countRes = await countQuery.count(CountOption.exact);
      final int totalCount = countRes.count ?? 0;

      final dataRes = await query
          .order('created_at', ascending: false)
          .range(from, to);

      final List<InventoryLogsRow> pageLogs = (dataRes as List)
          .map((item) => InventoryLogsRow(item))
          .toList();

      // Lazy Loading: Solo cargar los productos y usuarios faltantes de los 25 elementos de esta página
      final productIds = pageLogs
          .map((l) => l.productoId)
          .where((id) => id.isNotEmpty && id.length >= 8)
          .toSet()
          .toList();

      final missingProdIds = productIds.where((id) => !_productsMap.containsKey(id)).toList();
      if (missingProdIds.isNotEmpty) {
        try {
          final prods = await ProductosTable().queryRows(
            queryFn: (q) => q.inFilter('id', missingProdIds),
          );
          for (var p in prods) {
            _productsMap[p.id] = p;
          }
        } catch (pe) {
          debugPrint('Error cargando lote de productos: $pe');
        }
      }

      final userIds = pageLogs
          .map((l) => l.usuarioId)
          .where((id) => id != null && id.isNotEmpty && id.length >= 8)
          .map((id) => id!)
          .toSet()
          .toList();

      final missingUserIds = userIds.where((id) => !_usersMap.containsKey(id)).toList();
      if (missingUserIds.isNotEmpty) {
        try {
          final users = await UsuariosTable().queryRows(
            queryFn: (q) => q.inFilter('id', missingUserIds),
          );
          for (var u in users) {
            _usersMap[u.id] = u;
          }
        } catch (ue) {
          debugPrint('Error cargando lote de usuarios: $ue');
        }
      }

      if (mounted) {
        setState(() {
          _logs = pageLogs;
          _totalElements = totalCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando logs de auditoría: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando movimientos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _goToPage(int page) {
    final totalPages = (_totalElements / _pageSize).ceil() == 0 ? 1 : (_totalElements / _pageSize).ceil();
    if (page < 1 || page > totalPages || page == _currentPage) return;
    setState(() => _currentPage = page);
    _loadLogs();
  }

  void _changePageSize(int newSize) {
    if (newSize == _pageSize) return;
    setState(() {
      _pageSize = newSize;
      _currentPage = 1;
    });
    _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    final theme = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(theme, isDesktop),
        const SizedBox(height: 12),
        _buildFiltersAndSearch(theme, isDesktop),
        const SizedBox(height: 12),
        Expanded(
          child: _isLoading && !_isSyncing
              ? const Center(child: CircularProgressIndicator())
              : _logs.isEmpty
                  ? _buildEmptyState(theme)
                  : (isDesktop
                      ? _buildDesktopTable(theme)
                      : RefreshIndicator(
                          onRefresh: _syncAndRefresh,
                          child: _buildMobileList(theme),
                        )),
        ),
        const SizedBox(height: 10),
        _buildPaginationBar(theme, isDesktop),
      ],
    );
  }

  Widget _buildHeader(FlutterFlowTheme theme, bool isDesktop) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.manage_history_rounded, size: 22, color: theme.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Auditoría',
            style: theme.headlineSmall.override(
              fontFamily: 'Inter',
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        if (isDesktop)
          ElevatedButton.icon(
            onPressed: _isSyncing ? null : _syncAndRefresh,
            icon: _isSyncing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh_rounded, size: 18),
            label: Text(_isSyncing ? 'Sincronizando...' : 'Recargar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: theme.primaryText,
              disabledBackgroundColor: theme.primary.withValues(alpha: 0.6),
              disabledForegroundColor: theme.primaryText.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          )
        else
          Material(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _isSyncing ? null : _syncAndRefresh,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.alternate),
                ),
                child: _isSyncing
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.primary,
                        ),
                      )
                    : Icon(Icons.refresh_rounded, size: 20, color: theme.primaryText),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFiltersAndSearch(FlutterFlowTheme theme, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Buscador
        SizedBox(
          width: double.infinity,
          height: 44,
          child: TextField(
            controller: _searchController,
            onSubmitted: (val) {
              setState(() {
                _searchQuery = val.trim();
                _currentPage = 1;
              });
              _loadLogs();
            },
            onChanged: (val) {
              if (val.trim() != _searchQuery) {
                _searchQuery = val.trim();
                _currentPage = 1;
                _loadLogs();
              }
            },
            decoration: InputDecoration(
              hintText: 'Buscar por nota, pedido o palabra clave...',
              hintStyle: theme.labelMedium,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _currentPage = 1;
                        });
                        _loadLogs();
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.secondaryBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
        const SizedBox(height: 10),

        // Filtros en Fila Scrolleable Horizontalmente
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('todos', 'Todos', Icons.list_alt_rounded, theme),
              const SizedBox(width: 8),
              _buildFilterChip('woo', 'WooCommerce', Icons.shopping_cart_outlined, theme, color: const Color(0xFF9333EA)),
              const SizedBox(width: 8),
              _buildFilterChip('app', 'App Móvil', Icons.phone_android_rounded, theme, color: const Color(0xFF0284C7)),
              const SizedBox(width: 8),
              _buildFilterChip('ajustes', 'Ajustes Manuales', Icons.tune_rounded, theme, color: const Color(0xFFD97706)),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Total Elementos
        Row(
          children: [
            Text(
              'Total elementos: ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.secondaryText,
              ),
            ),
            Text(
              '$_totalElements',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.primaryText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String key,
    String label,
    IconData icon,
    FlutterFlowTheme theme, {
    Color? color,
  }) {
    final isSelected = _selectedFilter == key;
    final activeColor = color ?? theme.primary;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) {
        if (_selectedFilter != key) {
          setState(() {
            _selectedFilter = key;
            _currentPage = 1;
          });
          _loadLogs();
        }
      },
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : activeColor,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : theme.primaryText,
      ),
      backgroundColor: theme.secondaryBackground,
      selectedColor: activeColor,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? activeColor : theme.alternate,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildEmptyState(FlutterFlowTheme theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 64, color: theme.secondaryText),
          const SizedBox(height: 16),
          Text(
            'No se encontraron movimientos',
            style: theme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta cambiar los filtros o el término de búsqueda.',
            style: theme.labelMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(FlutterFlowTheme theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth;
            const double spacing = 16.0;
            const double margin = 16.0;
            
            // Espacios y anchos fijos
            const double colFechaWidth = 125.0;
            const double colOrigenWidth = 120.0;
            const double colCantidadWidth = 75.0;

            const double fixedColumnsWidth = colFechaWidth + colOrigenWidth + colCantidadWidth;
            const double fixedSpacingsWidth = (margin * 2) + (spacing * 5); // 32 + 80 = 112
            final double remainingWidth = (availableWidth - fixedColumnsWidth - fixedSpacingsWidth).clamp(360.0, double.infinity);

            final double colProductoWidth = remainingWidth * 0.44;
            final double colUsuarioWidth = remainingWidth * 0.22;
            final double colDetalleWidth = remainingWidth * 0.34;

            return Scrollbar(
              controller: _verticalScrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _verticalScrollController,
                scrollDirection: Axis.vertical,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Scrollbar(
                  controller: _horizontalScrollController,
                  thumbVisibility: true,
                  notificationPredicate: (notif) => notif.depth == 1,
                  child: SingleChildScrollView(
                    controller: _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraints.maxWidth),
                      child: DataTable(
                        columnSpacing: spacing,
                        horizontalMargin: margin,
                        headingRowColor: WidgetStateProperty.all(theme.primaryBackground),
                        columns: [
                          const DataColumn(label: SizedBox(width: colFechaWidth, child: Text('Fecha y Hora', style: TextStyle(fontWeight: FontWeight.bold)))),
                          DataColumn(label: SizedBox(width: colProductoWidth, child: const Text('Producto', style: TextStyle(fontWeight: FontWeight.bold)))),
                          const DataColumn(label: SizedBox(width: colOrigenWidth, child: Text('Origen / Tipo', style: TextStyle(fontWeight: FontWeight.bold)))),
                          DataColumn(label: SizedBox(width: colUsuarioWidth, child: const Text('Usuario / Cliente', style: TextStyle(fontWeight: FontWeight.bold)))),
                          const DataColumn(label: SizedBox(width: colCantidadWidth, child: Text('Cantidad', style: TextStyle(fontWeight: FontWeight.bold)))),
                          DataColumn(label: SizedBox(width: colDetalleWidth, child: const Text('Detalle / Pedido', style: TextStyle(fontWeight: FontWeight.bold)))),
                        ],
                        rows: _logs
                            .map((log) => _buildDataRow(
                                  log,
                                  theme,
                                  colFechaWidth,
                                  colProductoWidth,
                                  colOrigenWidth,
                                  colUsuarioWidth,
                                  colCantidadWidth,
                                  colDetalleWidth,
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  DataRow _buildDataRow(
    InventoryLogsRow log,
    FlutterFlowTheme theme,
    double colFechaWidth,
    double colProductoWidth,
    double colOrigenWidth,
    double colUsuarioWidth,
    double colCantidadWidth,
    double colDetalleWidth,
  ) {
    final prod = _productsMap[log.productoId];
    final user = _usersMap[log.usuarioId];
    final isWoo = log.tipoOperacion == 'venta_woo' || 
                  log.tipoOperacion == 'reembolso_woo' || 
                  (log.notas?.toLowerCase().contains('woo') ?? false);

    final String? imgUrl = (prod?.imagePath != null && prod!.imagePath!.isNotEmpty) 
        ? prod.imagePath!.first 
        : null;

    return DataRow(
      cells: [
        // 1. Fecha y Hora
        DataCell(
          SizedBox(
            width: colFechaWidth,
            child: Text(
              DateFormat('dd/MM/yyyy HH:mm').format(log.createdAt.toLocal()),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),

        // 2. Producto (Expandido dinámicamente)
        DataCell(
          SizedBox(
            width: colProductoWidth,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: imgUrl != null && imgUrl.isNotEmpty
                      ? Image.network(
                          imgUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _prodPlaceholder(theme),
                        )
                      : _prodPlaceholder(theme),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _safeProductName(log, prod),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (prod?.sku != null && prod!.sku!.isNotEmpty)
                        Text(
                          'SKU: ${prod.sku}',
                          style: TextStyle(fontSize: 11, color: theme.secondaryText),
                        )
                      else if (prod?.idWoo != null)
                        Text(
                          'Woo ID: ${prod?.idWoo}',
                          style: TextStyle(fontSize: 11, color: theme.secondaryText),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Origen / Tipo
        DataCell(
          SizedBox(
            width: colOrigenWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildOriginBadge(log, isWoo, theme),
            ),
          ),
        ),

        // 4. Usuario / Cliente
        DataCell(
          SizedBox(
            width: colUsuarioWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isWoo)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.storefront_rounded, size: 14, color: Color(0xFF9333EA)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _resolveCustomerName(log, user, isWoo),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    _resolveCustomerName(log, user, isWoo),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (user?.email != null && user!.email!.isNotEmpty && !isWoo)
                  Text(
                    user.email!,
                    style: TextStyle(fontSize: 11, color: theme.secondaryText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),

        // 5. Cantidad Delta
        DataCell(
          SizedBox(
            width: colCantidadWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildDeltaBadge(log.cantidad),
            ),
          ),
        ),

        // 6. Detalle / Pedido
        DataCell(
          SizedBox(
            width: colDetalleWidth,
            child: _buildNotesWidget(log.notas, isWoo, theme),
          ),
        ),
      ],
    );
  }

  String _resolveCustomerName(InventoryLogsRow log, UsuariosRow? user, bool isWoo) {
    if (user?.nombre != null && user!.nombre!.isNotEmpty) {
      return user.nombre!;
    }
    if (isWoo && log.notas != null) {
      final match = RegExp(r'\(([^-\)]+)').firstMatch(log.notas!);
      if (match != null && match.group(1) != null) {
        final extracted = match.group(1)!.trim();
        if (extracted.isNotEmpty && extracted.length < 35) {
          return extracted;
        }
      }
      return 'Cliente WooCommerce';
    }
    return user?.email ?? 'Sistema / Admin';
  }

  String _safeProductName(InventoryLogsRow log, ProductosRow? prod) {
    if (prod?.nombre != null && prod!.nombre.isNotEmpty) {
      return prod.nombre;
    }
    if (log.productoId.length >= 8) {
      return 'Producto #${log.productoId.substring(0, 8)}';
    }
    if (log.productoId.isNotEmpty) {
      return 'Producto #${log.productoId}';
    }
    return 'Producto';
  }

  Widget _buildNotesWidget(String? rawNotes, bool isWoo, FlutterFlowTheme theme) {
    if (rawNotes == null || rawNotes.isEmpty) {
      return Text('-', style: TextStyle(fontSize: 12, color: theme.secondaryText));
    }

    final orderMatch = RegExp(r'#(\d+)').firstMatch(rawNotes);
    final String? orderNum = orderMatch != null ? '#${orderMatch.group(1)}' : null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (orderNum != null && isWoo) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF9333EA).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF9333EA).withValues(alpha: 0.3)),
            ),
            child: Text(
              orderNum,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9333EA),
              ),
            ),
          ),
        ],
        Flexible(
          child: Text(
            rawNotes,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: theme.secondaryText),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileList(FlutterFlowTheme theme) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final log = _logs[index];
        final prod = _productsMap[log.productoId];
        final user = _usersMap[log.usuarioId];
        final isWoo = log.tipoOperacion == 'venta_woo' || 
                      log.tipoOperacion == 'reembolso_woo' || 
                      (log.notas?.toLowerCase().contains('woo') ?? false);

        final String? imgUrl = (prod?.imagePath != null && prod!.imagePath!.isNotEmpty) 
            ? prod.imagePath!.first 
            : null;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.alternate),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila Superior: Badge + Fecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildOriginBadge(log, isWoo, theme),
                  Text(
                    DateFormat('dd/MM/yy HH:mm').format(log.createdAt.toLocal()),
                    style: TextStyle(fontSize: 11, color: theme.secondaryText),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Fila Media: Imagen + Producto + Delta
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imgUrl != null && imgUrl.isNotEmpty
                        ? Image.network(
                            imgUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _prodPlaceholder(theme),
                          )
                        : _prodPlaceholder(theme),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _safeProductName(log, prod),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        if (prod?.sku != null && prod!.sku!.isNotEmpty)
                          Text(
                            'SKU: ${prod.sku}',
                            style: TextStyle(fontSize: 11, color: theme.secondaryText),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildDeltaBadge(log.cantidad),
                ],
              ),

              // Usuario / Cliente
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    isWoo ? Icons.storefront_rounded : Icons.person_outline_rounded,
                    size: 13,
                    color: isWoo ? const Color(0xFF9333EA) : theme.secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _resolveCustomerName(log, user, isWoo),
                      style: TextStyle(
                        fontSize: 11,
                        color: isWoo ? const Color(0xFF9333EA) : theme.secondaryText,
                        fontWeight: isWoo ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Notas / Pedido
              if (log.notas != null && log.notas!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notes_rounded, size: 14, color: theme.secondaryText),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _buildNotesWidget(log.notas, isWoo, theme),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildOriginBadge(InventoryLogsRow log, bool isWoo, FlutterFlowTheme theme) {
    if (isWoo) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF9333EA).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF9333EA).withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 13, color: Color(0xFF9333EA)),
            SizedBox(width: 4),
            Text(
              'WooCommerce',
              style: TextStyle(
                color: Color(0xFF9333EA),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    if (log.tipoOperacion == 'venta') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF0284C7).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.phone_android_rounded, size: 13, color: Color(0xFF0284C7)),
            SizedBox(width: 4),
            Text(
              'App Móvil',
              style: TextStyle(
                color: Color(0xFF0284C7),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    if (log.tipoOperacion.contains('ajuste') || log.tipoOperacion == 'entrada' || log.tipoOperacion == 'salida') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFD97706).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, size: 13, color: Color(0xFFD97706)),
            const SizedBox(width: 4),
            Text(
              log.tipoOperacion.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFD97706),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.secondaryText.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        log.tipoOperacion,
        style: TextStyle(
          color: theme.secondaryText,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildDeltaBadge(int cantidad) {
    final isNegative = cantidad < 0;
    final isPositive = cantidad > 0;
    final color = isNegative ? const Color(0xFFEF4444) : (isPositive ? const Color(0xFF16A34A) : Colors.grey);
    final text = '${isPositive ? '+' : ''}$cantidad';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNegative 
                ? Icons.arrow_downward_rounded 
                : (isPositive ? Icons.arrow_upward_rounded : Icons.remove_rounded),
            size: 14,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar(FlutterFlowTheme theme, bool isDesktop) {
    final totalPages = (_totalElements / _pageSize).ceil() == 0 ? 1 : (_totalElements / _pageSize).ceil();
    final startItem = _totalElements == 0 ? 0 : (_currentPage - 1) * _pageSize + 1;
    final endItem = ((_currentPage - 1) * _pageSize + _logs.length).clamp(0, _totalElements);

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
                DropdownMenuItem(value: 15, child: Text('15')),
                DropdownMenuItem(value: 25, child: Text('25')),
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

  Widget _prodPlaceholder(FlutterFlowTheme theme) {
    return Container(
      width: 36,
      height: 36,
      color: theme.primaryBackground,
      child: Icon(Icons.image_not_supported_rounded, size: 18, color: theme.secondaryText),
    );
  }
}
