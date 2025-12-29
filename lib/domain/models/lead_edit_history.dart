/// Represents a single edit history entry for a lead
class LeadEditHistory {
  final String id;
  final String leadId;
  final String editedBy; // User UID
  final String? editedByName; // User name for display
  final String? editedByEmail; // User email for display
  final DateTime editedAt;
  final Map<String, FieldChange> changes; // field name -> {old, new}

  const LeadEditHistory({
    required this.id,
    required this.leadId,
    required this.editedBy,
    this.editedByName,
    this.editedByEmail,
    required this.editedAt,
    required this.changes,
  });
}

/// Represents a change to a single field
class FieldChange {
  final String? oldValue;
  final String? newValue;

  const FieldChange({
    required this.oldValue,
    required this.newValue,
  });
}

