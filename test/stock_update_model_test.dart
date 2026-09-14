import 'package:flutter_test/flutter_test.dart';
import 'package:baul_pandora/components/stock_update_modal/stock_update_model.dart';
import 'package:baul_pandora/backend/supabase/database/tables/productos.dart';

void main() {
  test('addToBatch should remove item if quantity becomes <= 0', () {
    final model = StockUpdateModel();
    final product = ProductosRow({'id': '1', 'nombre': 'Test'});
    
    // Add 1
    model.addToBatch(product, 1, 'CARGA');
    expect(model.batchQueue.length, 1);
    expect(model.batchQueue[0].quantity, 1);
    
    // Add -1 (should remove)
    model.addToBatch(product, -1, 'SALIDA');
    expect(model.batchQueue.length, 0);
    
    // Add 1 then -2 (should remove)
    model.addToBatch(product, 1, 'CARGA');
    model.addToBatch(product, -2, 'SALIDA');
    expect(model.batchQueue.length, 0);
  });
}
