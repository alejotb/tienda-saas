import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_widgets.dart';
import 'package:baul_pandora/services/store_service.dart';
import 'package:baul_pandora/services/whatsapp_order_service.dart';

class WhatsAppConnectionModal extends StatefulWidget {
  const WhatsAppConnectionModal({
    super.key,
    this.store,
    this.onSaved,
  });

  final StoreData? store;
  final VoidCallback? onSaved;

  static Future<void> show(BuildContext context, {StoreData? store, VoidCallback? onSaved}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: MediaQuery.viewInsetsOf(ctx),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: WhatsAppConnectionModal(store: store, onSaved: onSaved),
        ),
      ),
    );
  }

  @override
  State<WhatsAppConnectionModal> createState() => _WhatsAppConnectionModalState();
}

class _WhatsAppConnectionModalState extends State<WhatsAppConnectionModal> {
  final _phoneController = TextEditingController();
  bool _whatsappActivo = true;
  bool _whatsappConfirmado = false;
  bool _isLoading = true;
  bool _isSaving = false;
  StoreData? _currentStore;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    setState(() => _isLoading = true);
    try {
      final store = widget.store ?? await StoreService.instance.getMyStore();
      _currentStore = store;
      if (store != null) {
        _phoneController.text = store.telefonoContacto ?? '';
        _whatsappActivo = store.whatsappActivo;
        _whatsappConfirmado = store.whatsappConfirmado;
      }
    } catch (e) {
      debugPrint('Error cargando datos de tienda para WhatsApp: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendTestMessage() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un número de teléfono primero.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final cleanPhone = WhatsAppOrderService.instance.cleanPhoneNumber(phone);
    final storeName = _currentStore?.nombre ?? 'Mi Tienda';
    final testMsg = '👋 ¡Hola! Mensaje de prueba de conexión de WhatsApp para *$storeName* en Baúl de Pandora.';
    final encoded = Uri.encodeComponent(testMsg);
    final url = Uri.parse('https://wa.me/$cleanPhone?text=$encoded');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveWhatsAppConfig() async {
    if (_currentStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró información de la tienda.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final success = await StoreService.instance.updateStoreWhatsApp(
        storeId: _currentStore!.id,
        phone: _phoneController.text.trim(),
        activo: _whatsappActivo,
        confirmado: _whatsappConfirmado,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Conexión de WhatsApp guardada exitosamente!'),
              backgroundColor: Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
          widget.onSaved?.call();
          Navigator.of(context).pop();
        }
      } else {
        throw Exception('Error al guardar en la base de datos.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error guardando configuración: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Modal Handle
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.alternate,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.whatsapp,
                          color: Color(0xFF25D366),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conexión con WhatsApp',
                              style: theme.titleMedium.override(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.0,
                              ),
                            ),
                            Text(
                              'Gestiona la recepción de pedidos directos',
                              style: theme.bodySmall.override(
                                fontFamily: 'Inter',
                                color: theme.secondaryText,
                                letterSpacing: 0.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Body
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      // Status Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _whatsappConfirmado
                              ? const Color(0xFF16A34A).withOpacity(0.08)
                              : Colors.amber.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _whatsappConfirmado
                                ? const Color(0xFF16A34A).withOpacity(0.3)
                                : Colors.amber.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _whatsappConfirmado
                                  ? Icons.verified_rounded
                                  : Icons.info_outline_rounded,
                              color: _whatsappConfirmado
                                  ? const Color(0xFF16A34A)
                                  : Colors.amber.shade800,
                              size: 28,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _whatsappConfirmado
                                        ? 'WhatsApp Verificado y Activo'
                                        : 'Pendiente de Confirmación',
                                    style: theme.bodyMedium.override(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.bold,
                                      color: _whatsappConfirmado
                                          ? const Color(0xFF16A34A)
                                          : Colors.amber.shade900,
                                      letterSpacing: 0.0,
                                    ),
                                  ),
                                  Text(
                                    _whatsappConfirmado
                                        ? 'Tus clientes recibirán el enlace directo para enviar pedidos a este número.'
                                        : 'Configura tu número y envía un mensaje de prueba para verificarlo.',
                                    style: theme.bodySmall.override(
                                      fontFamily: 'Inter',
                                      color: theme.secondaryText,
                                      letterSpacing: 0.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Toggle Enable/Disable
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.primaryBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.alternate),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Activar pedidos por WhatsApp',
                                    style: theme.bodyMedium.override(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.0,
                                    ),
                                  ),
                                  Text(
                                    'Permite el botón de checkout rápido por WhatsApp en el carrito',
                                    style: theme.bodySmall.override(
                                      fontFamily: 'Inter',
                                      color: theme.secondaryText,
                                      letterSpacing: 0.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: _whatsappActivo,
                              onChanged: (v) => setState(() => _whatsappActivo = v),
                              activeColor: const Color(0xFF25D366),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Phone Input Field
                      Text(
                        'Número de WhatsApp Comercial',
                        style: theme.bodyMedium.override(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '+58 412 1234567 o 04121234567',
                          hintStyle: TextStyle(color: theme.secondaryText),
                          prefixIcon: const Icon(Icons.phone_outlined),
                          filled: true,
                          fillColor: theme.primaryBackground,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.alternate),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: theme.alternate),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Test Message Button
                      OutlinedButton.icon(
                        onPressed: _sendTestMessage,
                        icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18, color: Color(0xFF25D366)),
                        label: const Text('Enviar mensaje de prueba a WhatsApp'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF25D366)),
                          foregroundColor: const Color(0xFF25D366),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Confirmation Checkbox
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.primaryBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.alternate),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Confirmar y verificar este número',
                              style: theme.bodyMedium.override(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.0,
                              ),
                            ),
                            subtitle: Text(
                              'He comprobado que el número recibe mensajes correctamente',
                              style: theme.bodySmall.override(
                                fontFamily: 'Inter',
                                color: theme.secondaryText,
                                letterSpacing: 0.0,
                              ),
                            ),
                            value: _whatsappConfirmado,
                            activeColor: const Color(0xFF25D366),
                            onChanged: (v) => setState(() => _whatsappConfirmado = v ?? false),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Save Footer Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: FFButtonWidget(
                    onPressed: _isSaving ? null : _saveWhatsAppConfig,
                    text: _isSaving ? 'Guardando...' : 'Guardar Configuración',
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 50,
                      color: const Color(0xFF25D366),
                      textStyle: theme.titleSmall.override(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.0,
                      ),
                      elevation: 2,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
