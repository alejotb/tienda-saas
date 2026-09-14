import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:baul_pandora/flutter_flow/flutter_flow_theme.dart';
import 'package:baul_pandora/services/cart_service.dart';
import 'package:baul_pandora/services/ai/gemini_vision_service.dart';

class UploadProofComponent extends StatefulWidget {
  const UploadProofComponent({
    super.key,
    this.onProofUploaded,
    this.fallbackAmount,
  });

  final Function(String?, Map<String, dynamic>?)? onProofUploaded;
  final double? fallbackAmount;

  @override
  State<UploadProofComponent> createState() => _UploadProofComponentState();
}

enum ProofState { normal, uploading, processing, success, error }

class _UploadProofComponentState extends State<UploadProofComponent> {
  ProofState _currentState = ProofState.normal;
  String? _errorMessage;
  String? _lastUrl;
  Map<String, dynamic>? _aiData;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (_currentState == ProofState.success) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text('Comprobante validado',
                style: theme.bodyMedium.override(
                    color: Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    if (_currentState == ProofState.error) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red),
        ),
        child: Column(
          children: [
            Text(_errorMessage ?? 'Error desconocido',
                style: const TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _lastUrl != null
                        ? () => _processProofWithAI(_lastUrl!)
                        : null,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar IA'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickAndUpload(),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Subir otro'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subir comprobante', style: theme.titleMedium),
              if (_currentState == ProofState.uploading)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else if (_currentState == ProofState.processing)
                const Row(
                  children: [
                    SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 6),
                    Text('Analizando IA...',
                        style: TextStyle(fontSize: 12, color: Colors.blue)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Formatos permitidos: JPG, PNG. La IA verificará los datos del pago automáticamente.',
            style: theme.bodySmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_currentState == ProofState.uploading ||
                      _currentState == ProofState.processing)
                  ? null
                  : _pickAndUpload,
              icon: const Icon(Icons.upload_file),
              label: const Text('Subir Imagen'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.single;
        Uint8List? bytes = platformFile.bytes;
        if (bytes == null && platformFile.path != null && !kIsWeb) {
          bytes = await File(platformFile.path!).readAsBytes();
        }
        if (bytes != null) {
          await _uploadBytes(bytes);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al seleccionar imagen: $e';
        _currentState = ProofState.error;
      });
    }
  }

  Future<void> _uploadBytes(Uint8List bytes) async {
    setState(() {
      _currentState = ProofState.uploading;
      _errorMessage = null;
    });
    try {
      String? url = await CartService.instance.uploadPaymentProof(
          bytes, 'apartado_${DateTime.now().millisecondsSinceEpoch}');

      _lastUrl = url;
      if (url != null) {
        await _processProofWithAI(url);
      } else {
        throw Exception('No se pudo generar la URL del comprobante');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'No pudimos subir la imagen: $e';
        _currentState = ProofState.error;
      });
    }
  }

  Future<void> _processProofWithAI(String url) async {
    setState(() {
      _currentState = ProofState.processing;
      _errorMessage = null;
    });
    try {
      final aiData =
          await GeminiVisionService.instance.analyzePaymentProof(url);

      if (aiData != null &&
          (aiData['valido'] as bool? ?? false) &&
          (aiData['es_comprobante'] as bool? ?? true)) {
        setState(() {
          _aiData = aiData;
          _currentState = ProofState.success;
        });
        if (widget.onProofUploaded != null) {
          widget.onProofUploaded!(url, aiData);
        }
      } else {
        final motivo = aiData?['motivo']?.toString() ??
            'La imagen no corresponde a un comprobante de pago bancario válido o es ilegible.';
        await _handleInvalidProof(url, motivo);
      }
    } catch (e) {
      if (e.toString().contains('API_ERROR')) {
        print('UploadProofComponent: Fallback activado por error de IA: $e');
        final double finalFallbackAmount = widget.fallbackAmount ?? 1.0;
        final fallbackData = {
          'valido': true,
          'ai_verified': false,
          'nota_admin': 'Sin comprobar por la IA',
          'banco': '',
          'referencia': '',
          'monto': finalFallbackAmount,
        };

        setState(() {
          _aiData = fallbackData;
          _currentState = ProofState.success;
        });

        if (widget.onProofUploaded != null) {
          widget.onProofUploaded!(url, fallbackData);
        }
      } else {
        setState(() {
          _errorMessage = 'Error en el análisis de IA.';
          _currentState = ProofState.error;
        });
      }
    }
  }

  Future<void> _handleInvalidProof(String url, String message) async {
    await CartService.instance.deletePaymentProof(url);
    setState(() {
      _errorMessage = message;
      // Al poner este estado, el usuario NO puede reintentar con la misma URL (reintentar IA)
      // Solo puede "Subir otro".
      _currentState = ProofState.error;
      _lastUrl = null; // Limpiamos la URL para que no pueda reintentar
    });
  }
}
