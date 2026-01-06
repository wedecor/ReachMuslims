import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/lead_activity.dart';

class LeadActivityModel extends LeadActivity {
  const LeadActivityModel({
    required super.id,
    required super.leadId,
    required super.type,
    required super.performedBy,
    super.performedByName,
    required super.performedAt,
    super.metadata,
  });

  factory LeadActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeadActivityModel(
      id: doc.id,
      leadId: data['leadId'] as String? ?? '',
      type: ActivityType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => ActivityType.fieldEdited,
      ),
      performedBy: data['performedBy'] as String? ?? '',
      performedByName: data['performedByName'] as String?,
      performedAt: (data['performedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: (data['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'leadId': leadId,
      'type': type.name,
      'performedBy': performedBy,
      if (performedByName != null) 'performedByName': performedByName,
      'performedAt': Timestamp.fromDate(performedAt),
      'metadata': metadata,
    };
  }
}

