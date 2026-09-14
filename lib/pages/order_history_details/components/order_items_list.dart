import 'package:flutter/material.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:auto_size_text/auto_size_text.dart';

class OrderItemsList extends StatelessWidget {
  final String orderId;

  const OrderItemsList({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PedidoItemsRow>>(
      future: PedidoItemsTable().queryRows(
        queryFn: (q) => q.eq('pedido_id', orderId),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: SizedBox(
              width: 50.0,
              height: 50.0,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  FlutterFlowTheme.of(context).primary,
                ),
              ),
            ),
          );
        }
        List<PedidoItemsRow> items = snapshot.data!;
        if (items.isEmpty) {
          return const Center(child: Text('No hay productos en este pedido.'));
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _OrderItem(item: item);
          },
        );
      },
    );
  }
}

class _OrderItem extends StatelessWidget {
  final PedidoItemsRow item;

  const _OrderItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductosRow>>(
      future: () {
        debugPrint('DEBUG: Inspeccionando ítem completo: ${item.data}');
        debugPrint('DEBUG: ID del ítem: ${item.id}');
        debugPrint('DEBUG: Product ID del ítem: ${item.productId}');
        
        return ProductosTable().querySingleRow(
          queryFn: (q) => q.eq('id', item.productId ?? ''),
        );
      }(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final producto = snapshot.data!.isNotEmpty ? snapshot.data!.first : null;
        if (producto == null) {
          debugPrint('DEBUG: No se encontró producto para ID: ${item.productId}');
        }

        return Container(
          width: MediaQuery.sizeOf(context).width,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 8.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: CachedNetworkImage(
                    imageUrl: producto?.imagePath?.firstOrNull ?? '',
                    width: 70.0,
                    height: 70.0,
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              valueOrDefault<String>(producto?.nombre, 'Unknown'),
                              style: FlutterFlowTheme.of(context).bodyLarge,
                            ),
                            Text(
                              () {
                                final precioAUsar = item.priceAtPurchase ?? producto?.precio ?? 0.0;
                                return formatNumber(
                                  precioAUsar,
                                  formatType: FormatType.decimal,
                                  decimalType: DecimalType.automatic,
                                );
                              }(),
                              style: FlutterFlowTheme.of(context).titleLarge,
                            ),
                          ],
                        ),
                        AutoSizeText(
                          'Quantity: ${item.quantity?.toString()}',
                          style: FlutterFlowTheme.of(context).labelSmall,
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
