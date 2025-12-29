import 'package:flutter_test/flutter_test.dart';
import '../../../lib/domain/models/notification.dart';

void main() {
  group('Notification', () {
    test('should create Notification with all fields', () {
      // Arrange
      final now = DateTime.now();
      const id = 'notification-123';
      const userId = 'user-123';
      const leadId = 'lead-123';
      const type = NotificationType.leadAssigned;
      const title = 'Test Notification';
      const body = 'Test body';
      const read = false;

      // Act
      final notification = Notification(
        id: id,
        userId: userId,
        leadId: leadId,
        type: type,
        title: title,
        body: body,
        read: read,
        createdAt: now,
      );

      // Assert
      expect(notification.id, equals(id));
      expect(notification.userId, equals(userId));
      expect(notification.leadId, equals(leadId));
      expect(notification.type, equals(type));
      expect(notification.title, equals(title));
      expect(notification.body, equals(body));
      expect(notification.read, equals(read));
      expect(notification.createdAt, equals(now));
    });

    test('NotificationType.fromString should parse correctly', () {
      // Enum names are camelCase, fromString converts to lowercase
      expect(NotificationType.fromString('leadAssigned'), equals(NotificationType.leadAssigned));
      expect(NotificationType.fromString('leadReassigned'), equals(NotificationType.leadReassigned));
      expect(NotificationType.fromString('leadStatusChanged'), equals(NotificationType.leadStatusChanged));
      expect(NotificationType.fromString('followUpAdded'), equals(NotificationType.followUpAdded));
      expect(NotificationType.fromString('unknown'), equals(NotificationType.leadAssigned)); // Default
    });
  });
}

