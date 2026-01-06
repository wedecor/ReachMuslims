/// Enum representing different types of activities that can occur on a lead
enum ActivityType {
  leadCreated,
  statusChanged,
  assigned,
  reassigned,
  unassigned,
  priorityChanged,
  followUpAdded,
  followUpScheduled,
  fieldEdited,
  leadDeleted,
  leadRestored,
}

/// Represents a single activity/event in a lead's timeline
class LeadActivity {
  final String id;
  final String leadId;
  final ActivityType type;
  final String performedBy; // User UID
  final String? performedByName; // User name for display
  final DateTime performedAt;
  
  // Activity-specific data (stored as JSON-like structure)
  final Map<String, dynamic> metadata; // e.g., oldStatus, newStatus, oldValue, newValue, etc.

  const LeadActivity({
    required this.id,
    required this.leadId,
    required this.type,
    required this.performedBy,
    this.performedByName,
    required this.performedAt,
    this.metadata = const {},
  });

  String get displayTitle {
    switch (type) {
      case ActivityType.leadCreated:
        return 'Lead Created';
      case ActivityType.statusChanged:
        return 'Status Changed';
      case ActivityType.assigned:
        return 'Lead Assigned';
      case ActivityType.reassigned:
        return 'Lead Reassigned';
      case ActivityType.unassigned:
        return 'Lead Unassigned';
      case ActivityType.priorityChanged:
        return 'Priority Changed';
      case ActivityType.followUpAdded:
        return 'Follow-Up Added';
      case ActivityType.followUpScheduled:
        return 'Follow-Up Scheduled';
      case ActivityType.fieldEdited:
        return 'Field Edited';
      case ActivityType.leadDeleted:
        return 'Lead Deleted';
      case ActivityType.leadRestored:
        return 'Lead Restored';
    }
  }

  String get displayDescription {
    switch (type) {
      case ActivityType.leadCreated:
        return 'Lead was created in the system';
      case ActivityType.statusChanged:
        final oldStatus = metadata['oldStatus'] as String?;
        final newStatus = metadata['newStatus'] as String?;
        if (oldStatus != null && newStatus != null) {
          return 'Changed from $oldStatus to $newStatus';
        }
        return 'Status was updated';
      case ActivityType.assigned:
        final assignedToName = metadata['assignedToName'] as String?;
        if (assignedToName != null) {
          return 'Assigned to $assignedToName';
        }
        return 'Lead was assigned';
      case ActivityType.reassigned:
        final oldAssignee = metadata['oldAssigneeName'] as String?;
        final newAssignee = metadata['newAssigneeName'] as String?;
        if (oldAssignee != null && newAssignee != null) {
          return 'Reassigned from $oldAssignee to $newAssignee';
        }
        return 'Lead was reassigned';
      case ActivityType.unassigned:
        final oldAssignee = metadata['oldAssigneeName'] as String?;
        if (oldAssignee != null) {
          return 'Unassigned from $oldAssignee';
        }
        return 'Lead was unassigned';
      case ActivityType.priorityChanged:
        final isPriority = metadata['isPriority'] as bool?;
        if (isPriority != null) {
          return isPriority ? 'Marked as priority' : 'Removed from priority';
        }
        return 'Priority was changed';
      case ActivityType.followUpAdded:
        final note = metadata['note'] as String?;
        if (note != null && note.isNotEmpty) {
          final preview = note.length > 50 ? '${note.substring(0, 50)}...' : note;
          return preview;
        }
        return 'Follow-up note was added';
      case ActivityType.followUpScheduled:
        final scheduledDate = metadata['scheduledDate'] as String?;
        if (scheduledDate != null) {
          return 'Scheduled for $scheduledDate';
        }
        return 'Follow-up was scheduled';
      case ActivityType.fieldEdited:
        final fieldName = metadata['fieldName'] as String?;
        if (fieldName != null) {
          return '$fieldName was updated';
        }
        return 'Field was edited';
      case ActivityType.leadDeleted:
        return 'Lead was deleted';
      case ActivityType.leadRestored:
        return 'Lead was restored';
    }
  }
}

