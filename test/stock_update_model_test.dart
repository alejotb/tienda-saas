import 'package:flutter_test/flutter_test.dart';
import 'package:baul_pandora/components/stock_update_modal/stock_update_model.dart';
import 'package:baul_pandora/backend/supabase/database/tables/productos.dart';

void main() {
  test('addToBatch should add product to queue and toggle remove it', () {
    final model = StockUpdateModel();
    final product = ProductosRow({'id': '1', 'nombre': 'Test'});
    
    // Add product
    model.addToBatch(product);
    expect(model.batchQueue.length, 1);
    expect(model.isSelected(product), true);
    
    // Toggle remove
    model.toggleSelection(product);
    expect(model.batchQueue.length, 0);
    expect(model.isSelected(product), false);
  });
}

