import 'package:flutter/material.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/flutter_flow/custom_functions.dart' as functions;

class StockItem {
  final ProductosRow product;
  TextEditingController quantityController;
  bool isIngreso;
  String reason; // 'Compra', 'Devolución', 'Venta', 'Avería', 'Ajuste'

  StockItem({
    required this.product,
    int initialQuantity = 1,
    this.isIngreso = true,
    this.reason = 'Compra',
  }) : quantityController = TextEditingController(text: initialQuantity.toString());

  void dispose() {
    quantityController.dispose();
  }
}

// I will use a standard class for the model since it's a custom component
class StockUpdateModel {
  int currentStep = 1; // 1 = Selection, 2 = Edit Queue

  // Search & Filtering
  List<ProductosRow> searchResults = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();

  // Batch Queue
  List<StockItem> batchQueue = [];
  
  // Quick Create State
  bool isCreatingNew = false;
  TextEditingController newProductNameController = TextEditingController();
  TextEditingController newProductPriceController = TextEditingController();
  String? selectedCategory; // Simplified for quick create

  // Loading States
  bool isProcessing = false;

  void dispose() {
    searchController.dispose();
    newProductNameController.dispose();
    newProductPriceController.dispose();
    for (var item in batchQueue) {
      item.dispose();
    }
  }

  // Logic: Search products
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      searchResults = [];
      return;
    }

    isSearching = true;
    try {
      final results = await ProductosTable().queryRows(
        queryFn: (q) => q.ilike('nombre', '%$query%'),
      );
      
      // Prevent race conditions: only update if the query still matches the input
      if (searchController.text == query) {
        searchResults = results;
      }
    } catch (e) {
      debugPrint('Error searching products: $e');
    } finally {
      if (searchController.text == query) {
        isSearching = false;
      }
    }
  }

  // Logic: Add or Remove from batch
  void toggleSelection(ProductosRow product) {
    int existingIndex = batchQueue.indexWhere((item) => item.product.id == product.id);
    if (existingIndex == -1) {
      batchQueue.add(StockItem(product: product));
    } else {
      batchQueue.removeAt(existingIndex);
    }
  }

  bool isSelected(ProductosRow product) {
    return batchQueue.any((item) => item.product.id == product.id);
  }

  void addToBatch(ProductosRow product) {
    int existingIndex = batchQueue.indexWhere((item) => item.product.id == product.id);
    if (existingIndex == -1) {
      batchQueue.add(StockItem(product: product));
    }
  }

  // Logic: Quick Create Product
  Future<ProductosRow?> createQuickProduct() async {
    final name = newProductNameController.text.trim();
    final price = double.tryParse(newProductPriceController.text.trim()) ?? 0.0;

    if (name.isEmpty) return null;

    try {
      final newProduct = ProductosRow({
        'id': functions.generateRealUUID(), // Assuming this exists as seen in other files
        'nombre': name,
        'precio': price,
        'stock': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      await newProduct.table.insert(newProduct.data);
      return newProduct;
    } catch (e) {
      debugPrint('Error creating quick product: $e');
      return null;
    }
  }

  // Logic: Execute Mass Update using RPC
  Future<bool> processBatch() async {
    if (batchQueue.isEmpty) return false;

    isProcessing = true;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      for (var item in batchQueue) {
        final qtyText = item.quantityController.text.trim();
        int qty = int.tryParse(qtyText) ?? 0;
        if (qty <= 0) continue; // Skip items with 0 or invalid quantity
        
        final finalQty = item.isIngreso ? qty : -qty;

        await Supabase.instance.client.rpc('update_product_stock', params: {
          'p_producto_id': item.product.id,
          'p_usuario_id': userId,
          'p_cantidad': finalQty,
          'p_tipo_operacion': item.isIngreso ? 'INGRESO' : 'EGRESO',
          'p_notas': item.reason,
        });
      }
      
      batchQueue.clear();
      return true;
    } catch (e) {
      debugPrint('Error processing batch: $e');
      return false;
    } finally {
      isProcessing = false;
    }
  }
}
