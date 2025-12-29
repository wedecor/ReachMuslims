import 'user.dart';

enum LeadStatus {
  newLead,
  inTalk,
  notInterested,
  converted;

  static LeadStatus fromString(String value) {
    return LeadStatus.values.firstWhere(
      (status) => status.name == value.toLowerCase().replaceAll(' ', ''),
      orElse: () => LeadStatus.newLead,
    );
  }

  String get displayName {
    switch (this) {
      case LeadStatus.newLead:
        return 'New';
      case LeadStatus.inTalk:
        return 'In Talk';
      case LeadStatus.notInterested:
        return 'Not Interested';
      case LeadStatus.converted:
        return 'Converted';
    }
  }
}

class Lead {
  final String id;
  final String name;
  final String phone;
  final String? location;
  final UserRegion region;
  final LeadStatus status;
  final String? assignedTo; // User UID
  final String? assignedToName; // User name for display
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPriority; // Priority star indicator
  final DateTime? lastContactedAt; // Last contact timestamp
  final bool isDeleted; // Soft delete flag

  const Lead({
    required this.id,
    required this.name,
    required this.phone,
    this.location,
    required this.region,
    required this.status,
    this.assignedTo,
    this.assignedToName,
    required this.createdAt,
    required this.updatedAt,
    this.isPriority = false,
    this.lastContactedAt,
    this.isDeleted = false,
  });
}

