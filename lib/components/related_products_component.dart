import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:baul_pandora/backend/supabase/database/tables/productos.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_icon_button.dart';
import 'package:baul_pandora/services/favorites_service.dart';
import 'package:baul_pandora/services/cart_service.dart';
import 'package:provider/provider.dart';
import 'package:baul_pandora/app_state.dart';
import 'package:baul_pandora/pages/product_details/product_details_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RelatedProductsComponent extends StatefulWidget {
  final List<ProductosRow> relatedProducts;

  const RelatedProductsComponent({super.key, required this.relatedProducts});

  @override
  State<RelatedProductsComponent> createState() => _RelatedProductsComponentState();
}

class _RelatedProductsComponentState extends State<RelatedProductsComponent> {
  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Productos Relacionados',
            style: FlutterFlowTheme.of(context).titleMedium.override(
              font: GoogleFonts.interTight(),
              letterSpacing: 0.0,
            ),
          ),
        ),
        SizedBox(
          height: 260.0, // Altura reducida
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: widget.relatedProducts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12.0),
            itemBuilder: (context, index) {
              final product = widget.relatedProducts[index];
              return InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  context.pushNamed(
                    ProductDetailsWidget.routeName,
                    queryParameters: {
                      'productRef': serializeParam(product, ParamType.SupabaseRow),
                    }.withoutNulls,
                  );
                },
                child: Container(
                  width: 160.0, // Ancho reducido para que se vean 2.5
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 2.0,
                        color: Color(0x520E151B),
                        offset: Offset(0.0, 1.0),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen grande maximizada
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
                            color: FlutterFlowTheme.of(context).primaryBackground,
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
                            child: product.imagePath?.isNotEmpty == true
                                ? CachedNetworkImage(
                                    imageUrl: product.imagePath!.first,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : Container(),
                          ),
                        ),
                      ),
                      // Título, precio y botones con padding compacto
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              product.nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 13.0,
                                lineHeight: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              '\$${product.precio?.toStringAsFixed(2) ?? '0.00'}',
                              style: FlutterFlowTheme.of(context).bodyLarge.override(
                                fontFamily: 'Inter',
                                color: FlutterFlowTheme.of(context).primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildFavoriteButton(context, product),
                                _buildCartButton(context, product),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24.0), // Padding extra abajo para que respire
      ],
    );
  }

  Widget _buildFavoriteButton(BuildContext context, ProductosRow product) {
    final isFavorite = FFAppState().itemsFavoritos.contains(product.id);
    
    return FlutterFlowIconButton(
      borderColor: Colors.transparent,
      borderRadius: 12.0,
      borderWidth: 1.0,
      buttonSize: 40.0,
      icon: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFavorite ? FlutterFlowTheme.of(context).primary : FlutterFlowTheme.of(context).secondaryText,
        size: 24.0,
      ),
      onPressed: () async {
        await FavoritesService.instance.toggleFavorite(product.id);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFavorite 
                    ? 'Se eliminó ${product.nombre} de tus favoritos'
                    : 'Se agregó ${product.nombre} a tus favoritos',
                style: FlutterFlowTheme.of(context).titleSmall,
              ),
              duration: const Duration(milliseconds: 1000),
              backgroundColor: FlutterFlowTheme.of(context).primary,
            ),
          );
        }
      },
    );
  }

  Widget _buildCartButton(BuildContext context, ProductosRow product) {
    final inCart = FFAppState().itemsCarrito.any((item) => item.idProducto == product.id);
    final isOutOfStock = product.stock == 0;
    
    if (inCart) {
      return Container(
        width: 40.0,
        height: 40.0,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primary,
          borderRadius: BorderRadius.circular(12.0),
        ),
        alignment: const AlignmentDirectional(0.0, 0.0),
        child: Icon(
          Icons.check_rounded,
          color: FlutterFlowTheme.of(context).info,
          size: 24.0,
        ),
      );
    }
    
    return FlutterFlowIconButton(
      borderColor: Colors.transparent,
      borderRadius: 12.0,
      borderWidth: 1.0,
      buttonSize: 40.0,
      fillColor: isOutOfStock 
          ? Colors.grey 
          : FlutterFlowTheme.of(context).accent1,
      icon: Icon(
        Icons.shopping_cart_outlined,
        color: isOutOfStock 
            ? Colors.white70 
            : FlutterFlowTheme.of(context).primaryText,
        size: 22.0,
      ),
      onPressed: () async {
        if (isOutOfStock) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Agrega este producto a tus favoritos y te avisaremos cuando volvamos a tener stock',
                style: FlutterFlowTheme.of(context).titleSmall,
              ),
              duration: const Duration(milliseconds: 1000),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        await CartService.instance.addItem(product.id, product.precio ?? 0.0);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Agregaste ${product.nombre} a tu carrito!',
                style: FlutterFlowTheme.of(context).titleSmall,
              ),
              duration: const Duration(milliseconds: 1000),
              backgroundColor: FlutterFlowTheme.of(context).primary,
            ),
          );
        }
      },
    );
  }
}
