import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import '../../../lib/presentation/screens/notification_inbox_screen.dart';
import '../../../lib/presentation/providers/notification_provider.dart';
import '../../../lib/presentation/providers/auth_provider.dart';
import '../../../lib/presentation/providers/lead_list_provider.dart';
import '../../../lib/domain/repositories/notification_repository.dart';
import '../../../lib/domain/repositories/auth_repository.dart';
import '../../../lib/domain/repositories/lead_repository.dart';
import '../../../lib/domain/models/notification.dart';
import '../../../lib/domain/models/user.dart';
import '../../helpers/test_helpers.dart';

class MockNotificationRepository extends Mock implements NotificationRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockLeadRepository extends Mock implements LeadRepository {}

void main() {
  group('NotificationInboxScreen', () {
    late MockNotificationRepository mockNotificationRepository;
    late MockAuthRepository mockAuthRepository;
    late MockLeadRepository mockLeadRepository;
    late ProviderContainer container;

    setUp(() {
      mockNotificationRepository = MockNotificationRepository();
      mockAuthRepository = MockAuthRepository();
      mockLeadRepository = MockLeadRepository();
      container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(mockNotificationRepository),
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          leadRepositoryProvider.overrideWithValue(mockLeadRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget createTestWidget(Widget child) {
      return ProviderScope(
        parent: container,
        child: MaterialApp(
          home: child,
        ),
      );
    }

    Future<void> initializeAuth(User user) async {
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => user);
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(user));
      container.read(authProvider);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    testWidgets('should display empty state when no notifications', (WidgetTester tester) async {
      // Arrange
      final user = TestHelpers.createTestUser();
      await initializeAuth(user);

      when(() => mockNotificationRepository.streamNotifications(user.uid))
          .thenAnswer((_) => Stream.value([]));

      // Act
      await tester.pumpWidget(createTestWidget(const NotificationInboxScreen()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No notifications'), findsOneWidget);
      expect(find.text('You\'ll see notifications here when leads are assigned or updated'), findsOneWidget);
    });

    testWidgets('should display notifications list', (WidgetTester tester) async {
      // Arrange
      final user = TestHelpers.createTestUser();
      await initializeAuth(user);

      final notifications = [
        TestHelpers.createTestNotification(
          id: '1',
          title: 'Lead Assigned',
          body: 'You have been assigned to a lead',
          read: false,
        ),
        TestHelpers.createTestNotification(
          id: '2',
          title: 'Status Changed',
          body: 'Lead status updated',
          read: true,
        ),
      ];

      when(() => mockNotificationRepository.streamNotifications(user.uid))
          .thenAnswer((_) => Stream.value(notifications));

      // Act
      await tester.pumpWidget(createTestWidget(const NotificationInboxScreen()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Lead Assigned'), findsOneWidget);
      expect(find.text('Status Changed'), findsOneWidget);
      expect(find.text('You have been assigned to a lead'), findsOneWidget);
    });

    testWidgets('should highlight unread notifications', (WidgetTester tester) async {
      // Arrange
      final user = TestHelpers.createTestUser();
      await initializeAuth(user);

      final notifications = [
        TestHelpers.createTestNotification(
          id: '1',
          title: 'Unread Notification',
          read: false,
        ),
        TestHelpers.createTestNotification(
          id: '2',
          title: 'Read Notification',
          read: true,
        ),
      ];

      when(() => mockNotificationRepository.streamNotifications(user.uid))
          .thenAnswer((_) => Stream.value(notifications));

      // Act
      await tester.pumpWidget(createTestWidget(const NotificationInboxScreen()));
      await tester.pumpAndSettle();

      // Assert
      final unreadTile = find.text('Unread Notification');
      expect(unreadTile, findsOneWidget);
      
      // Check that unread notification has bold text
      final unreadWidget = tester.widget<Text>(find.descendant(
        of: unreadTile,
        matching: find.byType(Text),
      ).first);
      expect(unreadWidget.style?.fontWeight, equals(FontWeight.bold));
    });

    testWidgets('should show mark all as read button when unread notifications exist', (WidgetTester tester) async {
      // Arrange
      final user = TestHelpers.createTestUser();
      await initializeAuth(user);

      final notifications = [
        TestHelpers.createTestNotification(id: '1', read: false),
        TestHelpers.createTestNotification(id: '2', read: false),
      ];

      when(() => mockNotificationRepository.streamNotifications(user.uid))
          .thenAnswer((_) => Stream.value(notifications));
      when(() => mockNotificationRepository.markAllAsRead(user.uid))
          .thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(createTestWidget(const NotificationInboxScreen()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Mark all as read'), findsOneWidget);
    });

    testWidgets('should mark notification as read on tap', (WidgetTester tester) async {
      // Arrange
      final user = TestHelpers.createTestUser();
      await initializeAuth(user);

      final notifications = [
        TestHelpers.createTestNotification(
          id: 'notif-1',
          title: 'Test Notification',
          read: false,
        ),
      ];

      when(() => mockNotificationRepository.streamNotifications(user.uid))
          .thenAnswer((_) => Stream.value(notifications));
      when(() => mockNotificationRepository.markAsRead('notif-1'))
          .thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(createTestWidget(const NotificationInboxScreen()));
      await tester.pumpAndSettle();

      // Tap notification
      await tester.tap(find.text('Test Notification'));
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockNotificationRepository.markAsRead('notif-1')).called(1);
    });

    testWidgets('should navigate to lead detail when notification tapped', (WidgetTester tester) async {
      // Arrange
      final user = TestHelpers.createTestUser();
      await initializeAuth(user);

      final lead = TestHelpers.createTestLead(id: 'lead-123', name: 'Test Lead');
      final notifications = [
        TestHelpers.createTestNotification(
          id: 'notif-1',
          leadId: 'lead-123',
          read: false,
        ),
      ];

      when(() => mockNotificationRepository.streamNotifications(user.uid))
          .thenAnswer((_) => Stream.value(notifications));
      when(() => mockNotificationRepository.markAsRead('notif-1'))
          .thenAnswer((_) async => Future.value());
      when(() => mockLeadRepository.getLeadById('lead-123'))
          .thenAnswer((_) async => lead);

      // Act
      await tester.pumpWidget(createTestWidget(const NotificationInboxScreen()));
      await tester.pumpAndSettle();

      // Tap notification
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();

      // Assert - should navigate to LeadDetailScreen
      expect(find.byType(LeadDetailScreen), findsOneWidget);
    });
  });
}

