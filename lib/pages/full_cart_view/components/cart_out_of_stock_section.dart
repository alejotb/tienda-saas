import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:flutter/material.dart';

class OutOfStockSection extends StatelessWidget {
  final List<Map<String, dynamic>> itemsSinStock;

  const OutOfStockSection({super.key, required this.itemsSinStock});

  @override
  Widget build(BuildContext context) {
    if (itemsSinStock.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.redAccent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Algunos productos no tienen stock disponible. Por favor, revisa tu carrito.',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Inter',
                        color: Colors.white,
                      ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Productos sin Stock',
              style: FlutterFlowTheme.of(context).titleMedium.override(
                    fontFamily: 'Inter',
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  )),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemsSinStock.length,
          itemBuilder: (context, index) {
            final item = itemsSinStock[index];
            return ListTile(
              title: Text(item['nombre'] ?? 'Producto'),
              subtitle: const Text('Actualmente sin stock'),
              trailing: const Icon(Icons.error, color: Colors.red),
            );
          },
        ),
      ],
    );
  }
}
