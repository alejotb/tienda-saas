# Proposal: Cleanup of FFAppState().invitado Flag

## Intent

The `FFAppState().invitado` flag is currently used inconsistently across the application to determine if a user is a guest. Since this is a persisted state, it frequently becomes desynchronized from the actual authentication session provided by Supabase (`BaseAuthUserProvider`), leading to "zombie states" where authenticated users are still treated as guests in the UI.

This change will establish `BaseAuthUserProvider.loggedIn` as the single source of truth for authentication status.

## Scope

### In Scope
- Global replacement of `FFAppState().invitado` with `loggedIn` for session checks in the identified 15 widgets.
- Removal of redundant `FFAppState().invitado` assignments used solely for UI branching.
- Adding necessary imports for `loggedIn` in affected files.

### Out of Scope
- Changes to the `BaseAuthUserProvider` implementation.
- Implementation of a persistent "Guest Mode" preference if separate from the session.

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- None

## Approach

The refactoring will follow these rules:
1. Replace `if (FFAppState().invitado)` $\rightarrow$ `if (!loggedIn)` (Guest mode).
2. Replace `if (!FFAppState().invitado)` $\rightarrow$ `if (loggedIn)` (Authenticated mode).
3. Identify and remove lines that manually set `FFAppState().invitado = true/false` when used only for UI branching.
4. Ensure `BaseAuthUserProvider` is correctly imported in all modified files to provide the `loggedIn` getter.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/components/product_grid/product_grid_widget.dart` | Modified | Replace guest flag check |
| `lib/pages/main_profile/main_profile_widget.dart` | Modified | Replace guest flag check |
| `lib/pages/checkout_full_page_copy/checkout_full_page_copy_widget.dart` | Modified | Replace guest flag check |
| `lib/pages/product_details/product_details_widget.dart` | Modified | Replace guest flag check |
| `lib/pages/main_home_page/main_home_page_widget.dart` | Modified | Replace guest flag check |
| `lib/pages/login_page/login_page_widget.dart` | Modified | Replace guest flag check |
| `lib/pages/full_cart_view/full_cart_view_widget.dart` | Modified | Replace guest flag check |
| `lib/pages/checkout_full_page/checkout_full_page_widget.dart` | Modified | Replace guest flag check |
| `lib/dropdowns/order_summary_new/order_summary_new_widget.dart` | Modified | Replace guest flag check |
| `lib/dropdowns/modal_create_account/modal_create_account_widget.dart` | Modified | Replace guest flag check |
| `lib/dropdowns/dropdown_account_guest/dropdown_account_guest_widget.dart` | Modified | Replace guest flag check |
| `lib/components/tarjeta_producto/tarjeta_producto_widget.dart` | Modified | Replace guest flag check |
| `lib/components/product_list_view/product_list_view_widget.dart` | Modified | Replace guest flag check |
| `lib/components/product_inventory_list_view/product_inventory_list_view_widget.dart` | Modified | Replace guest flag check |
| `lib/components/categoria_list_view/categoria_list_view_widget.dart` | Modified | Replace guest flag check |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Regression if `invitado` had non-session meaning | Low | Verify use case in each file; preserve if it represents a specific setting |
| Import errors | Low | Careful addition of `BaseAuthUserProvider` imports |

## Rollback Plan

Revert the git commit containing the refactor.

## Dependencies

- `BaseAuthUserProvider` must provide a reliable `loggedIn` getter.

## Success Criteria

- [ ] `FFAppState().invitado` is no longer used for session-based UI branching.
- [ ] UI correctly reflects authenticated state immediately upon session change.
- [ ] No regression in functionality across the 15 affected widgets.
