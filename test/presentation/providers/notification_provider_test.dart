import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import '../../../lib/presentation/providers/notification_provider.dart';
import '../../../lib/domain/repositories/notification_repository.dart';
import '../../../lib/domain/models/notification.dart';
import '../../../lib/core/errors/failures.dart';
import '../../helpers/test_helpers.dart';

class MockNotificationRepository extends Mock implements NotificationRepository {}

void main() {
  group('NotificationProvider', () {
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

    test('should initialize with loading state', () {
      // Arrange
      const userId = 'user-123';
      when(() => mockNotificationRepository.streamNotifications(userId))
          .thenAnswer((_) => Stream.value([]));

      // Act
      final notifier = container.read(notificationListProvider(userId).notifier);
      final state = container.read(notificationListProvider(userId));

      // Assert
      expect(state.isLoading, isTrue);
      expect(state.notifications, isEmpty);
    });

    test('should update state when notifications stream emits', () async {
      // Arrange
      const userId = 'user-123';
      final testNotifications = [
        TestHelpers.createTestNotification(
          id: 'notif1',
          title: 'Test Notification 1',
          read: false,
        ),
        TestHelpers.createTestNotification(
          id: 'notif2',
          title: 'Test Notification 2',
          read: true,
        ),
      ];

      when(() => mockNotificationRepository.streamNotifications(userId))
          .thenAnswer((_) => Stream.value(testNotifications));

      // Act
      await Future.delayed(const Duration(milliseconds: 100));
      final state = container.read(notificationListProvider(userId));

      // Assert
      expect(state.isLoading, isFalse);
      expect(state.notifications.length, equals(2));
      expect(state.unreadCount, equals(1));
    });

    test('should mark notification as read', () async {
      // Arrange
      const userId = 'user-123';
      const notificationId = 'notif-123';

      when(() => mockNotificationRepository.streamNotifications(userId))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockNotificationRepository.markAsRead(notificationId))
          .thenAnswer((_) async => Future.value());

      // Act
      final notifier = container.read(notificationListProvider(userId).notifier);
      await notifier.markAsRead(notificationId);

      // Assert
      verify(() => mockNotificationRepository.markAsRead(notificationId)).called(1);
    });

    test('should mark all notifications as read', () async {
      // Arrange
      const userId = 'user-123';

      when(() => mockNotificationRepository.streamNotifications(userId))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockNotificationRepository.markAllAsRead(userId))
          .thenAnswer((_) async => Future.value());

      // Act
      final notifier = container.read(notificationListProvider(userId).notifier);
      await notifier.markAllAsRead();

      // Assert
      verify(() => mockNotificationRepository.markAllAsRead(userId)).called(1);
    });
  });
}

