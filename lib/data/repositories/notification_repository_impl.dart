import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../core/errors/failures.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Notification>> streamNotifications(String userId) {
    try {
      return _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList();
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to stream notifications: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to mark notification as read: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String? leadId,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'leadId': leadId ?? '',
        'type': 'accountApproved',
        'title': title,
        'body': body,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to create notification: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to mark all as read: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }
}

