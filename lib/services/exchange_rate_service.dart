import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ExchangeRateService {
  static final ExchangeRateService instance = ExchangeRateService._internal();
  ExchangeRateService._internal();

  static const String _apiUrl = 'https://ve.dolarapi.com/v1/dolares/oficial';
  
  double? _cachedRate;
  DateTime? _lastFetch;
  
  /// Obtiene la tasa del dólar BCV.
  /// Implementa un caché de 1 hora para evitar llamadas excesivas a la API.
  Future<double> getBcvRate() async {
    if (_cachedRate != null && _lastFetch != null) {
      if (DateTime.now().difference(_lastFetch!) < const Duration(hours: 1)) {
        return _cachedRate!;
      }
    }
    
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // Debug print para ver la estructura real de la respuesta en consola
        debugPrint('BCV API Response: $data');
        
        // Usamos el campo 'promedio' según la respuesta de la API
        if (data['promedio'] != null) {
          _cachedRate = (data['promedio'] as num).toDouble();
          _lastFetch = DateTime.now();
          return _cachedRate!;
        }
      }
      throw Exception('No se pudo obtener la tasa oficial del BCV');
    } catch (e) {
      debugPrint('Error fetching BCV rate: $e');
      // Fallback
      return 36.5; 
    }
  }
}
