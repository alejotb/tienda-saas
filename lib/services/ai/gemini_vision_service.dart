import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class GeminiVisionService {
  static final GeminiVisionService instance = GeminiVisionService._internal();
  GeminiVisionService._internal();

  List<String> _getGeminiApiKeys() {
    final rawKeys =
        dotenv.env['GEMINI_API_KEYS'] ?? dotenv.env['GEMINI_API_KEY'] ?? '';
    return rawKeys
        .split(',')
        .map((k) => k.trim())
        .where((k) => k.isNotEmpty)
        .toList();
  }

  Future<Map<String, dynamic>?> analyzePaymentProof(String imageUrl) async {
    try {
      print('GeminiVisionService: Iniciando análisis para $imageUrl');
      final apiKeys = _getGeminiApiKeys();
      final openRouterKey = dotenv.env['OPENROUTER_API_KEY']?.trim();

      if (apiKeys.isEmpty && (openRouterKey == null || openRouterKey.isEmpty)) {
        throw Exception('API Key no configurada');
      }

      final primaryModel = dotenv.env['GEMINI_MODEL'] ?? 'gemini-flash-latest';
      final fallbackModels = [
        primaryModel,
        'gemini-flash-latest',
        'gemini-3.1-flash-lite',
        'gemini-3.5-flash',
        'gemini-3.6-flash',
        'gemini-flash-lite-latest',
      ];
      final modelsToTry = fallbackModels.toSet().toList();

      print('GeminiVisionService: Descargando imagen...');
      final response = await http
          .get(Uri.parse(imageUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Error al descargar la imagen: ${response.statusCode}');
      }
      final imageBytes = response.bodyBytes;
      print(
          'GeminiVisionService: Imagen descargada, tamaño: ${imageBytes.length} bytes');

      final promptText = '''
Actúa como un auditor bancario estricto. Analiza la imagen y determina si es un comprobante de pago o transferencia financiero legítimo (Pago Móvil, Transferencia Bancaria, Binance Pay, PayPal, Zelle, Zinli, etc.).

REGLAS DE RECHAZO INMEDIATO (es_comprobante = false, valido = false):
- Si la imagen es una foto personal, selfie, meme, paisaje, producto de tienda, captura de redes sociales (Instagram, TikTok), chat de WhatsApp sin comprobante, documento de texto genérico o imagen no financiera.
- Si la imagen está completamente ilegible, borrosa, cortada o no muestra datos de una transacción.

REGLAS DE EXTRACCIÓN (si es comprobante):
- tipo_pago: "pago_movil" (si es en Bolívares / bancos de Venezuela), "binance" (si es Binance Pay / USDT), "paypal" (si es PayPal), "zelle" (si es Zelle), "transferencia" (si es transferencia bancaria regular), "otro".
- monto: número decimal con el monto exacto pagado (sin símbolos).
- moneda: "VES", "USD", "USDT", "EUR".
- referencia: número de referencia, aprobación, transacción u orden (ej: "123456", "987654321").
- banco: nombre del banco emisor o receptor (ej: "Banesco", "Banco de Venezuela", "Mercantil", "Provincial", "BNC", "Bancaribe", "Bancamiga", etc.) o "N/A".
- telefono: número de teléfono visible asociado al pago móvil o Zelle (o "N/A").
- nombre: nombre o titular de quien transfiere (o "N/A").
- fecha: fecha de la transacción (o "N/A").

Devuelve EXCLUSIVAMENTE un objeto JSON válido con esta estructura:
{
  "es_comprobante": true,
  "valido": true,
  "motivo": "Comprobante verificado con éxito",
  "tipo_pago": "pago_movil",
  "monto": 2450.50,
  "moneda": "VES",
  "referencia": "123456",
  "banco": "Banesco",
  "telefono": "04141234567",
  "nombre": "Juan Perez",
  "fecha": "29/08/2026",
  "confianza": "alta"
}

Si NO es un comprobante o es inválido:
{
  "es_comprobante": false,
  "valido": false,
  "motivo": "La imagen no corresponde a un comprobante de pago o transferencia bancaria válido.",
  "tipo_pago": "desconocido",
  "monto": 0.0,
  "moneda": "USD",
  "referencia": "N/A",
  "banco": "N/A",
  "telefono": "N/A",
  "nombre": "N/A",
  "fecha": "N/A",
  "confianza": "baja"
}
''';

      String? text;
      dynamic lastError;

      // 1. Intentar con las API Keys de Google Gemini (con rotación de keys si hay 429)
      for (final apiKey in apiKeys) {
        bool keyExhausted = false;
        for (final modelName in modelsToTry) {
          try {
            print(
                'GeminiVisionService: Intentando modelo $modelName con key (${apiKey.substring(0, 6)}...)...');
            final model = GenerativeModel(
              model: modelName,
              apiKey: apiKey,
              generationConfig: GenerationConfig(
                responseMimeType: 'application/json',
                temperature: 0.1,
              ),
            );

            final generateContentResponse = await model.generateContent([
              Content.multi([
                TextPart(promptText),
                DataPart('image/jpeg', imageBytes),
              ])
            ]).timeout(const Duration(seconds: 25));

            text = generateContentResponse.text;
            if (text.isNotEmpty) {
              print('GeminiVisionService: Éxito con modelo $modelName!');
              break;
            }
          } catch (err) {
            print('GeminiVisionService: Falló modelo $modelName: $err');
            lastError = err;
            if (err.toString().contains('429') ||
                err.toString().contains('Quota exceeded')) {
              keyExhausted = true;
              break; // Pasar a la siguiente API Key si esta cuota está agotada
            }
          }
        }
        if (text != null && text.isNotEmpty) break;
        if (keyExhausted) {
          print(
              'GeminiVisionService: Cuota agotada en esta API Key, probando siguiente proveedor/key...');
        }
      }

      // 2. Fallback a OpenRouter si está configurado
      if (text == null && openRouterKey != null && openRouterKey.isNotEmpty) {
        try {
          print('GeminiVisionService: Intentando fallback con OpenRouter...');
          final base64Image = base64Encode(imageBytes);
          final openRouterRes = await http
              .post(
                Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
                headers: {
                  'Authorization': 'Bearer $openRouterKey',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'model': 'meta-llama/llama-3.2-11b-vision-instruct:free',
                  'messages': [
                    {
                      'role': 'user',
                      'content': [
                        {'type': 'text', 'text': promptText},
                        {
                          'type': 'image_url',
                          'image_url': {
                            'url': 'data:image/jpeg;base64,$base64Image'
                          }
                        }
                      ]
                    }
                  ],
                  'response_format': {'type': 'json_object'},
                }),
              )
              .timeout(const Duration(seconds: 25));

          if (openRouterRes.statusCode == 200) {
            final jsonBody = jsonDecode(openRouterRes.body);
            text = jsonBody['choices']?[0]?['message']?['content']?.toString();
            print('GeminiVisionService: Éxito con OpenRouter!');
          } else {
            print(
                'GeminiVisionService: OpenRouter falló con status ${openRouterRes.statusCode}');
          }
        } catch (orErr) {
          print('GeminiVisionService: Error en fallback OpenRouter: $orErr');
        }
      }

      if (text == null) {
        print(
            'GeminiVisionService: Todos los proveedores/modelos fallaron o cuota agotada.');
        throw Exception('API_ERROR: $lastError');
      }

      // Limpiar posibles marcas de markdown
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();

      print('GeminiVisionService: Parseando JSON...');
      final Map<String, dynamic> result =
          jsonDecode(text) as Map<String, dynamic>;
      print('GeminiVisionService: Análisis completado exitosamente: $result');

      return result;
    } catch (e) {
      print('GeminiVisionService: ERROR CRÍTICO: $e');
      throw Exception('API_ERROR: $e');
    }
  }
}
