import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:baul_pandora/backend/supabase/supabase.dart';
import 'package:baul_pandora/auth/supabase_auth/auth_util.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  /// Envía una notificación creando el registro en ambas tablas.
  Future<void> send(List<String> userIds, String title, String message, {String type = 'sistema', String? link, Map<String, dynamic>? metadata}) async {
    try {
      // 1. Insertar en notificaciones_base
      final baseResponse = await SupaFlow.client.from('notificaciones_base').insert({
        'titulo': title,
        'mensaje': message,
        'tipo': type,
        'link': link,
        'metadata_accion': metadata,
      }).select('id').single();

      final notificationId = baseResponse['id'];

      // 2. Insertar en notificaciones_usuario para cada usuario
      final List<Map<String, dynamic>> userNotifications = userIds.map((userId) => {
        'notification_id': notificationId,
        'user_id': userId,
        'leido': false,
      }).toList();

      await SupaFlow.client.from('notificaciones_usuario').insert(userNotifications);
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  /// Obtiene notificaciones no leídas haciendo JOIN con notificaciones_base.
  Future<List<Map<String, dynamic>>> getUnreadNotifications() async {
    if (!loggedIn) return [];
    try {
      final response = await SupaFlow.client
          .from('notificaciones_usuario')
          .select('*, notificaciones_base!inner(*)')
          .eq('user_id', currentUserUid)
          .eq('leido', false)
          .order('fecha_creacion', ascending: false);
      
      return (response as List<dynamic>).map((n) {
        final map = n as Map<String, dynamic>;
        final base = map['notificaciones_base'] as Map<String, dynamic>;
        return <String, dynamic>{ ...base, 'leido': map['leido'], 'rel_id': map['id'] };
      }).toList();
    } catch (e) {
      print('Error fetching unread notifications: $e');
      return [];
    }
  }

  /// Fetches all notifications for the current user.
  Future<List<Map<String, dynamic>>> getAllNotifications() async {
    if (!loggedIn) return [];
    try {
      final response = await SupaFlow.client
          .from('notificaciones_usuario')
          .select('*, notificaciones_base!inner(*)')
          .eq('user_id', currentUserUid)
          .order('fecha_creacion', ascending: false);
      
      return (response as List<dynamic>).map((n) {
        final map = n as Map<String, dynamic>;
        final base = map['notificaciones_base'] as Map<String, dynamic>;
        return <String, dynamic>{ ...base, 'leido': map['leido'], 'rel_id': map['id'] };
      }).toList();
    } catch (e) {
      print('Error fetching all notifications: $e');
      return [];
    }
  }

  /// Marca una notificación como leída (en notificaciones_usuario).
  Future<void> markNotificationAsRead(String relId) async {
    try {
      await SupaFlow.client
          .from('notificaciones_usuario')
          .update({'leido': true, 'fecha_lectura': DateTime.now().toIso8601String()})
          .eq('id', relId);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Marca todas las notificaciones como leídas para el usuario actual.
  Future<void> markAllAsRead() async {
    if (!loggedIn) return;
    try {
      await SupaFlow.client
          .from('notificaciones_usuario')
          .update({'leido': true, 'fecha_lectura': DateTime.now().toIso8601String()})
          .eq('user_id', currentUserUid)
          .eq('leido', false);
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  /// Returns a stream of unread notification count for the current user.
  Stream<int> getUnreadCountStream() {
    if (!loggedIn) return Stream.value(0);
    try {
      return SupaFlow.client
          .from('notificaciones_usuario')
          .stream(primaryKey: ['id'])
          .map((event) => event.where((n) => n['user_id'] == currentUserUid && n['leido'] == false).length)
          .handleError((e) {
            debugPrint('Nota: Stream de notificaciones no disponible: $e');
            return 0;
          });
    } catch (e) {
      debugPrint('Nota: Error iniciando stream de notificaciones: $e');
      return Stream.value(0);
    }
  }
}
