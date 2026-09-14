# Tasks: Fix Stock Update Modal

## Phase 1: Foundation
- [x] 1.1 Refactor `lib/components/stock_update_modal/stock_update_model.dart`: Remove duplicate class and `StatefulWidget` declaration.
- [x] 1.2 Add missing imports to `stock_update_model.dart`: `custom_functions.dart` as `functions`.

## Phase 2: Core Implementation (Model)
- [x] 2.1 Implement `searchProducts` method in `StockUpdateModel`.
- [x] 2.2 Implement `addToBatch` method in `StockUpdateModel`.
- [x] 2.3 Implement `createQuickProduct` method in `StockUpdateModel` with correct UUID generation and Supabase insert.
- [x] 2.4 Implement `processBatch` method in `StockUpdateModel` with RPC calls.

## Phase 3: UI Wiring (Widget)
- [x] 3.1 Update `lib/components/stock_update_modal/stock_update_widget.dart`: Initialize `StockUpdateModel` correctly in `initState`.
- [x] 3.2 Fix index bug in `_stockButton` (if still used) or ensure `_qtyActionButton` is used correctly.
- [x] 3.3 Ensure all model method calls in the widget match the new model interface.

## Phase 4: Verification
- [ ] 4.1 Verify product search works as expected.
- [ ] 4.2 Verify adding products to batch updates the UI correctly.
- [ ] 4.3 Verify quick product creation inserts into Supabase and adds to batch.
- [ ] 4.4 Verify batch processing calls the RPC and clears the queue.
