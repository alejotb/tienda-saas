# Proposal: Favorites Synchronization System

## Intent
Implement a robust synchronization mechanism for favorite products that bridges local persistent state (SharedPreferences) and remote storage (Supabase). This ensures users don't lose their preferences when switching devices or logging in/out.

## Scope

### In Scope
- Centralize favorite logic into a `FavoritesService`.
- Synchronize local `ff_itemsFavoritos` with Supabase `usuarios.favoriteItems` column.
- Implement "Merge on Login" strategy to preserve anonymous favorites.
- Refactor UI components to use the service instead of direct state manipulation.

### Out of Scope
- Implementing a separate `user_favorites` relational table (sticking to the current array-based schema for simplicity and speed).
- Complex conflict resolution (last-write-wins is sufficient for favorites).

## Approach
1. **Service Layer**: Create `FavoritesService` to handle the business logic of adding/removing favorites.
2. **State Management**: Use `FFAppState` as the reactive bridge to the UI.
3. **Remote Sync**: Use Supabase client to update the user's profile.
4. **Init Logic**: Hook into the authentication flow to trigger synchronization upon successful login.

## Success Criteria
- [ ] Toggle heart updates local state instantly.
- [ ] Toggle heart updates Supabase if user is authenticated.
- [ ] Logging in merges local favorites with remote favorites.
- [ ] Favorites persist across app restarts.
