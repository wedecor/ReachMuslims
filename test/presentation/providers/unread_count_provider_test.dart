import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import '../../../lib/presentation/providers/notification_provider.dart';
import '../../../lib/domain/repositories/notification_repository.dart';
import '../../../lib/domain/models/notification.dart';
import '../../helpers/test_helpers.dart';

class MockNotificationRepository extends Mock implements NotificationRepository {}

void main() {
  group('UnreadCountProvider', () {
    late MockNotificationRepository mockNotificationRepository;
    late ProviderContainer container;

    setUp(() {
      mockNotificationRepository = MockNotificationRepository();
      container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(mockNotificationRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should return 0 when no notifications', () async {
      // Arrange
      const userId = 'user-123';
      when(() => mockNotificationRepository.streamNotifications(userId))
          .thenAnswer((_) => Stream.value([]));

      // Act - trigger provider creation
      container.read(notificationListProvider(userId));
      await Future.delayed(const Duration(milliseconds: 150));
      final unreadCount = container.read(unreadCountProvider(userId));

      // Assert
      expect(unreadCount, equals(0));
    });

    test('should return correct unread count', () async {
      // Arrange
      const userId = 'user-123';
      final notifications = [
        TestHelpers.createTestNotification(id: '1', read: false),
        TestHelpers.createTestNotification(id: '2', read: true),
        TestHelpers.createTestNotification(id: '3', read: false),
        TestHelpers.createTestNotification(id: '4', read: false),
      ];

      when(() => mockNotificationRepository.streamNotifications(userId))
          .thenAnswer((_) => Stream.value(notifications));

      // Act - trigger provider creation
      container.read(notificationListProvider(userId));
      await Future.delayed(const Duration(milliseconds: 150));
      final unreadCount = container.read(unreadCountProvider(userId));

      // Assert
      expect(unreadCount, equals(3));
    });

    test('should update when notifications change', () async {
      // Arrange
      const userId = 'user-123';
      final streamController = StreamController<List<Notification>>();
      
      when(() => mockNotificationRepository.streamNotifications(userId))
          .thenAnswer((_) => streamController.stream);

      // Trigger provider creation
      container.read(notificationListProvider(userId));

      // Initial state: 2 unread
      streamController.add([
        TestHelpers.createTestNotification(id: '1', read: false),
        TestHelpers.createTestNotification(id: '2', read: false),
      ]);

      await Future.delayed(const Duration(milliseconds: 150));
      expect(container.read(unreadCountProvider(userId)), equals(2));

      // Update: 1 unread
      streamController.add([
        TestHelpers.createTestNotification(id: '1', read: true),
        TestHelpers.createTestNotification(id: '2', read: false),
      ]);

      await Future.delayed(const Duration(milliseconds: 150));
      expect(container.read(unreadCountProvider(userId)), equals(1));

      await streamController.close();
    });
  });
}

