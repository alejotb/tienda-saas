import 'package:flutter/material.dart';

class CheckoutStateService extends ChangeNotifier {
  CheckoutStateService._();
  static final CheckoutStateService instance = CheckoutStateService._();

  List<Map<String, dynamic>>? _selectedItems;
  double? _subtotal;
  double? _total;
  double? _totalPagado;

  List<Map<String, dynamic>>? get selectedItems => _selectedItems;
  double? get subtotal => _subtotal;
  double? get total => _total;
  double? get totalPagado => _totalPagado;

  void setCheckoutData({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double totalPagado,
    required double total,
  }) {
    _selectedItems = items;
    _subtotal = subtotal;
    _totalPagado = totalPagado;
    _total = total;
    notifyListeners();
  }

  void clear() {
    _selectedItems = null;
    _subtotal = null;
    _totalPagado = null;
    _total = null;
    notifyListeners();
  }
}
