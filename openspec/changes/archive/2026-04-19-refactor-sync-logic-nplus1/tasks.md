# Tasks: Refactor synchronization logic to remove N+1 requests and introduce DTOs

## Phase 1: Foundation / Infrastructure

- [x] 1.1 Create `lib/custom_code/actions/sync_dtos.dart` and implement `WooCategoryDto` and `WooOrderDto`
- [x] 1.2 Update `lib/backend/supabase/database/tables/pedidos.dart` (`PedidosRow`) to include new fields used in `WooOrderDto`

## Phase 2: Core Implementation

- [x] 2.1 Modify `lib/custom_code/actions/sync_categories.dart` to implement pre-fetch of categories and bulk upsert strategy
- [x] 2.2 Implement chunking mechanism (batch size 100) for category upserts in `lib/custom_code/actions/sync_categories.dart`
- [x] 2.3 Modify `lib/custom_code/actions/sync_orders.dart` to implement DTO mapping from WooCommerce to `WooOrderDto`
- [x] 2.4 Implement bulk upsert strategy for orders in `lib/custom_code/actions/sync_orders.dart`
- [x] 2.5 Implement chunking mechanism (batch size 100) for order upserts in `lib/custom_code/actions/sync_orders.dart`

## Phase 3: Verification

- [ ] 3.1 Run `flutter analyze` to verify no type errors were introduced
- [ ] 3.2 Verify the reduction of network requests during a test synchronization process
