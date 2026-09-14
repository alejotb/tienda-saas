import 'dart:convert';
import 'package:flutter/services.dart';

class VenezuelaLocationService {
  // Singleton pattern
  static final VenezuelaLocationService _instance = VenezuelaLocationService._internal();
  factory VenezuelaLocationService() => _instance;
  VenezuelaLocationService._internal();

  List<dynamic> _data = [];
  bool _isInitialized = false;

  /// Método interno para normalizar texto (quita acentos y pasa a minúsculas)
  String _normalize(String text) {
    String normalized = text.toLowerCase();
    const accents = 'áéíóúüñÁÉÍÓÚÜÑ';
    const basics = 'aeiouunAEIOUUN';
    for (int i = 0; i < accents.length; i++) {
      normalized = normalized.replaceAll(accents[i], basics[i]);
    }
    return normalized;
  }

  /// Carga el archivo JSON desde los assets.
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final String response = await rootBundle.loadString('assets/jsons/venezuela.json');
      final data = await json.decode(response);
      _data = data;
      _isInitialized = true;
    } catch (e) {
      print('Error loading venezuela.json: $e');
      _data = [];
    }
  }

  /// Obtiene los estados que coincidan con la búsqueda.
  List<String> getStates(String query) {
    if (!_isInitialized) return [];
    if (query.isEmpty) return [];

    final normalizedQuery = _normalize(query);

    return _data
        .map((e) => e['estado'] as String)
        .where((estado) => _normalize(estado).contains(normalizedQuery))
        .toList();
  }

  /// Obtiene las ciudades de un estado específico que coincidan con la búsqueda.
  List<String> getCities(String state, String query) {
    if (!_isInitialized) return [];
    
    // Buscar el objeto del estado normalizando la comparación
    final stateData = _data.firstWhere(
      (e) => _normalize(e['estado']) == _normalize(state),
      orElse: () => null,
    );

    if (stateData == null) return [];

    final List<dynamic> cities = stateData['ciudades'] ?? [];
    if (query.isEmpty) return cities.cast<String>();

    final normalizedQuery = _normalize(query);

    return cities
        .where((city) => _normalize(city.toString()).contains(normalizedQuery))
        .cast<String>()
        .toList();
  }

  /// Retorna todos los estados (útil para validaciones o listas completas).
  List<String> getAllStates() {
    return _data.map((e) => e['estado'] as String).toList();
  }
}
