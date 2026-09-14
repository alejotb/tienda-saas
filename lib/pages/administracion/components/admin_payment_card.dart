import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:intl/intl.dart';

class AdminPaymentCard extends StatelessWidget {
  final PedidosRow order;
  final VoidCallback onConfirm;
  final VoidCallback onReject;
  final VoidCallback onTapDetails;

  const AdminPaymentCard({
    super.key,
    required this.order,
    required this.onConfirm,
    required this.onReject,
    required this.onTapDetails,
  });

  Map<String, dynamic> _getDatosPago() {
    if (order.datosPago == null) return {};
    if (order.datosPago is Map) {
      return Map<String, dynamic>.from(order.datosPago as Map);
    }
    return {};
  }

  String _getTipoPago(Map<String, dynamic> datos) {
    final raw = (datos['tipo'] ?? datos['tipo_pago'] ?? datos['metodo'] ?? 'desconocido').toString().toLowerCase();
    if (raw.contains('movil') || raw.contains('móvil') || raw.contains('pago_movil')) {
      return 'pago_movil';
    }
    if (raw.contains('binance') || raw.contains('usdt')) {
      return 'binance';
    }
    if (raw.contains('paypal')) {
      return 'paypal';
    }
    if (raw.contains('zelle')) {
      return 'zelle';
    }
    if (raw.contains('efectivo') || raw.contains('cash')) {
      return 'efectivo';
    }
    if (raw.contains('transfer') || raw.contains('banco')) {
      return 'transferencia';
    }
    return raw;
  }

