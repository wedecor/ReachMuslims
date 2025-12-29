import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../lib/data/repositories/notification_repository_impl.dart';
import '../../../lib/domain/models/notification.dart';
import '../../../lib/core/errors/failures.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('NotificationRepositoryImpl', () {
    late FakeFirebaseFirestore firestore;
    late NotificationRepositoryImpl repository;

    setUp(() {
      firestore = TestHelpers.createMockFirestore();
      repository = NotificationRepositoryImpl(firestore: firestore);
    });

    group('streamNotifications', () {
      test('should stream notifications ordered by createdAt DESC', () async {
        // Arrange
        const userId = 'user-123';
        final now = DateTime.now();

        // Add notifications
        await firestore.collection('notifications').add({
          'userId': userId,
          'leadId': 'lead-1',
          'type': 'leadAssigned',
          'title': 'First',
          'body': 'First notification',
          'read': false,
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
        });

        await firestore.collection('notifications').add({
          'userId': userId,
          'leadId': 'lead-2',
          'type': 'leadAssigned',
          'title': 'Second',
          'body': 'Second notification',
          'read': false,
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
        });

        await firestore.collection('notifications').add({
          'userId': userId,
          'leadId': 'lead-3',
          'type': 'leadAssigned',
          'title': 'Third',
          'body': 'Third notification',
          'read': false,
          'createdAt': Timestamp.fromDate(now),
        });

        // Act
        final stream = repository.streamNotifications(userId);
        final notifications = await stream.first;

        // Assert
        expect(notifications.length, equals(3));
        // Should be ordered DESC (newest first)
        expect(notifications[0].title, equals('Third'));
        expect(notifications[1].title, equals('Second'));
        expect(notifications[2].title, equals('First'));
      });

      test('should only stream notifications for specific user', () async {
        // Arrange
        const userId1 = 'user-123';
        const userId2 = 'user-456';

        await firestore.collection('notifications').add({
          'userId': userId1,
          'leadId': 'lead-1',
          'type': 'leadAssigned',
          'title': 'User 1 Notification',
          'body': 'Body',
          'read': false,
          'createdAt': Timestamp.now(),
        });

        await firestore.collection('notifications').add({
          'userId': userId2,
          'leadId': 'lead-2',
          'type': 'leadAssigned',
          'title': 'User 2 Notification',
          'body': 'Body',
          'read': false,
          'createdAt': Timestamp.now(),
        });

        // Act
        final stream = repository.streamNotifications(userId1);
        final notifications = await stream.first;

        // Assert
        expect(notifications.length, equals(1));
        expect(notifications[0].title, equals('User 1 Notification'));
      });

      test('should stream empty list when no notifications', () async {
        // Arrange
        const userId = 'user-123';

        // Act
        final stream = repository.streamNotifications(userId);
        final notifications = await stream.first;

        // Assert
        expect(notifications, isEmpty);
      });
    });

    group('markAsRead', () {
      test('should mark notification as read', () async {
        // Arrange
        final docRef = await firestore.collection('notifications').add({
          'userId': 'user-123',
          'leadId': 'lead-1',
          'type': 'leadAssigned',
          'title': 'Test',
          'body': 'Body',
          'read': false,
          'createdAt': Timestamp.now(),
        });

        // Act
        await repository.markAsRead(docRef.id);

        // Assert
        final doc = await docRef.get();
        expect(doc.data()!['read'], isTrue);
      });
    });

    group('markAllAsRead', () {
      test('should mark all unread notifications as read', () async {
        // Arrange
        const userId = 'user-123';

        await firestore.collection('notifications').add({
          'userId': userId,
          'leadId': 'lead-1',
          'type': 'leadAssigned',
          'title': 'Unread 1',
          'body': 'Body',
          'read': false,
          'createdAt': Timestamp.now(),
        });

        await firestore.collection('notifications').add({
          'userId': userId,
          'leadId': 'lead-2',
          'type': 'leadAssigned',
          'title': 'Unread 2',
          'body': 'Body',
          'read': false,
          'createdAt': Timestamp.now(),
        });

        await firestore.collection('notifications').add({
          'userId': userId,
          'leadId': 'lead-3',
          'type': 'leadAssigned',
          'title': 'Already Read',
          'body': 'Body',
          'read': true,
          'createdAt': Timestamp.now(),
        });

        // Act
        await repository.markAllAsRead(userId);

        // Assert
        final snapshot = await firestore
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .get();

        final allRead = snapshot.docs.every((doc) => doc.data()['read'] == true);
        expect(allRead, isTrue);
      });
    });
  });
}

