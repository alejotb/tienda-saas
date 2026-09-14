# Design: Fix Stock Update Modal

## Technical Approach
Clean Model Refactor:
The current `StockUpdateModel` is corrupted with multiple declarations and incorrect inheritance. I will refactor it into a clean Dart class that handles all state and logic for the `StockUpdateWidget`. This class will implement the methods and getters currently expected by the UI.

## Architecture Decisions

### Decision: Model Implementation Pattern
**Choice**: Use a plain Dart class for `StockUpdateModel` (as intended by the second declaration in the existing file).
**Alternatives considered**: Using `FlutterFlowModel` or `StatefulWidget`'s `State` class.
**Rationale**: The existing widget code already tries to use a separate `_model` instance. Keeping it as a plain class provides the cleanest separation of logic without introducing FlutterFlow-specific boilerplate that might not be fully configured in this custom component.

### Decision: UUID Generation
**Choice**: Import and use `generateRealUUID` from `lib/flutter_flow/custom_functions.dart`.
**Alternatives considered**: Using the `uuid` package directly or relying on database-side UUID generation.
**Rationale**: `generateRealUUID` is already present in the codebase and used in similar components, ensuring consistency.

## Data Flow
1. **Search**: `StockUpdateWidget` → `_model.searchProducts(query)` → `ProductosTable().queryRows()` → Supabase.
2. **Add to Batch**: `StockUpdateWidget` → `_model.addToBatch(product, qty, type)` → `batchQueue`.
3. **Quick Create**: `StockUpdateWidget` → `_model.createQuickProduct()` → Supabase → `batchQueue`.
4. **Process Batch**: `StockUpdateWidget` → `_model.processBatch()` → `Supabase.instance.client.rpc('update_product_stock')`.

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/components/stock_update_modal/stock_update_model.dart` | Modify | Remove duplicate declaration and inheritance. Add missing imports and fix method logic. |
| `lib/components/stock_update_modal/stock_update_widget.dart` | Modify | Fix model initialization and UI bugs (index out of bounds in search results). |

## Interfaces / Contracts

```dart
class StockItem {
  final ProductosRow product;
  int quantity;
  final String type;
  StockItem({required this.product, required this.quantity, required this.type});
}

class StockUpdateModel {
  List<ProductosRow> searchResults = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  List<StockItem> batchQueue = [];
  bool isCreatingNew = false;
  TextEditingController newProductNameController = TextEditingController();
  TextEditingController newProductPriceController = TextEditingController();
  bool isProcessing = false;
  
  void dispose();
  Future<void> searchProducts(String query);
  void addToBatch(ProductosRow product, int qty, String type);
  Future<ProductosRow?> createQuickProduct();
  Future<bool> processBatch();
}
```

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | Model Logic | Test `addToBatch` and `searchProducts` logic (with mocked Supabase). |
| Integration | Widget-Model Interaction | Test that searching updates the UI and adding to batch updates the list. |

## Migration / Rollout
No migration required.

## Open Questions
None.
