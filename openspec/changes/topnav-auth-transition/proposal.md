# Proposal: TopNav Auth State Transition

## Intent

Currently, `TopNavWidget` uses `FFAppState().invitado` as the sole indicator for Guest vs. Authenticated UI. This creates a discrepancy when a user is logged in but the `invitado` flag remains true, causing the Guest UI to be displayed incorrectly. We need to make the actual authentication session (`loggedIn` state) the primary source of truth.

## Scope

### In Scope
- Update conditional rendering logic in `TopNavWidget`.
- Integration with `BaseAuthUserProvider` to check `loggedIn` status.
- Ensure correct UI state: Authenticated > Guest > Fallback.

### Out of Scope
- Global refactoring of `FFAppState().invitado` usage in other components.
- Changes to the login/logout flow logic itself.

## Capabilities

### New Capabilities
- `topnav-auth-state`: Correctly determines and displays the user identity section in the top navigation based on actual session status and guest flags.

### Modified Capabilities
- None

## Approach

Modify `lib/components/top_nav/top_nav_widget.dart` to implement the following priority logic:
1. **Priority 1 (Authenticated)**: If `BaseAuthUserProvider.loggedIn` is `true` $\rightarrow$ Render Authenticated UI (User photo and name).
2. **Priority 2 (Guest)**: If `BaseAuthUserProvider.loggedIn` is `false` AND `FFAppState().invitado` is `true` $\rightarrow$ Render Guest UI.
3. **Priority 3 (Fallback)**: Otherwise $\rightarrow$ Render Guest UI (default fallback).

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/components/top_nav/top_nav_widget.dart` | Modified | Updated conditional logic for the user profile section. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| UI not updating on auth change | Low | Ensure `BaseAuthUserProvider` is correctly watched/consumed in the widget tree. |

## Rollback Plan

Revert the changes in `lib/components/top_nav/top_nav_widget.dart` via git to restore the previous behavior.

## Dependencies

- `BaseAuthUserProvider` must provide a reliable `loggedIn` getter.

## Success Criteria

- [ ] Logged-in users see Authenticated UI regardless of `FFAppState().invitado` value.
- [ ] Unauthenticated users with `invitado = true` see Guest UI.
- [ ] Unauthenticated users with `invitado = false` see Guest UI (fallback).
