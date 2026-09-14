import 'package:flutter/services.dart';

class CalculatorCurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Si el texto está vacío, retornamos vacío o cero
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Extraemos solo los dígitos del texto nuevo
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Convertimos a un entero para representar los centavos
    int value = int.tryParse(digits) ?? 0;

    // Formateamos dividiendo por 100 para obtener los dos decimales
    String formatted = (value / 100).toStringAsFixed(2);

    // Retornamos el valor formateado, moviendo el cursor al final
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
