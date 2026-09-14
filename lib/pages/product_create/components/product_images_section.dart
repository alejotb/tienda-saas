import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import '/backend/supabase/supabase.dart';
import '../product_create_model.dart';
import '/services/ai/ai_product_service.dart';
import 'package:google_fonts/google_fonts.dart';


class ProductImagesSection extends StatelessWidget {
  final ProductCreateModel model;
  final VoidCallback onStateChanged;

  const ProductImagesSection({
    super.key,
    required this.model,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Imágenes del Producto',
              style: FlutterFlowTheme.of(context).headlineSmall,
            ),
            IconButton(
              icon: Icon(Icons.add_photo_alternate, color: FlutterFlowTheme.of(context).primary, size: 32),
              onPressed: () async {
                final selectedMedia = await selectMediaWithSourceBottomSheet(
                  context: context,
                  storageFolderPath: 'productos/${model.uuidProductoTemp}/',
                  allowPhoto: true,
                  allowMultiple: true,
                );
                if (selectedMedia != null && selectedMedia.every((m) => validateFileFormat(m.storagePath, context))) {
                  model.isDataUploadingUploadData24h1 = true;
                  onStateChanged();
                  
                  var selectedUploadedFiles = <FFUploadedFile>[];
                  var downloadUrls = <String>[];
                  try {
                    selectedUploadedFiles = selectedMedia
                        .map((m) => FFUploadedFile(
                              name: m.storagePath.split('/').last,
                              bytes: m.bytes,
                              height: m.dimensions?.height,
                              width: m.dimensions?.width,
                              blurHash: m.blurHash,
                            ))
                        .toList();

                    downloadUrls = await uploadSupabaseStorageFiles(
                      bucketName: 'images',
                      selectedFiles: selectedMedia,
                    );
                    print('✅ IMÁGENES SUBIDAS A SUPABASE: $downloadUrls');
                  } catch (e) {
                    print('❌ ERROR SUBIENDO IMÁGENES: $e');
                  } finally {
                    model.isDataUploadingUploadData24h1 = false;
                    
                    if (downloadUrls.isNotEmpty) {
                      if (selectedUploadedFiles.isNotEmpty) {
                        model.uploadedLocalFileUploadData24h1 = selectedUploadedFiles.first;
                      }
                      model.uploadedFileUrlUploadData24h1 = downloadUrls.first;
                      model.imagesPaths.addAll(downloadUrls);
                    }
                    onStateChanged();
                  }
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (model.imagesPaths.isEmpty)
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FlutterFlowTheme.of(context).alternate),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (model.isDataUploadingUploadData24h1) ...[
                  CircularProgressIndicator(color: FlutterFlowTheme.of(context).primary),
                  const SizedBox(height: 16),
                  Text('Subiendo imágenes...', style: FlutterFlowTheme.of(context).bodyMedium),
                ] else ...[
                  Icon(Icons.image_not_supported, size: 64, color: FlutterFlowTheme.of(context).secondaryText),
                  const SizedBox(height: 16),
                  Text('No hay imágenes subidas', style: FlutterFlowTheme.of(context).bodyMedium),
                ],
              ],
            ),
          )
        else
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  model.imagesPaths[model.indexImage],
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 300,
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    child: const Center(child: Icon(Icons.error_outline, size: 50)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: model.imagesPaths.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == model.indexImage;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          model.indexImage = index;
                          onStateChanged();
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? FlutterFlowTheme.of(context).primary : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  model.imagesPaths[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () {
                                  model.removeFromImagesPaths(model.imagesPaths[index]);
                                  if (model.indexImage >= model.imagesPaths.length) {
                                    model.indexImage = model.imagesPaths.length - 1;
                                    if (model.indexImage < 0) model.indexImage = 0;
                                  }
                                  onStateChanged();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (model.isDataUploadingUploadData24h1)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: FlutterFlowTheme.of(context).primary, strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Text('Subiendo más imágenes...', style: FlutterFlowTheme.of(context).bodyMedium),
                    ],
                  ),
                ),
              if (model.imagesPaths.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: InkWell(
                    onTap: model.isAnalyzingAI ? null : () async {
                      model.isAnalyzingAI = true;
                      onStateChanged();
                      try {
                        final data = await AIProductService.instance.analyzeProductImage(model.imagesPaths.first);
                        if (data != null && context.mounted) {
                          if (data['nombre'] != null) model.textController1?.text = data['nombre'];
                          if (data['descripcion'] != null) model.textController2?.text = data['descripcion'];
                          if (data['precio_estimado'] != null) model.textController3?.text = data['precio_estimado'].toString();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('¡Datos extraídos con éxito!')),
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se pudieron extraer datos de la imagen')),
                          );
                        }
                      } finally {
                        model.isAnalyzingAI = false;
                        onStateChanged();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: FlutterFlowTheme.of(context).primary),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (model.isAnalyzingAI)
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: FlutterFlowTheme.of(context).primary))
                          else
                            Icon(Icons.auto_awesome, color: FlutterFlowTheme.of(context).primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            model.isAnalyzingAI ? 'Analizando imagen...' : 'Auto-completar con IA (Gemini)',
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  font: GoogleFonts.interTight(
                                    color: FlutterFlowTheme.of(context).primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
