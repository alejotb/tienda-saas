# Design: Cleanup of FFAppState().invitado Flag

## Technical Approach

The goal is to eliminate the reliance on the persisted `FFAppState().invitado` flag for determining the user's authentication status in the UI. Instead, the application will use the `loggedIn` getter from `BaseAuthUserProvider`, which reflects the actual session state from Supabase.

This maps directly to the proposal by establishing a single source of truth for authentication, preventing "zombie states" where a user is authenticated but the UI still shows guest-related elements (or vice versa).

## Architecture Decisions

### Decision: Single Source of Truth for Auth State

**Choice**: Use `BaseAuthUserProvider.loggedIn` instead of `FFAppState().invitado`.
**Alternatives considered**: Keeping both and syncing them.
**Rationale**: Syncing a persisted state with a session state is error-prone and leads to the exact desynchronization issues we are solving. Using the session state directly is the only way to guarantee the UI is always in sync with the backend.

### Decision: Import Strategy

**Choice**: Explicitly import `package:baul_pandora/auth/base_auth_user_provider.dart` in all affected widgets.
**Alternatives considered**: Adding `loggedIn` to `FFAppState`.
**Rationale**: `loggedIn` is a dynamic property of the authentication provider, not a static piece of application state. Keeping it in the auth provider maintains a cleaner separation of concerns.

### Decision: Phased Implementation (Batching)

**Choice**: Implement changes in 4 batches of files.
**Alternatives considered**: Single global find-and-replace.
**Rationale**: A global replace in a large codebase can introduce subtle bugs if `invitado` was used for something other than session checks. Batching allows for targeted verification of each functional area (e.g., Checkout, Profile).

## Data Flow

The authentication state now flows directly from the provider to the UI components.

```
Supabase Session ──→ BaseAuthUserProvider (loggedIn) ──→ Widget (Build Method) ──→ UI Render
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/components/product_grid/product_grid_widget.dart` | Modify | Replace `FFAppState().invitado` with `loggedIn` |
| `lib/pages/main_profile/main_profile_widget.dart` | Modify | Replace `FFAppState().invitado` with `loggedIn` and remove redundant assignments |
| `lib/pages/checkout_full_page_copy/checkout_full_page_copy_widget.dart` | Modify | Replace `FFAppState().invitado` with `loggedIn` |
| `lib/pages/product_details/product_details_widget.dart` | Modify | Replace `FFAppState().invitado` with `loggedIn` |
| `lib/pages/main_home_page/main_home_page_widget.dart` | Modify | Replace `FFAppState().invitado` with `loggedIn` |
| `lib/pages/login_page/login_page_widget.dart` | Modify | Remove assignments to `FFAppState().invitado` used for UI branching |
| `lib/pages/full_cart_view/full_cart_view_widget.dart` | Modify | Replace `FFAppState().invitado` with `loggedIn` |
| `lib/pages/checkout_full_page/checkout_full_page_widget.dart` | Modify | Replace `FFAppState().invitado` with `loggedIn` |
| `lib/dropdowns/order_summary_new/order_summary_new_widget.dart` | Modify | Replace `FFAppState().invitado` with `loggedIn` |
| `lib/dropdowns/modal_create_account/modal_create_account_widget.dart` | Modify | Remove assignments to `FFAppState().invitado` |
| `lib/dropdowns/dropdown_account_guest/dropdown_account_guest_widget.dart` | Modify | Remove assignments to `FFAppState().invitado` |
| `lib/components/tarjeta_producto/tarjeta_producto_widget.dart` | Modify | Replace `FFAppState().invitado` with `loggedIn` |
| `lib/components/product_list_view/product_list_view_widget.dart` | Modify | Replace `FFAppState().invitado` with `loggedIn` |
| `lib/components/product_inventory_list_view/product_inventory_list_view_widget.dart` | Modify | Replace `FFAppState().invitado` with `loggedIn` |
| `lib/components/categoria_list_view/categoria_list_view_widget.dart` | Modify | Replace `FFAppState().invitado` with `loggedIn` |

## Interfaces / Contracts

No new interfaces are introduced. We are utilizing the existing `loggedIn` getter:

```dart
// lib/auth/base_auth_user_provider.dart
bool get loggedIn => currentUser?.loggedIn ?? false;
```

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Manual | Auth State Transitions | Log in and log out and verify that the UI updates immediately across all identified pages without "zombie" guest states. |
| Manual | Guest Experience | Verify that users who are not logged in still see the "Guest" UI as expected. |
| Static | Import Verification | Ensure no compilation errors due to missing `BaseAuthUserProvider` imports. |

## Migration / Rollout

No data migration required. The `FFAppState().invitado` flag will remain in `app_state.dart` for now to avoid breaking other potentially unrelated systems, but it will no longer be used for UI session branching.

## Open Questions

- [ ] Are there any cases where `invitado` represents a "Guest Mode" preference that is independent of the authentication session? (Initial analysis suggests no, but will verify during implementation).
