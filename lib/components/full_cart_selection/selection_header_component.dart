import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/full_cart_view/full_cart_view_model.dart';

class SelectionHeaderComponent extends StatelessWidget {
  const SelectionHeaderComponent({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<FullCartViewModel>();
    final activeTab = model.activeTab;

    if (activeTab == 'carrito') {
      final allIds = FFAppState().itemsCarrito.map((e) => e.idProducto).toList();
      final allSelected = model.isAllSelected(allIds);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          border: Border(
            bottom: BorderSide(color: FlutterFlowTheme.of(context).alternate, width: 1),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: allSelected,
              onChanged: (val) async {
                if (val == true) {
                  // Filtramos los productos que tienen stock
                  final cartItems = FFAppState().itemsCarrito;
                  final List<String> availableIds = [];
                  
                  for (var item in cartItems) {
                     // Obtenemos info de stock de la cache o servicio si es posible.
                     // Dado que no tenemos un mapa de stock, asumimos que necesitamos obtenerlo.
                     // Por ahora, para la implementación, necesitamos asegurar que solo seleccionamos los que tienen stock.
                     // Como no es inmediato, vamos a asumir que podemos obtener el stock del servicio o componente.
                     
                     // REVISIÓN: El 'CartListComponent' ya maneja la lógica de 'isOutOfStock'.
                     // Debemos replicar esa verificación aquí.
                     
                     final products = await ProductosTable().querySingleRow(queryFn: (q) => q.eq('id', item.idProducto));
                     final product = products.isNotEmpty ? products.first : null;
                     if (product != null && (product.stock ?? 0) > 0) {
                        availableIds.add(item.idProducto);
                     }
                  }
                  model.selectAll(availableIds);
                } else {
                  model.deselectAll();
                }
              },
              activeColor: FlutterFlowTheme.of(context).primary,
            ),
            const SizedBox(width: 8),
            Text(
              allSelected ? 'Deseleccionar todo' : 'Seleccionar todo',
              style: FlutterFlowTheme.of(context).bodyMedium,
            ),
            const Spacer(),
            Text(
              '${model.selectedItemIds.length} seleccionados',
              style: FlutterFlowTheme.of(context).bodySmall,
            ),
          ],
        ),
      );
    } else {
      final allSelected = model.areAllApartadosSelected();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          border: Border(
            bottom: BorderSide(color: FlutterFlowTheme.of(context).alternate, width: 1),
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: allSelected,
              onChanged: (val) {
                if (val == true) {
                  model.selectAllApartados();
                } else {
                  model.deselectAllApartados();
                }
                // Forzar reconstrucción si el componente no escucha automáticamente
                (context as Element).markNeedsBuild();
              },
              activeColor: FlutterFlowTheme.of(context).primary,
            ),
            const SizedBox(width: 8),
            Text(
              allSelected ? 'Deseleccionar todo' : 'Seleccionar todo',
              style: FlutterFlowTheme.of(context).bodyMedium,
            ),
            const Spacer(),
            Text(
              '${model.apartadosSeleccionados.length} seleccionados',
              style: FlutterFlowTheme.of(context).bodySmall,
            ),
          ],
        ),
      );
    }
  }
}
