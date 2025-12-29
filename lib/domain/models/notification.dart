enum NotificationType {
  leadAssigned,
  leadReassigned,
  leadStatusChanged,
  followUpAdded;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.name.toLowerCase() == value.toLowerCase(),
      orElse: () => NotificationType.leadAssigned,
    );
  }
}

class Notification {
  final String id;
  final String userId;
  final String leadId;
  final NotificationType type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;

  const Notification({
    required this.id,
    required this.userId,
    required this.leadId,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });
}

