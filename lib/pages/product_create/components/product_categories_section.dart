import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';

import '/backend/supabase/supabase.dart';
import '../product_create_model.dart';


class ProductCategoriesSection extends StatelessWidget {
  final ProductCreateModel model;
  final VoidCallback onStateChanged;

  const ProductCategoriesSection({
    super.key,
    required this.model,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categorías del Producto',
          style: FlutterFlowTheme.of(context).headlineSmall,
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FlutterFlowTheme.of(context).alternate),
          ),
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<CategoriasRow>>(
            future: CategoriasTable().queryRows(queryFn: (q) => q),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
              final categoriasList = snapshot.data!;
              if (categoriasList.isEmpty) {
                return const Text('No hay categorías disponibles');
              }
              return Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: List.generate(categoriasList.length, (index) {
                  final categoria = categoriasList[index];
                  final isSelected = model.categoriasSeleccionadas.contains(categoria.id);
                  
                  return FilterChip(
                    label: Text(
                      categoria.nombre ?? 'Sin nombre',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Inter',
                        color: isSelected 
                            ? FlutterFlowTheme.of(context).primaryBackground 
                            : FlutterFlowTheme.of(context).primaryText,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      if (selected) {
                        model.addToCategoriasSeleccionadas(categoria.id);
                      } else {
                        model.removeFromCategoriasSeleccionadas(categoria.id);
                      }
                      onStateChanged();
                    },
                    selectedColor: FlutterFlowTheme.of(context).primary,
                    backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
                    checkmarkColor: FlutterFlowTheme.of(context).primaryBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected 
                            ? Colors.transparent 
                            : FlutterFlowTheme.of(context).alternate,
                        width: 1,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
    );
  }
}
