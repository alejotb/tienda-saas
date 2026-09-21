import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:flutter/material.dart';

class UserService {
  static final UserService instance = UserService._internal();
  UserService._internal();

  // Variable para recordar a dónde volver después del registro/perfil
  String? _returnPath;
  String? get returnPath => _returnPath;
  set returnPath(String? path) => _returnPath = path;

  /// Actualiza el perfil del usuario con nombre e imagen
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? imagePath,
  }) async {
    try {
      final user = SupaFlow.client.auth.currentUser;
      if (user == null) return {'success': false, 'message': 'No hay usuario autenticado'};

      final updates = <String, dynamic>{
        'nombre_completo': name,
      };

      if (imagePath != null && imagePath.isNotEmpty) {
        updates['foto'] = imagePath;
      }

      await SupaFlow.client
          .from('usuarios')
          .update(updates)
          .eq('id', user.id);

      return {'success': true, 'message': 'Perfil actualizado correctamente'};
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return {'success': false, 'message': 'Error al actualizar el perfil'};
    }
  }

  /// Elimina la cuenta del usuario actual invocando la Edge Function
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final user = SupaFlow.client.auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No hay un usuario autenticado'};
      }

      final userId = user.id;

      // Llamamos a la Edge Function 'delete-user'
      final response = await SupaFlow.client.functions.invoke(
        'delete-user',
        body: {'user_id': userId},
      );

      if (response.status == 200) {
        return {'success': true, 'message': 'Cuenta eliminada exitosamente'};
      } else {
        final errorData = response.data;
        return {
          'success': false, 
          'message': errorData is Map ? (errorData['error'] ?? 'Error desconocido') : 'Error en el servidor'
        };
      }
    } catch (e) {
      debugPrint('Error crítico in deleteAccount: $e');
      return {'success': false, 'message': 'Error de conexión con el servidor'};
    }
  }
}
