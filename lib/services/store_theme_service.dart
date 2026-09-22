import 'package:flutter/material.dart';
import 'package:baul_pandora/services/store_service.dart';

class StoreStylePreset {
  final String id;
  final String name;
  final String tag;
  final String description;
  final String primaryHex;
  final String secondaryHex;
  final IconData icon;

  const StoreStylePreset({
    required this.id,
    required this.name,
    required this.tag,
    required this.description,
    required this.primaryHex,
    required this.secondaryHex,
    required this.icon,
  });

  Color get primaryColor => StoreThemeService.hexToColor(primaryHex, fallback: const Color(0xFF6366F1));
  Color get secondaryColor => StoreThemeService.hexToColor(secondaryHex, fallback: const Color(0xFF4F46E5));
}

class StoreThemeService extends ChangeNotifier {
  static final StoreThemeService instance = StoreThemeService._internal();
  StoreThemeService._internal();

  StoreData? _currentStore;
  Color _primaryColor = const Color(0xFF6366F1);
  Color _secondaryColor = const Color(0xFF4F46E5);

  StoreData? get currentStore => _currentStore;
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;

  static const List<StoreStylePreset> presets = [
    StoreStylePreset(
      id: 'indigo',
      name: 'Modern Indigo',
      tag: 'Tecnología & General',
      description: 'Estilo moderno, profesional e innovador',
      primaryHex: '#6366F1',
      secondaryHex: '#4F46E5',
      icon: Icons.bolt_rounded,
    ),
    StoreStylePreset(
      id: 'blue',
      name: 'Azul Océano',
      tag: 'Confianza & Corporativo',
      description: 'Transmite seguridad, firmeza y elegancia',
      primaryHex: '#2563EB',
      secondaryHex: '#1D4ED8',
      icon: Icons.storefront_rounded,
    ),
    StoreStylePreset(
      id: 'emerald',
      name: 'Verde Esmeralda',
      tag: 'Eco & Salud',
      description: 'Ideal para productos orgánicos, naturales y bienestar',
      primaryHex: '#10B981',
      secondaryHex: '#059669',
      icon: Icons.eco_rounded,
    ),
    StoreStylePreset(
      id: 'amber',
      name: 'Ámbar Cálido',
      tag: 'Comida & Gastronomía',
      description: 'Perfecto para restaurantes, café, panaderías y snacks',
      primaryHex: '#F59E0B',
      secondaryHex: '#D97706',
      icon: Icons.restaurant_rounded,
    ),
    StoreStylePreset(
      id: 'red',
      name: 'Rojo Pasión',
      tag: 'Ofertas & Deportes',
      description: 'Energía alta, moda deportiva y liquidaciones',
      primaryHex: '#EF4444',
      secondaryHex: '#DC2626',
      icon: Icons.local_fire_department_rounded,
    ),
    StoreStylePreset(
      id: 'purple',
      name: 'Violeta Creativo',
      tag: 'Arte & Diseño',
      description: 'Distintivo, sofisticado y vanguardista',
      primaryHex: '#8B5CF6',
      secondaryHex: '#7C3AED',
      icon: Icons.auto_awesome_rounded,
    ),
    StoreStylePreset(
      id: 'pink',
      name: 'Rosa Boutique',
      tag: 'Belleza & Cosmética',
      description: 'Elegancia femenina, cuidado personal y accesorios',
      primaryHex: '#EC4899',
      secondaryHex: '#DB2777',
      icon: Icons.favorite_rounded,
    ),
    StoreStylePreset(
      id: 'dark',
      name: 'Elegante Slate',
      tag: 'Lujo & Minimalismo',
      description: 'Exclusividad, joyería de lujo y alta gama',
      primaryHex: '#0F172A',
      secondaryHex: '#334155',
      icon: Icons.diamond_rounded,
    ),
  ];

  void setStore(StoreData store) {
    _currentStore = store;
    _primaryColor = hexToColor(store.colorPrimario, fallback: const Color(0xFF6366F1));
    _secondaryColor = hexToColor(store.colorSecundario, fallback: const Color(0xFF4F46E5));
    notifyListeners();
  }

  void clearStore() {
    _currentStore = null;
    _primaryColor = const Color(0xFF6366F1);
    _secondaryColor = const Color(0xFF4F46E5);
    notifyListeners();
  }

  static Color hexToColor(String hexString, {required Color fallback}) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}

