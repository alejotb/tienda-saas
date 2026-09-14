# Tasks: topnav-auth-transition

## Phase 1: Core Implementation

- [ ] 1.1 Update imports in `lib/components/top_nav/top_nav_widget.dart` to include `loggedIn` from `lib/auth/base_auth_user_provider.dart`.
- [ ] 1.2 Replace `FFAppState().invitado` with `loggedIn` in the `Visibility` widget for the notification bell in `lib/components/top_nav/top_nav_widget.dart`.
- [ ] 1.3 Replace `FFAppState().invitado` with `loggedIn` in the user profile rendering logic in `lib/components/top_nav/top_nav_widget.dart`.

## Phase 2: Verification

- [ ] 2.1 Verify Guest UI (login/signup) displays when `loggedIn` is false.
- [ ] 2.2 Verify Authenticated UI (profile/notifications) displays when `loggedIn` is true.
- [ ] 2.3 Run `flutter analyze` to ensure no compilation errors or unused imports in `lib/components/top_nav/top_nav_widget.dart`.
