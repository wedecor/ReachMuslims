enum ScheduledFollowUpStatus {
  pending,
  completed,
  missed;

  static ScheduledFollowUpStatus fromString(String value) {
    return ScheduledFollowUpStatus.values.firstWhere(
      (status) => status.name == value.toLowerCase(),
      orElse: () => ScheduledFollowUpStatus.pending,
    );
  }
}

class ScheduledFollowUp {
  final String id;
  final String leadId;
  final DateTime scheduledAt;
  final String? note;
  final String createdBy;
  final ScheduledFollowUpStatus status;
  final DateTime createdAt;

  const ScheduledFollowUp({
    required this.id,
    required this.leadId,
    required this.scheduledAt,
    this.note,
    required this.createdBy,
    this.status = ScheduledFollowUpStatus.pending,
    required this.createdAt,
  });
}

