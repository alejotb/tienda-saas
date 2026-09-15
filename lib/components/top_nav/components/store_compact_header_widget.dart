import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/services/store_theme_service.dart';

class StoreCompactHeaderWidget extends StatelessWidget {
  const StoreCompactHeaderWidget({super.key});

  Future<void> _openWhatsApp(String phone, String storeName) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent('¡Hola! Me gustaría hacer una consulta en la tienda $storeName')}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: StoreThemeService.instance,
      builder: (context, _) {
        final store = StoreThemeService.instance.currentStore;
        if (store == null) return const SizedBox.shrink();

        final primaryColor = StoreThemeService.instance.primaryColor;
        final theme = FlutterFlowTheme.of(context);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1400.0),
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withValues(alpha: 0.12),
                  primaryColor.withValues(alpha: 0.04),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                // Icono / Logo Miniatura
                if (store.logoUrl != null && store.logoUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      store.logoUrl!,
                      width: 32.0,
                      height: 32.0,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.storefront_rounded,
                        color: primaryColor,
                        size: 24.0,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      color: primaryColor,
                      size: 18.0,
                    ),
                  ),
                const SizedBox(width: 10.0),

                // Nombre de la Tienda y Verificación
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              store.nombre,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                                color: theme.primaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Icon(
                            Icons.verified_rounded,
                            color: primaryColor,
                            size: 15.0,
                          ),
                        ],
                      ),
                      Text(
                        'Catálogo Oficial • Pedidos directos',
                        style: GoogleFonts.inter(
                          fontSize: 11.0,
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Acciones Rápidas (WhatsApp / Contacto)
                if (store.telefonoContacto != null && store.telefonoContacto!.isNotEmpty)
                  InkWell(
                    onTap: () => _openWhatsApp(store.telefonoContacto!, store.nombre),
                    borderRadius: BorderRadius.circular(8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: const Color(0xFF25D366).withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Color(0xFF16A34A),
                            size: 14.0,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            'WhatsApp',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF16A34A),
                              fontWeight: FontWeight.bold,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
