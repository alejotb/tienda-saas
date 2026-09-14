import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/services/store_service.dart';
import 'package:baul_pandora/services/store_theme_service.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminStoreDashboardView extends StatefulWidget {
  const AdminStoreDashboardView({super.key});

  @override
  State<AdminStoreDashboardView> createState() => _AdminStoreDashboardViewState();
}

class _AdminStoreDashboardViewState extends State<AdminStoreDashboardView> {
  bool _isLoading = true;
  StoreData? _store;
  double _totalSales = 0.0;
  int _pendingOrdersCount = 0;
  int _productsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    setState(() => _isLoading = true);
    try {
      final store = await StoreService.instance.getMyStore();
      _store = store;

      if (store != null) {
        StoreThemeService.instance.setStore(store);
        await _fetchStoreMetrics(store.id);
      }
    } catch (e) {
      debugPrint('Error cargando panel de tienda: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStoreMetrics(String storeId) async {
    try {
      // 1. Contar productos de esta tienda específica
      final productsRes = await SupaFlow.client
          .from('productos')
          .select('id')
          .eq('tienda_id', storeId);
      
      final pCount = (productsRes as List).length;

      // 2. Contar ventas y pedidos pendientes de esta tienda específica
      final ordersRes = await SupaFlow.client
          .from('pedidos')
          .select('total_price, status')
          .eq('tienda_id', storeId);

      double salesSum = 0;
      int pendingCount = 0;

      for (var order in (ordersRes as List)) {
        final price = (order['total_price'] as num?)?.toDouble() ?? 0.0;
        final status = (order['status'] ?? '').toString();

        if (status == 'completado' || status == 'confirmado' || status == 'pagado') {
          salesSum += price;
        }
        if (status == 'pendiente' || status == 'apartado' || status == 'pendiente_pago') {
          pendingCount++;
        }
      }

      setState(() {
        _productsCount = pCount;
        _totalSales = salesSum;
        _pendingOrdersCount = pendingCount;
      });
    } catch (e) {
      debugPrint('Nota: Métricas multi-tenant cargadas o sin registros previos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_store == null) {
      return _buildNoStoreView(theme);
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con Branding de la Tienda
            _buildStoreHeader(theme),
            const SizedBox(height: 24),

            // Métricas y KPIs de la Tienda
            Text('Métricas de la Tienda', style: theme.titleLarge.override(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildMetricsGrid(theme),
            const SizedBox(height: 32),

            // Acciones Rápidas del Comerciante
            Text('Gestión y Herramientas', style: theme.titleLarge.override(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildQuickActionsGrid(theme),
          ],
        ),
      ),
    );
  }

  // --- Vista cuando el usuario no ha registrado ninguna tienda ---
  Widget _buildNoStoreView(FlutterFlowTheme theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.storefront_rounded, size: 72, color: theme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              '¡Aún no tienes una tienda registrada!',
              style: theme.headlineSmall.override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Comienza en menos de 2 minutos subiendo tu logo, eligiendo tus colores y creando tu catálogo independiente.',
              style: theme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.pushNamed('storeRegister');
              },
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Registrar Mi Tienda Ahora'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Cabecera de la Tienda ---
  Widget _buildStoreHeader(FlutterFlowTheme theme) {
    final primaryColor = StoreThemeService.instance.primaryColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.alternate),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo de la Tienda
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: _store!.logoUrl != null && _store!.logoUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_store!.logoUrl!, fit: BoxFit.cover),
                  )
                : Icon(Icons.storefront_rounded, size: 36, color: primaryColor),
          ),
          const SizedBox(width: 16),

          // Información de la Tienda
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _store!.nombre,
                      style: theme.headlineSmall.override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _store!.plan.toUpperCase(),
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'app.com/${_store!.slug}',
                      style: theme.bodySmall.override(color: theme.secondaryText, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botón de Crear Nueva / Cambiar Tienda
          OutlinedButton.icon(
            onPressed: () => context.pushNamed('storeRegister'),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Nueva Tienda'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Grid de Métricas ---
  Widget _buildMetricsGrid(FlutterFlowTheme theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        double spacing = 16;
        double cardWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _buildKpiCard('Ventas de la Tienda', '\$${_totalSales.toStringAsFixed(2)}', Icons.monetization_on_rounded, Colors.green, cardWidth, theme),
            _buildKpiCard('Pedidos Pendientes', '$_pendingOrdersCount', Icons.pending_actions_rounded, Colors.orange, cardWidth, theme),
            _buildKpiCard('Catálogo de Productos', '$_productsCount', Icons.inventory_2_rounded, Colors.teal, cardWidth, theme),
            _buildKpiCard('Plan de la Tienda', _store!.plan.toUpperCase(), Icons.stars_rounded, Colors.purple, cardWidth, theme),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color, double width, FlutterFlowTheme theme) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.alternate),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(title, style: theme.bodySmall),
            const SizedBox(height: 4),
            Text(value, style: theme.titleLarge.override(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // --- Grid de Acciones del Comerciante ---
  Widget _buildQuickActionsGrid(FlutterFlowTheme theme) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildActionButton(
          theme,
          title: 'Crear Producto',
          subtitle: 'Añade ítems a tu catálogo',
          icon: Icons.add_box_rounded,
          color: Colors.blue,
          onTap: () => context.pushNamed('productCreate'),
        ),
        _buildActionButton(
          theme,
          title: 'Configuración & Branding',
          subtitle: 'Personaliza logo y colores',
          icon: Icons.palette_rounded,
          color: Colors.purple,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Personalizador de colores de marca activado')),
            );
          },
        ),
        _buildActionButton(
          theme,
          title: 'Módulos & Extensiones',
          subtitle: 'Conectar WooCommerce / Shopify',
          icon: Icons.extension_rounded,
          color: Colors.orange,
          onTap: () => context.pushNamed('adminIntegraciones'),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    FlutterFlowTheme theme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 260,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.alternate),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.bodyMedium.override(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: theme.bodySmall.override(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
