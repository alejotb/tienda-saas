import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/services/store_service.dart';
import 'package:baul_pandora/services/store_theme_service.dart';

class AdminCustomDomainView extends StatefulWidget {
  const AdminCustomDomainView({super.key});

  @override
  State<AdminCustomDomainView> createState() => _AdminCustomDomainViewState();
}

class _AdminCustomDomainViewState extends State<AdminCustomDomainView> {
  bool _isLoading = true;
  StoreData? _store;
  late TextEditingController _domainController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _domainController = TextEditingController();
    _loadStoreData();
  }

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    setState(() => _isLoading = true);
    try {
      final store = await StoreService.instance.getMyStore();
      _store = store;
      if (store != null) {
        _domainController.text = store.dominioPersonalizado ?? '';
      }
    } catch (e) {
      debugPrint('Error cargando dominio de la tienda: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDomain() async {
    if (_store == null || _isSaving) return;

    final isPro = _store!.plan.toLowerCase() == 'pro' || _store!.plan.toLowerCase() == 'premium';
    if (!isPro) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔒 La vinculación de dominios personalizados es una función exclusiva del Plan Pro.'),
          backgroundColor: Colors.purple,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final rawDomain = _domainController.text.trim();

    setState(() => _isSaving = true);
    try {
      final success = await StoreService.instance.updateCustomDomain(
        _store!.id,
        rawDomain.isNotEmpty ? rawDomain : null,
      );

      if (success) {
        await _loadStoreData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(rawDomain.isNotEmpty
                  ? '✅ Dominio "$rawDomain" guardado. Configura tus registros DNS para completar la conexión.'
                  : 'Dominio personalizado desvinculado.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar dominio: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📋 $label copiado al portapapeles'), duration: const Duration(seconds: 2)),
    );
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
    final hasDomain = _store!.dominioPersonalizado != null && _store!.dominioPersonalizado!.isNotEmpty;

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
                      'Dominio Personalizado',
                      style: theme.headlineMedium.override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Conecta tu propio dominio (ej: www.mitienda.com) para darle identidad profesional a tu marca',
                      style: theme.bodySmall.override(color: theme.secondaryText),
                    ),
                  ],
                ),
                if (!isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.purple),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded, size: 16, color: Colors.purple),
                        SizedBox(width: 6),
                        Text('FUNCIÓN PRO', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Estado del Dominio
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
                  Text('Enlace Actual de la Tienda', style: theme.bodySmall.override(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.link_rounded, color: Colors.grey, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'app.com/${_store!.slug}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => _copyToClipboard('https://app.com/${_store!.slug}', 'Enlace'),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copiar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Formulario de Dominio Personalizado
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: hasDomain ? Colors.green.withValues(alpha: 0.4) : theme.alternate),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tu Dominio Propio', style: theme.titleMedium.override(fontWeight: FontWeight.bold)),
                      if (hasDomain)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 14, color: Colors.green),
                              SizedBox(width: 4),
                              Text('Conectado', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _domainController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de Dominio o Subdominio',
                      hintText: 'ej: www.mitienda.com o tienda.mimarca.com',
                      prefixIcon: const Icon(Icons.language_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      filled: true,
                      fillColor: theme.primaryBackground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveDomain,
                    icon: _isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_isSaving ? 'Guardando...' : 'Guardar y Vincular Dominio'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Instrucciones DNS
            Text('Instrucciones de Configuración DNS', style: theme.titleLarge.override(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Ingresa al panel de control de tu proveedor de dominio (GoDaddy, Namecheap, Cloudflare, etc.) y añade estos registros:',
              style: theme.bodySmall.override(color: theme.secondaryText),
            ),
            const SizedBox(height: 16),

            _buildDnsRecordCard(
              theme: theme,
              type: 'CNAME',
              host: 'www',
              target: 'cname.mitienda-saas.com',
              purpose: 'Redirige www.mitienda.com hacia el servidor de la tienda',
            ),
            const SizedBox(height: 12),
            _buildDnsRecordCard(
              theme: theme,
              type: 'A',
              host: '@',
              target: '199.36.158.100',
              purpose: 'Redirige el dominio raíz (mitienda.com)',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDnsRecordCard({
    required FlutterFlowTheme theme,
    required String type,
    required String host,
    required String target,
    required String purpose,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(type, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              Text('Host / Nombre: ', style: theme.bodySmall),
              Text(host, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16),
                onPressed: () => _copyToClipboard(target, 'Destino $type'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Valor / Destino: ', style: theme.bodySmall),
              SelectableText(
                target,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(purpose, style: theme.bodySmall.override(color: theme.secondaryText, fontSize: 11)),
        ],
      ),
    );
  }
}
