import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/notification.dart';

class NotificationModel extends Notification {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.leadId,
    required super.type,
    required super.title,
    required super.body,
    required super.read,
    required super.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      leadId: data['leadId'] as String? ?? '',
      type: NotificationType.fromString(data['type'] as String? ?? 'leadAssigned'),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      read: data['read'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'leadId': leadId,
      'type': type.name,
      'title': title,
      'body': body,
      'read': read,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

