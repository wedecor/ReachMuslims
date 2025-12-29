class FollowUp {
  final String id;
  final String note;
  final String createdBy; // User UID
  final String? createdByName; // User name for display
  final DateTime createdAt;
  final String? type; // e.g., "whatsapp"
  final String? region; // e.g., "india", "usa"
  final String? messagePreview; // First 50 chars of message

  const FollowUp({
    required this.id,
    required this.note,
    required this.createdBy,
    this.createdByName,
    required this.createdAt,
    this.type,
    this.region,
    this.messagePreview,
  });
}