  PaymentTypeStyle _getStyleForType(String tipo) {
    switch (tipo) {
      case 'pago_movil':
        return PaymentTypeStyle(
          label: 'Pago Móvil',
          color: const Color(0xFF00897B),
          icon: Icons.phone_android_rounded,
          bgColor: const Color(0xFFE0F2F1),
        );
      case 'binance':
        return PaymentTypeStyle(
          label: 'Binance Pay',
          color: const Color(0xFFF59E0B),
          icon: Icons.currency_bitcoin_rounded,
          bgColor: const Color(0xFFFEF3C7),
        );
      case 'paypal':
        return PaymentTypeStyle(
          label: 'PayPal',
          color: const Color(0xFF0284C7),
          icon: Icons.payment_rounded,
          bgColor: const Color(0xFFE0F2FE),
        );
      case 'zelle':
        return PaymentTypeStyle(
          label: 'Zelle',
          color: const Color(0xFF7C3AED),
          icon: Icons.flash_on_rounded,
          bgColor: const Color(0xFFEDE9FE),
        );
      case 'efectivo':
        return PaymentTypeStyle(
          label: 'Efectivo',
          color: const Color(0xFF16A34A),
          icon: Icons.attach_money_rounded,
          bgColor: const Color(0xFFDCFCE7),
        );
      case 'transferencia':
        return PaymentTypeStyle(
          label: 'Transferencia',
          color: const Color(0xFF4F46E5),
          icon: Icons.account_balance_rounded,
          bgColor: const Color(0xFFEEF2FF),
        );
      default:
        return PaymentTypeStyle(
          label: tipo.toUpperCase(),
          color: const Color(0xFF64748B),
          icon: Icons.credit_card_rounded,
          bgColor: const Color(0xFFF1F5F9),
        );
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copiado al portapapeles'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 300,
                      color: Colors.black54,
                      child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.black87,
                    child: const Center(
                      child: Text('No se pudo cargar la imagen', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final datos = _getDatosPago();
    final tipoKey = _getTipoPago(datos);
    final style = _getStyleForType(tipoKey);

    final String clientName = order.nombreCliente?.isNotEmpty == true ? order.nombreCliente! : 'Cliente sin nombre';
    final String clientEmail = order.emailCliente ?? '';
    final double montoUsd = order.totalPrice ?? order.total ?? 0.0;
    final num? montoVes = datos['montoVes'] ?? datos['monto_ves'] ?? datos['montoBs'] ?? datos['monto_bs'];
    final num? tasa = datos['tasaAplicada'] ?? datos['tasa_aplicada'] ?? datos['tasa'];
    final String? referencia = datos['referencia']?.toString() ?? datos['ref']?.toString();
    final String? comprobanteUrl = datos['comprobanteUrl'] ?? datos['comprobante_url'];
    final Map<String, dynamic>? aiData = datos['ai_data'] is Map ? Map<String, dynamic>.from(datos['ai_data'] as Map) : null;

    final String formattedDate = DateFormat('dd/MM · HH:mm').format(order.createdAt);
    final String shortId = order.id.length > 8 ? order.id.substring(0, 8).toUpperCase() : order.id.toUpperCase();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 520;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14.0),
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: theme.alternate,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Badge del método + ID + Fecha
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 8 : 10,
                              vertical: isMobile ? 4 : 5,
                            ),
                            decoration: BoxDecoration(
                              color: style.bgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: style.color.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(style.icon, size: isMobile ? 12 : 14, color: style.color),
                                const SizedBox(width: 5),
                                Text(
                                  style.label,
                                  style: theme.bodySmall.override(
                                    fontFamily: 'Inter',
                                    color: style.color,
                                    fontSize: isMobile ? 11 : 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '#$shortId',
                            style: theme.bodySmall.override(
                              fontFamily: 'Inter',
                              color: theme.secondaryText,
                              fontSize: isMobile ? 11 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: theme.bodySmall.override(
                        fontFamily: 'Inter',
                        color: theme.secondaryText,
                        fontSize: isMobile ? 11 : 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, thickness: 1),

              // 2. Body: Info del Cliente + Campos específicos del método
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cliente y Monto Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clientName,
                                style: theme.titleMedium.override(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (clientEmail.isNotEmpty)
                                Text(
                                  clientEmail,
                                  style: theme.bodySmall.override(
                                    fontFamily: 'Inter',
                                    color: theme.secondaryText,
                                    fontSize: isMobile ? 11 : 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${montoUsd.toStringAsFixed(2)} USD',
                              style: theme.titleMedium.override(
                                fontFamily: 'Inter',
                                color: theme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                            if (montoVes != null && montoVes > 0)
                              Text(
                                'Bs. ${NumberFormat("#,##0.00", "es_VE").format(montoVes)}',
                                style: theme.bodySmall.override(
                                  fontFamily: 'Inter',
                                  color: const Color(0xFF00897B),
                                  fontSize: isMobile ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Contenedor de detalles específicos por método
                    _buildSpecificDetails(context, theme, tipoKey, datos, referencia, tasa),

                    // Análisis IA si existe
                    if (aiData != null) ...[
                      const SizedBox(height: 8),
                      _buildAiSummaryBadge(theme, aiData),
                    ],
                  ],
                ),
              ),

              // 3. Footer: Acciones Rápidas Responsive
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.primaryBackground.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    // Botón Comprobante
                    if (comprobanteUrl != null && comprobanteUrl.isNotEmpty) ...[
                      Tooltip(
                        message: 'Ver comprobante',
                        child: ElevatedButton.icon(
                          onPressed: () => _showImagePreview(context, comprobanteUrl),
                          icon: const Icon(Icons.image_rounded, size: 16),
                          label: isMobile ? const SizedBox.shrink() : const Text('Comprobante'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary.withValues(alpha: 0.12),
                            foregroundColor: theme.primary,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 10 : 12,
                              vertical: isMobile ? 10 : 8,
                            ),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(color: theme.primary.withValues(alpha: 0.3)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ] else ...[
                      Tooltip(
                        message: 'Sin foto de comprobante',
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 8 : 8,
                            vertical: isMobile ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.alternate.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hide_image_outlined, size: 16, color: theme.secondaryText),
                              if (!isMobile) ...[
                                const SizedBox(width: 4),
                                Text(
                                  'Sin foto',
                                  style: theme.bodySmall.override(
                                    fontFamily: 'Inter',
                                    color: theme.secondaryText,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Botón Ver Detalle completo
                    Tooltip(
                      message: 'Detalle completo del pedido',
                      child: IconButton(
                        icon: Icon(Icons.info_outline_rounded, color: theme.secondaryText, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                        onPressed: onTapDetails,
                      ),
                    ),

                    const Spacer(),

                    // Botón Rechazar
                    Tooltip(
                      message: 'Rechazar pago',
                      child: ElevatedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: isMobile ? const SizedBox.shrink() : const Text('Rechazar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red.shade700,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 10 : 12,
                            vertical: isMobile ? 10 : 8,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.red.shade200),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Botón Aprobar / Confirmar
                    Tooltip(
                      message: 'Aprobar pago',
                      child: ElevatedButton.icon(
                        onPressed: onConfirm,
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: isMobile ? const SizedBox.shrink() : const Text('Aprobar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 14,
                            vertical: isMobile ? 10 : 8,
                          ),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSpecificDetails(
    BuildContext context,
    FlutterFlowTheme theme,
    String tipo,
    Map<String, dynamic> datos,
    String? referencia,
    num? tasa,
  ) {
    switch (tipo) {
      case 'pago_movil':
      case 'transferencia':
        final String? bancoEnv = datos['bancoEnviado'] ?? datos['banco_enviado'] ?? datos['banco_origen'];
        final String? bancoRec = datos['bancoRecibido'] ?? datos['banco_recibido'] ?? datos['banco_destino'];
        final String? telf = datos['numeroTelefono'] ?? datos['numero_telefono'] ?? datos['telefono'];

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.alternate),
          ),
          child: Column(
            children: [
              if (bancoEnv != null || bancoRec != null)
                _buildInfoRow(
                  theme,
                  icon: Icons.account_balance_outlined,
                  label: 'Banco:',
                  value: ' ➔ ',
                ),
              if (telf != null && telf.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildInfoRow(
                  theme,
                  icon: Icons.phone_iphone_outlined,
                  label: 'Teléfono:',
                  value: telf,
                  onCopy: () => _copyToClipboard(context, telf, 'Teléfono'),
                ),
              ],
              if (referencia != null && referencia.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildInfoRow(
                  theme,
                  icon: Icons.tag_rounded,
                  label: 'Referencia:',
                  value: referencia,
                  isHighlight: true,
                  onCopy: () => _copyToClipboard(context, referencia, 'Referencia'),
                ),
              ],
              if (tasa != null && tasa > 0) ...[
                const SizedBox(height: 4),
                _buildInfoRow(
                  theme,
                  icon: Icons.currency_exchange_rounded,
                  label: 'Tasa aplicada:',
                  value: ' Bs/\$',
                ),
              ],
            ],
          ),
        );

      case 'binance':
        final String? binanceId = datos['email'] ?? datos['binance_id'] ?? datos['pay_id'];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.alternate),
          ),
          child: Column(
            children: [
              if (binanceId != null && binanceId.isNotEmpty)
                _buildInfoRow(
                  theme,
                  icon: Icons.badge_outlined,
                  label: 'Pay ID / Email:',
                  value: binanceId,
                  onCopy: () => _copyToClipboard(context, binanceId, 'Binance ID'),
                ),
              if (referencia != null && referencia.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildInfoRow(
                  theme,
                  icon: Icons.tag_rounded,
                  label: 'Order ID / Tx:',
                  value: referencia,
                  isHighlight: true,
                  onCopy: () => _copyToClipboard(context, referencia, 'Referencia Binance'),
                ),
              ],
            ],
          ),
        );

      case 'paypal':
        final String? paypalEmail = datos['email'] ?? datos['paypal_email'];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.alternate),
          ),
          child: Column(
            children: [
              if (paypalEmail != null && paypalEmail.isNotEmpty)
                _buildInfoRow(
                  theme,
                  icon: Icons.email_outlined,
                  label: 'Correo PayPal:',
                  value: paypalEmail,
                  onCopy: () => _copyToClipboard(context, paypalEmail, 'Correo PayPal'),
                ),
              if (referencia != null && referencia.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildInfoRow(
                  theme,
                  icon: Icons.tag_rounded,
                  label: 'ID Transacción:',
                  value: referencia,
                  isHighlight: true,
                  onCopy: () => _copyToClipboard(context, referencia, 'ID Transacción'),
                ),
              ],
            ],
          ),
        );

      case 'zelle':
        final String? titular = datos['nombre'] ?? datos['titular'];
        final String? zelleContact = datos['email'] ?? datos['numeroTelefono'] ?? datos['telefono'];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.alternate),
          ),
          child: Column(
            children: [
              if (titular != null && titular.isNotEmpty)
                _buildInfoRow(
                  theme,
                  icon: Icons.person_outline_rounded,
                  label: 'Titular Zelle:',
                  value: titular,
                ),
              if (zelleContact != null && zelleContact.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildInfoRow(
                  theme,
                  icon: Icons.contact_mail_outlined,
                  label: 'Contacto Zelle:',
                  value: zelleContact,
                  onCopy: () => _copyToClipboard(context, zelleContact, 'Contacto Zelle'),
                ),
              ],
              if (referencia != null && referencia.isNotEmpty) ...[
                const SizedBox(height: 4),
                _buildInfoRow(
                  theme,
                  icon: Icons.tag_rounded,
                  label: 'Referencia:',
                  value: referencia,
                  isHighlight: true,
                  onCopy: () => _copyToClipboard(context, referencia, 'Referencia Zelle'),
                ),
              ],
            ],
          ),
        );

      default:
        return referencia != null && referencia.isNotEmpty
            ? Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.primaryBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.alternate),
                ),
                child: _buildInfoRow(
                  theme,
                  icon: Icons.tag_rounded,
                  label: 'Referencia:',
                  value: referencia,
                  isHighlight: true,
                  onCopy: () => _copyToClipboard(context, referencia, 'Referencia'),
                ),
              )
            : const SizedBox.shrink();
    }
  }

  Widget _buildInfoRow(
    FlutterFlowTheme theme, {
    required IconData icon,
    required String label,
    required String value,
    bool isHighlight = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: theme.secondaryText),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.bodySmall.override(
            fontFamily: 'Inter',
            color: theme.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: theme.bodySmall.override(
              fontFamily: 'Inter',
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? theme.primaryText : theme.secondaryText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onCopy != null)
          InkWell(
            onTap: onCopy,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(3.0),
              child: Icon(Icons.copy_rounded, size: 14, color: theme.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildAiSummaryBadge(FlutterFlowTheme theme, Map<String, dynamic> aiData) {
    final bool valido = aiData['valido'] == true;
    final String? detectedRef = aiData['referencia'];
    final dynamic detectedAmount = aiData['monto'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: valido ? Colors.green.withValues(alpha: 0.08) : Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: valido ? Colors.green.withValues(alpha: 0.3) : Colors.amber.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            valido ? Icons.smart_toy_outlined : Icons.warning_amber_rounded,
            size: 15,
            color: valido ? Colors.green.shade700 : Colors.amber.shade800,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              valido
                  ? 'IA: Verificado (${detectedAmount != null ? "\$$detectedAmount" : ""} ${detectedRef != null ? "Ref: $detectedRef" : ""})'
                  : 'IA: Revisión sugerida en comprobante',
              style: theme.bodySmall.override(
                fontFamily: 'Inter',
                color: valido ? Colors.green.shade800 : Colors.amber.shade900,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentTypeStyle {
  final String label;
  final Color color;
  final Color bgColor;
  final IconData icon;

  PaymentTypeStyle({
    required this.label,
    required this.color,
    required this.bgColor,
    required this.icon,
  });
}
