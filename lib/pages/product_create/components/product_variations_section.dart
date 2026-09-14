import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import '/backend/supabase/supabase.dart';
import '../product_create_model.dart';

class ProductVariationsSection extends StatelessWidget {
  final ProductCreateModel model;
  final VoidCallback onStateChanged;

  const ProductVariationsSection({
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
          'Atributos y Variaciones',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                title: Text('¿Este producto es variable?', style: FlutterFlowTheme.of(context).bodyLarge.override(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                )),
                subtitle: Text('Permite definir atributos (ej: Talla, Color) y generar múltiples combinaciones con precios, stock e imágenes independientes.', style: FlutterFlowTheme.of(context).bodySmall),
                value: model.isVariable,
                onChanged: (val) {
                  model.isVariable = val;
                  if (val && model.attributesList.isEmpty) {
                    model.generateVariations();
                  }
                  onStateChanged();
                },
                activeTrackColor: FlutterFlowTheme.of(context).primary,
              ),
              
              if (model.isVariable) ...[
                const Divider(height: 32),
                Text('Configurar Atributos', style: FlutterFlowTheme.of(context).titleMedium),
                const SizedBox(height: 16),
                
                // Add new attribute form
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: model.newAttributeNameController,
                        focusNode: model.newAttributeNameFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Nombre (ej: Talle)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: FlutterFlowTheme.of(context).primaryBackground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: model.newAttributeOptionsController,
                        focusNode: model.newAttributeOptionsFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Opciones separadas por coma (ej: S, M, L)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: FlutterFlowTheme.of(context).primaryBackground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).success,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.check, color: Colors.white),
                        onPressed: () {
                          if (model.newAttributeNameController?.text.isNotEmpty == true &&
                              model.newAttributeOptionsController?.text.isNotEmpty == true) {
                            model.attributesList.add({
                              'name': model.newAttributeNameController!.text.trim(),
                              'options': model.newAttributeOptionsController!.text
                                  .split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty)
                                  .toList(),
                            });
                            model.newAttributeNameController?.clear();
                            model.newAttributeOptionsController?.clear();
                            onStateChanged();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // List of added attributes
                if (model.attributesList.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primaryBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...model.attributesList.asMap().entries.map((entry) {
                          int idx = entry.key;
                          var attr = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${attr['name']}: ${(attr['options'] as List).join(", ")}', style: FlutterFlowTheme.of(context).bodyMedium),
                                InkWell(
                                  onTap: () {
                                    model.attributesList.removeAt(idx);
                                    onStateChanged();
                                  },
                                  child: Icon(Icons.delete_outline, color: FlutterFlowTheme.of(context).error, size: 20),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            model.generateVariations();
                            onStateChanged();
                          },
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Generar Combinaciones'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FlutterFlowTheme.of(context).primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                const SizedBox(height: 24),

                // List of variations generated
                if (model.variationsList.isNotEmpty) ...[
                  Text('Variaciones (${model.variationsList.length})', style: FlutterFlowTheme.of(context).titleMedium),
                  const SizedBox(height: 16),
                  ...model.variationsList.asMap().entries.map((entry) {
                    int varIdx = entry.key;
                    var variation = entry.value;
                    Map<String, String> attrs = Map<String, String>.from(variation['attributes']);
                    List<String> varImages = List<String>.from(variation['images'] ?? []);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primaryBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Variation Image
                          InkWell(
                            onTap: () async {
                              final selectedMedia = await selectMediaWithSourceBottomSheet(
                                context: context,
                                storageFolderPath: 'productos/${model.uuidProductoTemp}/var_$varIdx/',
                                allowPhoto: true,
                              );
                              if (selectedMedia != null && selectedMedia.every((m) => validateFileFormat(m.storagePath, context))) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subiendo imagen de variación...')));
                                }
                                try {
                                  var downloadUrls = await uploadSupabaseStorageFiles(
                                    bucketName: 'images',
                                    selectedFiles: selectedMedia,
                                  );
                                  if (downloadUrls.isNotEmpty) {
                                    model.variationsList[varIdx]['images'] = downloadUrls;
                                    onStateChanged();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                }
                              }
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).secondaryBackground,
                                borderRadius: BorderRadius.circular(8),
                                image: varImages.isNotEmpty
                                    ? DecorationImage(image: NetworkImage(varImages.first), fit: BoxFit.cover)
                                    : null,
                              ),
                              child: varImages.isEmpty
                                  ? Icon(Icons.add_a_photo, color: FlutterFlowTheme.of(context).secondaryText)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Variation Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  attrs.entries.map((e) => '${e.key}: ${e.value}').join(' | '),
                                  style: FlutterFlowTheme.of(context).bodyLarge.override(fontFamily: 'Inter', fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: model.variationPriceControllers[varIdx],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Precio',
                                          prefixText: '\$ ',
                                          isDense: true,
                                        ),
                                        style: FlutterFlowTheme.of(context).bodyMedium,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: model.variationStockControllers[varIdx],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Stock',
                                          isDense: true,
                                        ),
                                        style: FlutterFlowTheme.of(context).bodyMedium,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Delete variation
                          IconButton(
                            icon: Icon(Icons.delete, color: FlutterFlowTheme.of(context).error),
                            onPressed: () {
                              model.variationsList.removeAt(varIdx);
                              model.variationPriceControllers.removeAt(varIdx);
                              model.variationStockControllers.removeAt(varIdx);
                              onStateChanged();
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
