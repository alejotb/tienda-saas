# Spec: Favorites Synchronization

## Requirements

### Requirement: Local Persistence
The system MUST persist favorite products in `SharedPreferences` using the `ff_itemsFavoritos` key, regardless of the user's authentication status.

### Requirement: Remote Persistence
When a user is authenticated, any change to the favorites list MUST be mirrored in the `usuarios.favoriteItems` column in Supabase.

### Requirement: Merge on Login
Upon successful authentication, the system MUST:
1. Fetch `favoriteItems` from the `usuarios` table.
2. Merge these with the current local `itemsFavoritos` list (Union operation: remove duplicates).
3. Update both the local state and the remote database with the merged list.

### Requirement: UI Decoupling
UI components MUST NOT call `FFAppState` methods directly to modify favorites. They MUST use the `FavoritesService`.

## Scenarios

### Scenario: Anonymous Favorite
- GIVEN the user is not logged in
- WHEN the user toggles a product as favorite
- THEN the product ID is added/removed from `FFAppState().itemsFavoritos` and persisted locally.

### Scenario: Authenticated Favorite
- GIVEN the user is logged in
- WHEN the user toggles a product as favorite
- THEN the product ID is updated in `FFAppState().itemsFavoritos` (local) AND the `usuarios` table (remote).

### Scenario: Login Sync
- GIVEN a user has 2 favorites locally (anonymous) and 3 favorites on the server
- WHEN the user logs in
- THEN the final list should contain 5 unique product IDs (or fewer if there was overlap).
- AND this list is saved to both local and remote storage.
