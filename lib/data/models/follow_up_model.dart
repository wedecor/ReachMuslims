import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/follow_up.dart';

class FollowUpModel extends FollowUp {
  const FollowUpModel({
    required super.id,
    required super.note,
    required super.createdBy,
    super.createdByName,
    required super.createdAt,
    super.type,
    super.region,
    super.messagePreview,
  });

  factory FollowUpModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FollowUpModel(
      id: doc.id,
      note: data['note'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: data['type'] as String?,
      region: data['region'] as String?,
      messagePreview: data['messagePreview'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'note': note,
      'createdBy': createdBy,
      if (createdByName != null) 'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      if (type != null) 'type': type,
      if (region != null) 'region': region,
      if (messagePreview != null) 'messagePreview': messagePreview,
    };
  }
}

