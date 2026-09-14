# Proposal: Refactor synchronization logic to remove N+1 requests and introduce DTOs

## Intent

Reduce the number of network requests during WooCommerce synchronization for categories and orders. Currently, the logic performs N+1 requests (fetching/updating items individually), leading to poor performance and potential rate limiting. Aligning this with the `syncProducts` pattern (DTOs + Batch Upserts) will improve efficiency and maintainability.

## Scope

### In Scope
- Implementation of `WooCategoryDto` for type-safe category mapping.
- Implementation of `WooOrderDto` for type-safe order mapping.
- Refactoring `syncCategories` to use batch upserts and pre-fetching for images.
- Refactoring `syncOrders` to use batch upserts.
- Updating `PedidosRow` definition in `lib/backend/supabase/database/tables/pedidos.dart` to align with the Supabase schema.

### Out of Scope
- Refactoring `syncProducts` (already follows the desired pattern).
- Adding new sync features beyond the current functionality.
- Changing the WooCommerce API version.

## Capabilities

### New Capabilities
- `woo-category-sync`: Synchronization of categories from WooCommerce to Supabase using batch operations.
- `woo-order-sync`: Synchronization of orders from WooCommerce to Supabase using batch operations.

### Modified Capabilities
- None

## Approach

1. **DTO Introduction**: Create `WooCategoryDto` and `WooOrderDto` to decouple the API response from the database model.
2. **Batch Upserts**: Replace individual `upsert` calls within loops with a single batch upsert operation.
3. **Image Pre-fetching**: In `syncCategories`, fetch existing category images in bulk to avoid per-item lookups.
4. **Schema Alignment**: Update the `PedidosRow` model to ensure it accurately reflects the database columns, preventing runtime mapping errors.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/custom_code/actions/sync_categories.dart` | Modified | Implement DTOs and batch upserts |
| `lib/custom_code/actions/sync_orders.dart` | Modified | Implement DTOs and batch upserts |
| `lib/backend/supabase/database/tables/pedidos.dart` | Modified | Update `PedidosRow` definition |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Memory overhead from large DTO lists | Low | The volume of categories/orders per sync is typically manageable |
| Data loss during batch upsert if one item fails | Low | Use transaction-like behavior or validate DTOs before batching |

## Rollback Plan

Revert changes to `sync_categories.dart`, `sync_orders.dart`, and `pedidos.dart` using git.

## Dependencies

- WooCommerce API access.
- Supabase database connectivity.

## Success Criteria

- [ ] `syncCategories` performs a constant number of network requests regardless of item count (O(1) upsert).
- [ ] `syncOrders` performs a constant number of network requests (O(1) upsert).
- [ ] `PedidosRow` matches the Supabase schema and no mapping errors occur.
- [ ] Synchronization completes faster and without N+1 query warnings in logs.
