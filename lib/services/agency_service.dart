import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'dart:convert';

class Agency {
  final String empresa;
  final String estado;
  final String nombre;
  final String codigo;
  final String direccion;

  Agency({
    required this.empresa,
    required this.estado,
    required this.nombre,
    required this.codigo,
    required this.direccion,
  });

  factory Agency.fromMap(Map<String, dynamic> map) {
    return Agency(
      empresa: map['empresa'] ?? '',
      estado: map['estado'] ?? '',
      nombre: map['nombre_agencia'] ?? '',
      codigo: map['codigo_agencia']?.toString() ?? '',
      direccion: map['direccion'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'empresa': empresa,
      'estado': estado,
      'nombre_agencia': nombre,
      'codigo_agencia': codigo,
      'direccion': direccion,
    };
  }
}

class AgencyService {
  static final AgencyService _instance = AgencyService._internal();
  factory AgencyService() => _instance;
  AgencyService._internal();

  List<Agency> _agencies = [];
  bool _isLoaded = false;

  /// Método interno para normalizar texto (corrige codificación corrupta, quita acentos y pasa a minúsculas)
  String _normalize(String text) {
    if (text.isEmpty) return '';
    
    String normalized = text;
    try {
      // 1. Corregir codificación: UTF-8 interpretado como Latin-1
      // Convertimos el string a bytes usando Latin-1 y luego los decodificamos como UTF-8
      normalized = utf8.decode(latin1.encode(text), allowMalformed: true);
    } catch (e) {
      // Si falla, seguimos con el texto original
    }

    normalized = normalized.toLowerCase();
        
    // 2. Quitar acentos restantes para búsqueda flexible
    const accents = 'áéíóúüñ';
    const basics = 'aeiouun';
    for (int i = 0; i < accents.length; i++) {
      normalized = normalized.replaceAll(accents[i], basics[i]);
    }
    return normalized;
  }

  Future<void> loadAgencies() async {
    if (_isLoaded) return;

    try {
      // Fetching from Supabase table 'agencias_envio'
      final response = await SupaFlow.client
          .from('agencias_envio')
          .select();

      final List<dynamic> data = response;
      _agencies = data.map((item) => Agency.fromMap(item)).toList();
      _isLoaded = true;
      
    } catch (e) {
      print('Error loading agencies from Supabase: $e');
      rethrow;
    }
  }

  List<Agency> getAgenciesByState(String state) {
    return _agencies.where((a) => _normalize(a.estado) == _normalize(state)).toList();
  }

  List<Agency> getAgenciesByCourier(String courier) {
    return _agencies.where((a) => _normalize(a.empresa) == _normalize(courier)).toList();
  }

  /// Busca agencias por estado, empresa y un query (que puede ser nombre, código o dirección)
  List<Agency> searchAgencies(String state, String query, {String searchMode = 'Nombre/Dirección', String? courier}) {
    final normalizedQuery = query.isEmpty ? '' : _normalize(query);
    final normalizedState = _normalize(state);
    
    return _agencies.where((a) {
      final agencyState = _normalize(a.estado);
      final agencyCourier = _normalize(a.empresa);
      
      // Match flexible para el estado: uno debe contener al otro
      final matchesState = agencyState.contains(normalizedState) || normalizedState.contains(agencyState);
      
      // Match flexible para la empresa: la empresa de la agencia debe contener el nombre seleccionado o viceversa
      final matchesCourier = courier == null || 
                             agencyCourier.contains(_normalize(courier)) || 
                             _normalize(courier).contains(agencyCourier);
      
      if (!matchesState || !matchesCourier) return false;
      
      if (normalizedQuery.isEmpty) return true;
      
      final matchesName = _normalize(a.nombre).contains(normalizedQuery);
      final matchesCode = _normalize(a.codigo).contains(normalizedQuery);
      final matchesAddress = _normalize(a.direccion).contains(normalizedQuery);
      
      if (searchMode == 'Código de Agencia') {
        return matchesCode;
      }
      return matchesName || matchesCode || matchesAddress;
    }).toList();
  }

  List<String> getAvailableStates() {
    return _agencies.map((a) => a.estado).toSet().toList()..sort();
  }

  List<Agency> getAllAgencies() => _agencies;
}
