import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/services/store_service.dart';
import 'package:baul_pandora/services/store_theme_service.dart';

class StoreSelectorModal extends StatefulWidget {
  final Function(StoreData)? onStoreSelected;

  const StoreSelectorModal({super.key, this.onStoreSelected});

  static Future<void> show(
    BuildContext context, {
    Function(StoreData)? onStoreSelected,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Padding(
        padding: MediaQuery.viewInsetsOf(bottomSheetContext),
        child: StoreSelectorModal(onStoreSelected: onStoreSelected),
      ),
    );
  }

  @override
  State<StoreSelectorModal> createState() => _StoreSelectorModalState();
}

class _StoreSelectorModalState extends State<StoreSelectorModal> {
  bool _isLoading = true;
  List<StoreData> _stores = [];
  String? _activeStoreId;

  @override
  void initState() {
    super.initState();
    _activeStoreId = FFAppState().activeStoreId.isNotEmpty
        ? FFAppState().activeStoreId
        : StoreThemeService.instance.currentStore?.id;
    _fetchStores();
  }

  Future<void> _fetchStores() async {
    setState(() => _isLoading = true);
    try {
      final stores = await StoreService.instance.getMyStores();
      if (mounted) {
        setState(() {
          _stores = stores;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSelectStore(StoreData store) async {
    setState(() {
      _activeStoreId = store.id;
    });

    FFAppState().activeStoreId = store.id;
    FFAppState().activeStoreSlug = store.slug;
    StoreService.instance.switchActiveStore(store);

    if (widget.onStoreSelected != null) {
      widget.onStoreSelected!(store);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tienda activa: ${store.nombre}'),
          backgroundColor: const Color(0xFF16A34A),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleCreateStore() async {
    final eligibility = await StoreService.instance.checkStoreCreationEligibility();

    if (!eligibility.canCreate) {
      if (mounted) {
        _showUpgradeToProDialog(eligibility.message ?? 'Para gestionar múltiples tiendas, activa el Plan Pro.');
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).pop();
      context.pushNamed('storeRegister');
    }
  }

  void _showUpgradeToProDialog(String message) {
    final theme = FlutterFlowTheme.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded, color: Colors.purple, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Límite de Tiendas (Plan Free)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: theme.bodyMedium.override(fontFamily: 'Inter', fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.purple, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Plan Pro (\$14.99/mes): Tiendas ilimitadas, dominio propio y productos sin límite.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.purple),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text('Cerrar', style: TextStyle(color: theme.secondaryText)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              Navigator.of(context).pop();
              context.goNamed('adminStore');
            },
            icon: const Icon(Icons.stars_rounded, size: 18),
            label: const Text('Ver Planes Pro'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.storefront_rounded, color: theme.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis Tiendas',
                        style: theme.titleLarge.override(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Selecciona la tienda para administrar',
                        style: theme.bodySmall.override(color: theme.secondaryText),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Lista de Tiendas
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_stores.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.store_mall_directory_outlined, size: 48, color: theme.secondaryText),
                    const SizedBox(height: 12),
                    Text(
                      'No tienes tiendas registradas',
                      style: theme.bodyMedium.override(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _stores.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final store = _stores[index];
                  final isCurrentActive = _activeStoreId == store.id;
                  final isPro = store.plan.toLowerCase() == 'pro' || store.plan.toLowerCase() == 'premium';

                  return InkWell(
                    onTap: () => _handleSelectStore(store),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isCurrentActive
                            ? theme.primary.withValues(alpha: 0.08)
                            : theme.primaryBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrentActive ? theme.primary : theme.alternate,
                          width: isCurrentActive ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Logo / Icono
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isCurrentActive
                                  ? theme.primary.withValues(alpha: 0.15)
                                  : theme.alternate,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: store.logoUrl != null && store.logoUrl!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(store.logoUrl!, fit: BoxFit.cover),
                                  )
                                : Icon(
                                    Icons.storefront_rounded,
                                    color: isCurrentActive ? theme.primary : theme.secondaryText,
                                    size: 24,
                                  ),
                          ),
                          const SizedBox(width: 14),

                          // Información
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        store.nombre,
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: theme.primaryText,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isPro ? Colors.purple.withValues(alpha: 0.12) : Colors.green.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isPro ? 'PRO 👑' : 'FREE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isPro ? Colors.purple : Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'app.com/${store.slug}',
                                  style: theme.bodySmall.override(
                                    color: theme.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Indicador Activo
                          if (isCurrentActive)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 16),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 24),
          Divider(color: theme.alternate),
          const SizedBox(height: 12),

          // Botón Crear Nueva Tienda
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _handleCreateStore,
              icon: const Icon(Icons.add_business_rounded, size: 20),
              label: const Text('Crear Nueva Tienda'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
