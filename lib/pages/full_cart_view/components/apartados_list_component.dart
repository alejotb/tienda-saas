import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

class ApartadosListComponent extends StatelessWidget {
  final List<dynamic> apartados;
  final Set<String> apartadosSeleccionados;
  final Function(String) onToggleSeleccion;
  final Function(String, String, int) onUpdateApartadoItem;

  const ApartadosListComponent({
    super.key,
    required this.apartados,
    required this.apartadosSeleccionados,
    required this.onToggleSeleccion,
    required this.onUpdateApartadoItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: apartados.asMap().entries.map((entry) {
        final int index = entry.key + 1;
        final apartado = entry.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FlutterFlowTheme.of(context).alternate),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pedido #$index', 
                      style: FlutterFlowTheme.of(context).titleSmall),
                  Text('Pagado: \$${(apartado['monto_pagado'] as num? ?? 0.0).toStringAsFixed(2)}', 
                      style: FlutterFlowTheme.of(context).titleMedium),
                ],
              ),
              const Divider(),
              ... (apartado['items'] as List).map((item) {
                final int minQty = item['cantidad_original'] ?? 0;
                final int maxQty = item['stock'] ?? 0;
                final int currentQty = item['cantidad'] ?? 0;
                final double price = (item['precio'] as num).toDouble();
                final bool isOutOfStock = maxQty <= 0;

                return Container(
                  color: isOutOfStock ? FlutterFlowTheme.of(context).primaryBackground.withOpacity(0.5) : Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      if (!isOutOfStock)
                        Checkbox(
                          value: apartadosSeleccionados.contains(item['id']),
                          onChanged: (val) => onToggleSeleccion(item['id']),
                        ),
                      Expanded(
                        child: GestureDetector(
                          onTap: isOutOfStock ? null : () => onToggleSeleccion(item['id']),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['nombre'], style: FlutterFlowTheme.of(context).bodyMedium),
                              if (isOutOfStock)
                                Text('AGOTADO', style: FlutterFlowTheme.of(context).bodySmall.override(fontFamily: 'Inter', color: Colors.red, fontWeight: FontWeight.bold)),
                              Text('\$${price.toStringAsFixed(2)}', style: FlutterFlowTheme.of(context).bodySmall),
                            ],
                          ),
                        ),
                      ),
                      if (isOutOfStock)
                        TextButton(
                          onPressed: () async {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Movido a favoritos')));
                          },
                          child: Text('Mover a Favoritos', style: FlutterFlowTheme.of(context).bodySmall.override(fontFamily: 'Inter', color: FlutterFlowTheme.of(context).primary, fontWeight: FontWeight.bold)),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: currentQty > minQty
                                  ? () => onUpdateApartadoItem(apartado['pedido_id'], item['id'], -1)
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: Text('-', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentQty > minQty ? FlutterFlowTheme.of(context).primaryText : Colors.grey)),
                              ),
                            ),
                            Text('$currentQty', style: FlutterFlowTheme.of(context).titleMedium),
                            InkWell(
                              onTap: currentQty < maxQty
                                  ? () => onUpdateApartadoItem(apartado['pedido_id'], item['id'], 1)
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                child: Text('+', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: currentQty < maxQty ? FlutterFlowTheme.of(context).primaryText : Colors.grey)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}
