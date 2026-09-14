# Design: Favorites Synchronization System

## Technical Architecture

The system will follow a Service-Oriented approach to decouple business logic from UI.

### 1. FavoritesService (New Class)
A singleton service responsible for all favorite-related operations.

**Methods**:
- `toggleFavorite(String productId)`:
  - Checks if `productId` is in `FFAppState().itemsFavoritos`.
  - Adds or removes it accordingly.
  - Calls `_syncWithRemote()` if authenticated.
- `syncFavorites()`:
  - Implementation of the "Merge on Login" logic.
  - Fetches remote list $\rightarrow$ Merges with local $\rightarrow$ Saves both.
- `_syncWithRemote()`:
  - Internal helper to update the `usuarios` table in Supabase.

### 2. FFAppState Integration
`FFAppState` will remain as the reactive store. `FavoritesService` will call `FFAppState` setters to trigger UI rebuilds.

### 3. Auth Integration
The `SupabaseAuthManager` (or the logic that handles successful login) will be updated to call `FavoritesService.instance.syncFavorites()` immediately after the user session is established.

## Data Flow

```
UI (Toggle) -> FavoritesService.toggleFavorite() 
               │
               ├─> FFAppState.itemsFavoritos (Local Update & UI Refresh)
               └─> (if authenticated) ─> Supabase: usuarios (Remote Update)
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/services/favorites_service.dart` | Create | New service for favorites logic |
| `lib/auth/supabase_auth/supabase_auth_manager.dart` | Modify | Trigger `syncFavorites()` on login |
| `lib/app_state.dart` | Modify | Optional: make `itemsFavoritos` private and provide methods through service |
| `lib/components/...` | Modify | Refactor toggle calls to use `FavoritesService.instance.toggleFavorite()` |

## Testing Strategy
1. **Anonymous Test**: Add favorites $\rightarrow$ Restart app $\rightarrow$ Verify persistence.
2. **Sync Test**: Add favorites (anon) $\rightarrow$ Login $\rightarrow$ Verify merged list.
3. **Remote Test**: Add favorite (auth) $\rightarrow$ Check Supabase Dashboard $\rightarrow$ Verify record.
