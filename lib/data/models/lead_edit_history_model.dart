import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/lead_edit_history.dart';

class LeadEditHistoryModel extends LeadEditHistory {
  const LeadEditHistoryModel({
    required super.id,
    required super.leadId,
    required super.editedBy,
    super.editedByName,
    super.editedByEmail,
    required super.editedAt,
    required super.changes,
  });

  factory LeadEditHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final changesData = data['changes'] as Map<String, dynamic>? ?? {};
    
    // Convert changes map to FieldChange objects
    final changes = <String, FieldChange>{};
    changesData.forEach((field, changeData) {
      if (changeData is Map) {
        changes[field] = FieldChange(
          oldValue: changeData['old'] as String?,
          newValue: changeData['new'] as String?,
        );
      }
    });

    return LeadEditHistoryModel(
      id: doc.id,
      leadId: data['leadId'] as String? ?? '',
      editedBy: data['editedBy'] as String? ?? '',
      editedByName: data['editedByName'] as String?,
      editedByEmail: data['editedByEmail'] as String?,
      editedAt: (data['editedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      changes: changes,
    );
  }

  Map<String, dynamic> toFirestore() {
    // Convert changes map to Firestore format
    final changesData = <String, Map<String, String?>>{};
    changes.forEach((field, change) {
      changesData[field] = {
        'old': change.oldValue,
        'new': change.newValue,
      };
    });

    return {
      'leadId': leadId,
      'editedBy': editedBy,
      if (editedByName != null) 'editedByName': editedByName,
      if (editedByEmail != null) 'editedByEmail': editedByEmail,
      'editedAt': Timestamp.fromDate(editedAt),
      'changes': changesData,
    };
  }
}

