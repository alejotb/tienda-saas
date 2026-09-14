import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/services/store_service.dart';
import 'package:baul_pandora/services/integration_service.dart';
import 'package:baul_pandora/services/woocommerce_sync_service.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminIntegrationsView extends StatefulWidget {
  const AdminIntegrationsView({super.key});

  @override
  State<AdminIntegrationsView> createState() => _AdminIntegrationsViewState();
}

class _AdminIntegrationsViewState extends State<AdminIntegrationsView> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSyncing = false;
  StoreData? _store;

  // WooCommerce controllers
  final _wooUrlController = TextEditingController();
  final _wooKeyController = TextEditingController();
  final _wooSecretController = TextEditingController();
  bool _wooActive = false;

  @override
  void initState() {
    super.initState();
    _loadIntegrationsData();
  }

  @override
  void dispose() {
    _wooUrlController.dispose();
    _wooKeyController.dispose();
    _wooSecretController.dispose();
    super.dispose();
  }

  Future<void> _loadIntegrationsData() async {
    setState(() => _isLoading = true);
    try {
      final store = await StoreService.instance.getMyStore();
      _store = store;

      if (store != null) {
        final integrations = await IntegrationService.instance.getStoreIntegrations(store.id);
        
        final wooInt = integrations.firstWhere(
          (i) => i.tipo == 'woocommerce',
          orElse: () => StoreIntegration(id: '', tiendaId: store.id, tipo: 'woocommerce', activa: false, credenciales: {}),
        );

        _wooActive = wooInt.activa;
        _wooUrlController.text = wooInt.credenciales['url']?.toString() ?? '';
        _wooKeyController.text = wooInt.credenciales['consumer_key']?.toString() ?? '';
        _wooSecretController.text = wooInt.credenciales['consumer_secret']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('Error cargando integraciones: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveWooCredentials() async {
    if (_store == null) return;
    setState(() => _isSaving = true);

    try {
      final success = await IntegrationService.instance.saveWooCommerceIntegration(
        tiendaId: _store!.id,
        wooUrl: _wooUrlController.text,
        consumerKey: _wooKeyController.text,
        consumerSecret: _wooSecretController.text,
        activa: _wooActive,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Configuración de WooCommerce guardada con éxito' : 'Error guardando credenciales'),
            backgroundColor: success ? const Color(0xFF16A34A) : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _triggerWooSync() async {
    setState(() => _isSyncing = true);
    try {
      final result = await WooCommerceSyncService().syncAllProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? const Color(0xFF16A34A) : Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al sincronizar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_store == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text('Debes registrar una tienda para acceder a las extensiones'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.pushNamed('storeRegister'),
              child: const Text('Registrar Tienda'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Módulos & Extensiones', style: theme.headlineMedium.override(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Conecta tu tienda con plataformas de comercio electrónico y herramientas externas', style: theme.bodyMedium),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _loadIntegrationsData,
                  tooltip: 'Actualizar estado',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Tarjeta de Extensión: WooCommerce
            _buildWooCommerceCard(theme),
            const SizedBox(height: 24),

            // Tarjeta de Extensión: Shopify (Próximamente)
            _buildComingSoonCard(theme, 'Shopify', 'Sincroniza tu catálogo con tu tienda de Shopify', Icons.shopping_bag_outlined, Colors.green),
            const SizedBox(height: 16),

            // Tarjeta de Extensión: MercadoLibre (Próximamente)
            _buildComingSoonCard(theme, 'MercadoLibre', 'Publicación directa en el marketplace de MercadoLibre', Icons.store_rounded, Colors.amber.shade800),
          ],
        ),
      ),
    );
  }

  Widget _buildWooCommerceCard(FlutterFlowTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _wooActive ? theme.primary : theme.alternate, width: _wooActive ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera de la tarjeta
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.sync_alt_rounded, color: Colors.purple, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('WooCommerce Sync Add-on', style: theme.titleLarge.override(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _wooActive ? Colors.green.shade100 : theme.alternate,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _wooActive ? 'ACTIVO' : 'INACTIVO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _wooActive ? Colors.green.shade800 : theme.secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Sincroniza inventario, precios y productos de tu sitio WooCommerce.', style: theme.bodySmall),
                    ],
                  ),
                ),
                Switch(
                  value: _wooActive,
                  activeColor: theme.primary,
                  onChanged: (val) {
                    setState(() => _wooActive = val);
                  },
                ),
              ],
            ),
            const Divider(height: 32),

            // Formulario de Credenciales API
            Text('Credenciales API de tu WooCommerce', style: theme.bodyMedium.override(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            TextField(
              controller: _wooUrlController,
              decoration: InputDecoration(
                labelText: 'URL de tu Tienda WooCommerce',
                hintText: 'https://mi-tienda-woo.com',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.language_rounded),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wooKeyController,
                    decoration: InputDecoration(
                      labelText: 'Consumer Key (ck_...)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.key_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _wooSecretController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Consumer Secret (cs_...)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Botones de Acción
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveWooCredentials,
                  icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save_rounded),
                  label: const Text('Guardar Credenciales'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),
                if (_wooActive)
                  OutlinedButton.icon(
                    onPressed: _isSyncing ? null : _triggerWooSync,
                    icon: _isSyncing ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync_rounded),
                    label: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar Ahora'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonCard(FlutterFlowTheme theme, String title, String subtitle, IconData icon, Color color) {
    return Container(
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
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.bodyMedium.override(fontWeight: FontWeight.bold)),
                Text(subtitle, style: theme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: theme.alternate, borderRadius: BorderRadius.circular(12)),
            child: Text('PRÓXIMAMENTE', style: theme.bodySmall.override(fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
