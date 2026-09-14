import 'package:flutter/material.dart';
import 'package:baul_pandora/services/store_service.dart';

class StoreThemeService extends ChangeNotifier {
  static final StoreThemeService instance = StoreThemeService._internal();
  StoreThemeService._internal();

  StoreData? _currentStore;
  Color _primaryColor = const Color(0xFF6366F1);
  Color _secondaryColor = const Color(0xFF4F46E5);

  StoreData? get currentStore => _currentStore;
  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;

  void setStore(StoreData store) {
    _currentStore = store;
    _primaryColor = _hexToColor(store.colorPrimario, fallback: const Color(0xFF6366F1));
    _secondaryColor = _hexToColor(store.colorSecundario, fallback: const Color(0xFF4F46E5));
    notifyListeners();
  }

  void clearStore() {
    _currentStore = null;
    _primaryColor = const Color(0xFF6366F1);
    _secondaryColor = const Color(0xFF4F46E5);
    notifyListeners();
  }

  static Color _hexToColor(String hexString, {required Color fallback}) {
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
