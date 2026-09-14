import '/flutter_flow/flutter_flow_theme.dart';
import '/backend/supabase/supabase.dart';
import '/services/cart_service.dart';
import '/services/favorites_service.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '/pages/full_cart_view/full_cart_view_model.dart';
import '/flutter_flow/custom_functions.dart' as functions;

class CartListComponent extends StatelessWidget {
  const CartListComponent({
    super.key,
    required this.items,
    required this.onUpdate,
  });

  final List<dynamic> items; // Cambiar tipo según tu estructura real
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      primary: false,
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _CartItem(item: item, onUpdate: onUpdate);
      },
    );
  }
}

class _CartItem extends StatelessWidget {
  final dynamic item;
  final VoidCallback onUpdate;

  const _CartItem({required this.item, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleWidth = screenWidth <= 450 ? 130.0 : 250.0;

    return FutureBuilder<List<ProductosRow>>(
      future: ProductosTable().querySingleRow(queryFn: (q) => q.eq('id', item.idProducto)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final product = snapshot.data!.isNotEmpty ? snapshot.data!.first : null;
        if (product == null) return const SizedBox.shrink();

        // Check stock
        final bool isOutOfStock = (product.stock ?? 0) <= 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isOutOfStock 
                  ? FlutterFlowTheme.of(context).primaryBackground.withOpacity(0.5)
                  : FlutterFlowTheme.of(context).secondaryBackground,
              boxShadow: [BoxShadow(color: FlutterFlowTheme.of(context).alternate, offset: const Offset(0, 1))],
            ),
            child: Row(
              children: [
                Checkbox(
                  // Disable selection if out of stock
                  value: isOutOfStock ? false : context.watch<FullCartViewModel>().selectedItemIds.contains(item.idProducto),
                  onChanged: isOutOfStock ? null : (val) {
                    context.read<FullCartViewModel>().toggleSelection(item.idProducto);
                    onUpdate();
                  },
                  activeColor: FlutterFlowTheme.of(context).primary,
                ),
                GestureDetector(
                  onTap: isOutOfStock ? null : () {
                    context.read<FullCartViewModel>().toggleSelection(item.idProducto);
                    onUpdate();
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: ColorFiltered(
                      colorFilter: isOutOfStock 
                          ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                          : const ColorFilter.mode(Colors.transparent, BlendMode.srcOver),
                      child: CachedNetworkImage(
                        imageUrl: functions.getProxyUrl(product.imagePath?.firstOrNull),
                        width: 70.0,
                        height: 70.0,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Expanded( // Flexible name container
                  child: GestureDetector(
                    onTap: isOutOfStock ? null : () {
                      context.read<FullCartViewModel>().toggleSelection(item.idProducto);
                      onUpdate();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${product.nombre ?? 'Unknown'}',
                            style: FlutterFlowTheme.of(context).titleMedium.override(
                              fontFamily: 'Inter',
                              color: isOutOfStock ? FlutterFlowTheme.of(context).secondaryText : FlutterFlowTheme.of(context).primaryText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isOutOfStock)
                            Text(
                              'AGOTADO',
                              style: FlutterFlowTheme.of(context).bodySmall.override(
                                fontFamily: 'Inter',
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container( // Fixed width container for controls to keep them aligned
                  width: 100, 
                  alignment: Alignment.centerRight,
                  child: isOutOfStock
                      ? _OutOfStockAction(
                          item: item,
                          onUpdate: onUpdate,
                        )
                      : _QuantityControls(
                          item: item,
                          product: product,
                          onUpdate: onUpdate,
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

class _OutOfStockAction extends StatelessWidget {
  final dynamic item;
  final VoidCallback onUpdate;

  const _OutOfStockAction({required this.item, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: TextButton(
            onPressed: () async {
              await FavoritesService.instance.toggleFavorite(item.idProducto);
              await CartService.instance.removeItem(item.idProducto, 0.0); // Precio no importa para remover
              onUpdate();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Movido a favoritos. Te avisaremos cuando haya stock',
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                  backgroundColor: FlutterFlowTheme.of(context).primary,
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.favorite, color: FlutterFlowTheme.of(context).primary, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Mover a Favoritos',
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          fontFamily: 'Inter',
                          color: FlutterFlowTheme.of(context).primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuantityControls extends StatelessWidget {
  final dynamic item;
  final ProductosRow product;
  final VoidCallback onUpdate;

  const _QuantityControls({required this.item, required this.product, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final bool isOutOfStock = (product.stock ?? 0) <= 0;
    
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: isOutOfStock ? null : () async {
                if (item.cantidad > 1) {
                  await CartService.instance.decrementItem(item.idProducto, product.precio ?? 0.0);
                  onUpdate();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), 
                child: Text('-', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isOutOfStock ? Colors.grey : FlutterFlowTheme.of(context).primaryText))),
            ),
            Text('${item.cantidad}', style: FlutterFlowTheme.of(context).titleMedium),
            InkWell(
              onTap: isOutOfStock || item.cantidad >= (product.stock ?? 0) ? null : () async {
                await CartService.instance.addItem(item.idProducto, product.precio ?? 0.0);
                onUpdate();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0), 
                child: Text('+', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: (isOutOfStock || item.cantidad >= (product.stock ?? 0)) ? Colors.grey : FlutterFlowTheme.of(context).primaryText))),
            ),
          ],
        ),
      ],
    );
  }
}
