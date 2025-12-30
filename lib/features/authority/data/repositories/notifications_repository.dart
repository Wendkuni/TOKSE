import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../models/notification_model.dart';

class NotificationsRepository {
  final _supabase = SupabaseConfig.client;

  // /// Récupérer toutes les notifications de l'autorité connectée
  // Future<List<NotificationModel>> getNotifications({String? typeFilter}) async {
  //   try {
  //     final authorityId = _supabase.auth.currentUser!.id;
  //     final filters = {'authority_id': authorityId};
  //     if (typeFilter != null && typeFilter != 'all') {
  //       filters['type'] = typeFilter;
  //     }
  //     final response = await _supabase
  //         .from('notifications')
  //         .select('*')
  //         .match(filters)
  //         .order('created_at', ascending: false);
  //
  //     return (response as List)
  //         .map((json) => NotificationModel.fromJson(json))
  //         .toList();
  //   } catch (e) {
  //     print('❌ [NOTIFICATIONS_REPO] Erreur lors du chargement: $e');
  //     return [];
  //   }
  // }

  // /// Récupérer le nombre de notifications non lues
  // Future<int> getUnreadCount() async {
  //   try {
  //     final response = await _supabase
  //         .from('notifications')
  //         .select('id')
  //         .eq('authority_id', _supabase.auth.currentUser!.id)
  //         .eq('is_read', false);
  //
  //     return (response as List).length;
  //   } catch (e) {
  //     print('❌ [NOTIFICATIONS_REPO] Erreur comptage non lues: $e');
  //     return 0;
  //   }
  // }

  // /// Marquer une notification comme lue
  // Future<bool> markAsRead(String notificationId) async {
  //   try {
  //     await _supabase
  //         .from('notifications')
  //         .update(
  //             {'is_read': true, 'updated_at': DateTime.now().toIso8601String()})
  //         .eq('id', notificationId)
  //         .eq('authority_id', _supabase.auth.currentUser!.id);
  //
  //     return true;
  //   } catch (e) {
  //     print('❌ [NOTIFICATIONS_REPO] Erreur marquage lu: $e');
  //     return false;
  //   }
  // }

  // /// Marquer toutes les notifications comme lues
  // Future<bool> markAllAsRead() async {
  //   try {
  //     await _supabase
  //         .from('notifications')
  //         .update(
  //             {'is_read': true, 'updated_at': DateTime.now().toIso8601String()})
  //         .eq('authority_id', _supabase.auth.currentUser!.id)
  //         .eq('is_read', false);
  //
  //     return true;
  //   } catch (e) {
  //     print('❌ [NOTIFICATIONS_REPO] Erreur marquage tous lus: $e');
  //     return false;
  //   }
  // }

  // /// Supprimer une notification
  // Future<bool> deleteNotification(String notificationId) async {
  //   try {
  //     await _supabase
  //         .from('notifications')
  //         .delete()
  //         .eq('id', notificationId)
  //         .eq('authority_id', _supabase.auth.currentUser!.id);
  //
  //     return true;
  //   } catch (e) {
  //     print('❌ [NOTIFICATIONS_REPO] Erreur suppression: $e');
  //     return false;
  //   }
  // }

  // /// Créer une notification manuellement (pour tests ou cas spéciaux)
  // Future<bool> createNotification({
  //   required String authorityId,
  //   required String title,
  //   required String message,
  //   required String type,
  //   String? signalementId,
  // }) async {
  //   try {
  //     await _supabase.from('notifications').insert({
  //       'authority_id': authorityId,
  //       'title': title,
  //       'message': message,
  //       'type': type,
  //       'signalement_id': signalementId,
  //       'is_read': false,
  //     });
  //
  //     return true;
  //   } catch (e) {
  //     print('❌ [NOTIFICATIONS_REPO] Erreur création: $e');
  //     return false;
  //   }
  // }

  // /// Écouter les nouvelles notifications en temps réel
  // RealtimeChannel subscribeToNotifications(
  //     Function(NotificationModel) onNotification) {
  //   final channel = _supabase
  //       .channel('notifications_${_supabase.auth.currentUser!.id}')
  //       .onPostgresChanges(
  //         event: PostgresChangeEvent.insert,
  //         schema: 'public',
  //         table: 'notifications',
  //         filter: PostgresChangeFilter(
  //           type: PostgresChangeFilterType.eq,
  //           column: 'authority_id',
  //           value: _supabase.auth.currentUser!.id,
  //         ),
  //         callback: (payload) {
  //           print('🔔 [NOTIFICATIONS_REPO] Nouvelle notification reçue');
  //           final notification = NotificationModel.fromJson(payload.newRecord);
  //           onNotification(notification);
  //         },
  //       )
  //       .subscribe();
  //
  //   return channel;
  // }

  // /// Nettoyer les anciennes notifications (plus de 30 jours et lues)
  // Future<void> cleanupOldNotifications() async {
  //   try {
  //     await _supabase.rpc('cleanup_old_notifications');
  //     print('✅ [NOTIFICATIONS_REPO] Anciennes notifications nettoyées');
  //   } catch (e) {
  //     print('❌ [NOTIFICATIONS_REPO] Erreur nettoyage: $e');
  //   }
  // }
}
