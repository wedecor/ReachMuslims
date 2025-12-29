import '../models/notification.dart';

abstract class NotificationRepository {
  Stream<List<Notification>> streamNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String? leadId,
  });
}

