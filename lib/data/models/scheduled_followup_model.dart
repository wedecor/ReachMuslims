import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/scheduled_followup.dart';

class ScheduledFollowUpModel extends ScheduledFollowUp {
  const ScheduledFollowUpModel({
    required super.id,
    required super.leadId,
    required super.scheduledAt,
    super.note,
    required super.createdBy,
    super.status,
    required super.createdAt,
  });

  factory ScheduledFollowUpModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ScheduledFollowUpModel(
      id: doc.id,
      leadId: data['leadId'] as String? ?? '',
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] as String?,
      createdBy: data['createdBy'] as String? ?? '',
      status: ScheduledFollowUpStatus.fromString(data['status'] as String? ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'leadId': leadId,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      if (note != null && note!.isNotEmpty) 'note': note,
      'createdBy': createdBy,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

