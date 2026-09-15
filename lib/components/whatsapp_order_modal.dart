import 'package:flutter/material.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/services/whatsapp_order_service.dart';
import 'package:baul_pandora/services/store_theme_service.dart';
import 'package:baul_pandora/services/cart_service.dart';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';
import 'package:baul_pandora/app_state.dart';

class WhatsAppOrderModal extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double total;
  final double bcvRate;
  final VoidCallback? onOrderPlaced;

  const WhatsAppOrderModal({
    super.key,
    required this.items,
    required this.subtotal,
    required this.total,
    required this.bcvRate,
    this.onOrderPlaced,
  });

  @override
  State<WhatsAppOrderModal> createState() => _WhatsAppOrderModalState();
}

class _WhatsAppOrderModalState extends State<WhatsAppOrderModal> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _refController;
  late TextEditingController _notesController;

  String _deliveryType = 'domicilio'; // 'domicilio' o 'retiro'
  String _paymentMethod = 'Pago Móvil';
  bool _isSubmitting = false;

  final List<String> _paymentMethods = [
    'Pago Móvil',
    'Transferencia Bancaria',
    'Efectivo / Divisas',
    'Binance Pay',
    'Zelle',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: currentUserDisplayName);
    _phoneController = TextEditingController(text: currentPhoneNumber);
    _addressController = TextEditingController();
    _refController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final activeStore = StoreThemeService.instance.currentStore;
      final storeName = activeStore?.nombre ?? 'Mi Tienda';
      final storePhone = activeStore?.telefonoContacto ?? '';
      final storeId = activeStore?.id ?? FFAppState().activeStoreId;

      final orderItems = widget.items.map((e) => WhatsAppOrderItem.fromMap(e)).toList();

      final customerInfo = WhatsAppOrderCustomerInfo(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        deliveryType: _deliveryType,
        address: _deliveryType == 'domicilio' ? _addressController.text.trim() : 'Retiro en Tienda',
        paymentMethod: _paymentMethod,
        paymentReference: _refController.text.trim().isNotEmpty ? _refController.text.trim() : null,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      final launched = await WhatsAppOrderService.instance.submitAndOpenWhatsApp(
        storeId: storeId,
        storeName: storeName,
        storePhone: storePhone,
        items: orderItems,
        totalUsd: widget.total,
        bcvRate: widget.bcvRate,
        customer: customerInfo,
      );

      // Limpiar carrito local
      for (final item in widget.items) {
        final id = item['id']?.toString() ?? '';
        final price = (item['precio'] as num?)?.toDouble() ?? 0.0;
        if (id.isNotEmpty) {
          await CartService.instance.removeItem(id, price);
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onOrderPlaced?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(launched
                ? '✅ ¡Pedido registrado! Redirigiendo a WhatsApp...'
                : '✅ Pedido registrado con éxito en la tienda.'),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar pedido: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: isMobile ? 16 : 24,
      ),
      child: Container(
        width: 580,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(theme),

            // Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Resumen rápido de compra
                      _buildOrderMiniSummary(theme),
                      const SizedBox(height: 20),

                      // Datos de Contacto
                      Text('Datos del Comprador', style: theme.bodyMedium.override(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nombre y Apellido *',
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: theme.primaryBackground,
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Ingresa tu nombre' : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Teléfono / WhatsApp *',
                          prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                          hintText: 'Ej: 04121234567',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: theme.primaryBackground,
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Ingresa tu teléfono' : null,
                      ),
                      const SizedBox(height: 20),

                      // Tipo de Entrega
                      Text('Método de Entrega', style: theme.bodyMedium.override(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDeliveryOption(
                              label: 'Envío a Domicilio',
                              icon: Icons.delivery_dining_rounded,
                              value: 'domicilio',
                              theme: theme,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDeliveryOption(
                              label: 'Retiro en Tienda',
                              icon: Icons.storefront_rounded,
                              value: 'retiro',
                              theme: theme,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_deliveryType == 'domicilio') ...[
                        TextFormField(
                          controller: _addressController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Dirección de Entrega *',
                            hintText: 'Ciudad, zona, calle, edificio/casa, punto de referencia...',
                            prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: theme.primaryBackground,
                          ),
                          validator: (val) {
                            if (_deliveryType == 'domicilio' && (val == null || val.trim().isEmpty)) {
                              return 'Ingresa tu dirección de entrega';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Método de Pago
                      Text('Forma de Pago Preferida', style: theme.bodyMedium.override(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: theme.primaryBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.alternate),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _paymentMethod,
                            isExpanded: true,
                            items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _paymentMethod = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Referencia (Opcional)
                      TextFormField(
                        controller: _refController,
                        decoration: InputDecoration(
                          labelText: 'Número de Referencia / Comprobante (Opcional)',
                          hintText: 'Si ya realizaste el pago, coloca los últimos 4-6 dígitos',
                          prefixIcon: const Icon(Icons.receipt_long_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: theme.primaryBackground,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Notas adicionales
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Notas o Instrucciones Especiales (Opcional)',
                          prefixIcon: const Icon(Icons.comment_outlined, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: theme.primaryBackground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer Button
            _buildFooter(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(bottom: BorderSide(color: theme.alternate)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completar Pedido por WhatsApp',
                  style: theme.titleMedium.override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                ),
                Text(
                  'Enviaremos el desglose directamente a la tienda para coordinar el pago',
                  style: theme.bodySmall.override(color: theme.secondaryText, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
            color: theme.secondaryText,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderMiniSummary(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.items.length} productos en la orden', style: theme.bodySmall),
              const SizedBox(height: 2),
              Text(
                'Total: \$${widget.total.toStringAsFixed(2)} USD',
                style: theme.titleMedium.override(fontFamily: 'Inter', fontWeight: FontWeight.bold, color: const Color(0xFF16A34A)),
              ),
            ],
          ),
          if (widget.bcvRate > 0)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Tasa BCV: ${widget.bcvRate.toStringAsFixed(2)}', style: theme.bodySmall.override(fontSize: 10)),
                const SizedBox(height: 2),
                Text(
                  'Bs. ${(widget.total * widget.bcvRate).toStringAsFixed(2)}',
                  style: theme.bodyMedium.override(fontWeight: FontWeight.bold),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption({
    required String label,
    required IconData icon,
    required String value,
    required FlutterFlowTheme theme,
  }) {
    final isSelected = _deliveryType == value;

    return InkWell(
      onTap: () => setState(() => _deliveryType = value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF16A34A).withValues(alpha: 0.1) : theme.primaryBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF16A34A) : theme.alternate,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: isSelected ? const Color(0xFF16A34A) : theme.secondaryText),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF16A34A) : theme.primaryText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(FlutterFlowTheme theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: theme.alternate)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Volver al Carrito'),
          ),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _handleConfirm,
            icon: _isSubmitting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_isSubmitting ? 'Procesando...' : 'Confirmar y Pedir por WhatsApp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
