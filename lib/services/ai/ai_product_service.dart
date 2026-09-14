import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class AIProductService {
  static final AIProductService instance = AIProductService._internal();
  AIProductService._internal();

  /// Analyzes a product image and extracts attributes for auto-filling the form.
  Future<Map<String, dynamic>?> analyzeProductImage(String imageUrl) async {
    try {
      final imageResponse = await http.get(Uri.parse(imageUrl));
      if (imageResponse.statusCode != 200) return null;
      return await analyzeProductImageBytes(imageResponse.bodyBytes);
    } catch (e) {
      print('Error downloading image: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzeProductImageBytes(List<int> imageBytes) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API Key no configurada');
      }

      final modelName = dotenv.env['GEMINI_MODEL'] ?? 'gemini-3.1-flash-lite';
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
      );

      final promptText = '''
        Analiza esta imagen de un producto comercial. 
        Enfócate EXCLUSIVAMENTE en el producto principal y enfocado, ignorando completamente el fondo y elementos secundarios.
        Extrae la siguiente información en formato JSON estricto:
        {
          "nombre": string (el nombre más probable del producto, breve y claro),
          "descripcion": string (una descripción detallada y atractiva para venta, resaltando beneficios),
          "precio_estimado": double (un precio estimado basado en el mercado si es posible, sino null),
          "categoria_sugerida": string (una categoría general para el producto),
          "caracteristicas": list of strings (puntos clave o especificaciones del producto)
        }
        Si no puedes encontrar algún dato, pon null. No añadas texto fuera del JSON.
      ''';

      final prompt = TextPart(promptText);
      final imagePart = DataPart('image/jpeg', Uint8List.fromList(imageBytes));

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      if (response.text != null) {
        final textResponse = response.text!;
        final cleanJson = textResponse
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
            
        return jsonDecode(cleanJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error in AI product analysis: $e');
      return null;
    }
  }

  /// Identifies the product from the image to search in the database.
  Future<String?> identifyProductForSearch(List<int> imageBytes) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API Key no configurada en las variables de entorno.');
      }

      final model = GenerativeModel(
        model: 'gemini-3.1-flash-lite',
        apiKey: apiKey,
      );

      final promptText = 'Dime el nombre genérico, marca o modelo del producto principal y enfocado en la imagen para buscarlo en una base de datos. Enfócate SOLO en el objeto principal, ignorando el fondo y cualquier otro elemento secundario. Sé muy breve, máximo 3 a 5 palabras, sin signos de puntuación, solo las palabras clave.';
      
      final prompt = TextPart(promptText);
      final imagePart = DataPart('image/jpeg', Uint8List.fromList(imageBytes));

      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      if (response.text != null) {
        return response.text!.trim();
      }
      return null;
    } catch (e) {
      print('Error identifying product for search: $e');
      rethrow;
    }
  }
}
