import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baul_pandora/app_state.dart';

class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  /// Toggles a product's favorite status.
  Future<void> toggleFavorite(String productId) async {
    final currentFavorites = FFAppState().itemsFavoritos;
    List<String> newFavorites;

    if (currentFavorites.contains(productId)) {
      newFavorites = currentFavorites.where((id) => id != productId).toList();
    } else {
      newFavorites = [...currentFavorites, productId];
    }

    // 1. Update local state immediately for UI responsiveness
    FFAppState().itemsFavoritos = newFavorites;

    // 2. Sync with remote if authenticated
    if (Supabase.instance.client.auth.currentUser != null) {
      await _syncWithRemote(newFavorites);
    }
  }

  /// Synchronizes local favorites with remote favorites (used during login).
  Future<void> syncFavorites() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Fetch remote favorites
      final data = await Supabase.instance.client
          .from('usuarios')
          .select('favoriteitems')
          .eq('id', user.id)
          .single();

      final List<dynamic> remoteFavsRaw = data['favoriteitems'] ?? [];
      final List<String> remoteFavs = remoteFavsRaw.map((e) => e.toString()).toList();

      // 2. Merge with local favorites (Union)
      final localFavs = FFAppState().itemsFavoritos;
      final mergedFavs = {...remoteFavs, ...localFavs}.toList();

      // 3. Update both sources
      FFAppState().itemsFavoritos = mergedFavs;
      await _syncWithRemote(mergedFavs);

      print('Favorites synchronized successfully. Total: ${mergedFavs.length}');
    } catch (e) {
      print('Error synchronizing favorites: $e');
    }
  }

  /// Internal helper to update the usuarios table in Supabase.
  Future<void> _syncWithRemote(List<String> favorites) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('usuarios')
          .update({'favoriteitems': favorites})
          .eq('id', user.id);
    } catch (e) {
      print('Error updating remote favorites: $e');
    }
  }
}
