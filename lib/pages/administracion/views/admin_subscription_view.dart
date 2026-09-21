import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/services/store_service.dart';
import 'package:baul_pandora/services/store_theme_service.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';

class AdminSubscriptionView extends StatefulWidget {
  const AdminSubscriptionView({super.key});

  @override
  State<AdminSubscriptionView> createState() => _AdminSubscriptionViewState();
}

class _AdminSubscriptionViewState extends State<AdminSubscriptionView> {
  bool _isLoading = true;
  StoreData? _store;
  int _productsCount = 0;
  bool _isUpdatingPlan = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final store = await StoreService.instance.getMyStore();
      _store = store;

      if (store != null) {
        StoreThemeService.instance.setStore(store);

        final countRes = await SupaFlow.client
            .from('productos')
            .select('id')
            .eq('tienda_id', store.id)
            .eq('es_variacion', false)
            .count(CountOption.exact);
        _productsCount = countRes.count;
      }
    } catch (e) {
      debugPrint('Error cargando información de suscripción: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePlan(String targetPlan) async {
    if (_store == null || _isUpdatingPlan) return;

    final isUpgrading = targetPlan == 'pro';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isUpgrading ? '👑 Activar Plan Pro' : 'Cambiar a Plan Gratuito'),
        content: Text(isUpgrading
            ? '¿Deseas activar el Plan Pro para "${_store!.nombre}"? Obtendrás productos ilimitados, dominio propio y cero publicidad.'
            : '¿Deseas cambiar al Plan Gratuito? Recuerda que el catálogo estará limitado a 100 productos.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isUpgrading ? Colors.purple : Colors.grey,
              foregroundColor: Colors.white,
            ),
            child: Text(isUpgrading ? '¡Activar Pro Ahora!' : 'Confirmar Cambio'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUpdatingPlan = true);
    try {
      final success = await StoreService.instance.updateStorePlan(_store!.id, targetPlan);
      if (success) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isUpgrading
                  ? '🎉 ¡Felicidades! Tu tienda ahora cuenta con todas las funciones del Plan Pro.'
                  : 'Se ha cambiado la tienda al Plan Gratuito.'),
              backgroundColor: isUpgrading ? Colors.purple : Colors.blueGrey,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar plan: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingPlan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final primaryColor = StoreThemeService.instance.primaryColor;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_store == null) {
      return const Center(child: Text('No se encontró información de la tienda.'));
    }

    final isPro = _store!.plan.toLowerCase() == 'pro' || _store!.plan.toLowerCase() == 'premium';
    const maxFreeProducts = 100;
    final progress = (_productsCount / maxFreeProducts).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mi Plan & Suscripción',
                      style: theme.headlineMedium.override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Administra los recursos, límites y membresía de tu tienda online',
                      style: theme.bodySmall.override(color: theme.secondaryText),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPro ? Colors.purple.withValues(alpha: 0.12) : Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isPro ? Colors.purple : Colors.green),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isPro ? Icons.stars_rounded : Icons.check_circle_outline, size: 18, color: isPro ? Colors.purple : Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        isPro ? 'PLAN PRO ACTIVO' : 'PLAN FREE ACTIVO',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPro ? Colors.purple : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tarjeta de Uso de Cuota
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.alternate),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Uso del Catálogo de Productos', style: theme.titleMedium.override(fontWeight: FontWeight.bold)),
                      Text(
                        isPro ? '$_productsCount productos (Ilimitados)' : '$_productsCount de $maxFreeProducts productos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (!isPro && _productsCount >= maxFreeProducts) ? Colors.red : primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: isPro ? 1.0 : progress,
                      backgroundColor: theme.alternate,
                      color: isPro
                          ? Colors.purple
                          : (_productsCount >= maxFreeProducts ? Colors.red : primaryColor),
                      minHeight: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPro
                        ? 'Tu tienda cuenta con capacidad ilimitada de productos en catálogo.'
                        : 'Te quedan ${maxFreeProducts - _productsCount > 0 ? maxFreeProducts - _productsCount : 0} cupos disponibles en el Plan Free.',
                    style: theme.bodySmall.override(color: theme.secondaryText, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Planes Comparativos
            Text('Planes Disponibles', style: theme.titleLarge.override(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: isWide ? 1 : 0,
                      child: _buildPlanCard(
                        theme: theme,
                        title: 'Plan Gratuito',
                        price: '\$0',
                        period: '/ mes',
                        isCurrent: !isPro,
                        accentColor: Colors.blueGrey,
                        features: [
                          '1 sola tienda por cuenta',
                          'Hasta 100 productos en catálogo',
                          'Catálogo web público independiente',
                          'Recepción de pedidos por WhatsApp',
                          'Gestión básica de inventario',
                          'Subdominio plataforma (app.com/tu-tienda)',
                          'Soporte estándar',
                        ],
                        buttonText: !isPro ? 'Plan Actual' : 'Cambiar a Free',
                        onTap: !isPro ? null : () => _togglePlan('free'),
                      ),
                    ),
                    SizedBox(width: isWide ? 20 : 0, height: isWide ? 0 : 20),
                    Expanded(
                      flex: isWide ? 1 : 0,
                      child: _buildPlanCard(
                        theme: theme,
                        title: 'Plan Pro',
                        price: '\$14.99',
                        period: '/ mes',
                        isCurrent: isPro,
                        isHighlight: true,
                        accentColor: Colors.purple,
                        features: [
                          '🏢 Múltiples Tiendas ILIMITADAS (Multi-Store)',
                          '👑 Productos ILIMITADOS',
                          '🌐 Dominio Propio (www.mitienda.com)',
                          '🚫 Cero Anuncios de Publicidad',
                          '📥 Importador Masivo CSV / Excel',
                          '🔄 Sincronización WooCommerce en vivo',
                          '🏷️ Módulo de Cupones y Descuentos',
                          '📊 Reportes y Analítica Avanzada',
                          '⚡ Soporte Prioritario VIP',
                        ],
                        buttonText: isPro ? 'Plan Actual' : '👑 ¡Actualizar a Pro!',
                        onTap: isPro ? null : () => _togglePlan('pro'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required FlutterFlowTheme theme,
    required String title,
    required String price,
    required String period,
    required bool isCurrent,
    bool isHighlight = false,
    required Color accentColor,
    required List<String> features,
    required String buttonText,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHighlight ? Colors.purple : (isCurrent ? accentColor : theme.alternate),
          width: isHighlight ? 2 : 1,
        ),
        boxShadow: [
          if (isHighlight)
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHighlight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'MÁS POPULAR',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          Text(title, style: theme.titleMedium.override(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: accentColor),
              ),
              const SizedBox(width: 4),
              Text(period, style: theme.bodySmall.override(color: theme.secondaryText)),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: theme.alternate),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, size: 18, color: accentColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: f.contains('👑') || f.contains('ILIMITADOS') ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? theme.primaryBackground : accentColor,
                foregroundColor: isCurrent ? theme.secondaryText : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: isCurrent ? 0 : 2,
              ),
              child: _isUpdatingPlan && !isCurrent
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
