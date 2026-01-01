import 'user.dart';

enum LeadSource {
  website,
  personal,
  facebook,
  instagram,
  linkedin,
  whatsapp,
  telegram,
  matrimonySites,
  familyReferral,
  friendReferral,
  communityEvents,
  email,
  phoneCall,
  socialMedia,
  other;

  static LeadSource fromString(String value) {
    final normalizedValue = value.toLowerCase().replaceAll(' ', '');
    
    // Handle backward compatibility for old "referral" value
    if (normalizedValue == 'referral') {
      return LeadSource.familyReferral; // Map old referral to familyReferral
    }
    
    return LeadSource.values.firstWhere(
      (source) => source.name.toLowerCase() == normalizedValue,
      orElse: () => LeadSource.other,
    );
  }

  String get displayName {
    switch (this) {
      case LeadSource.website:
        return 'Website';
      case LeadSource.personal:
        return 'Personal';
      case LeadSource.facebook:
        return 'Facebook';
      case LeadSource.instagram:
        return 'Instagram';
      case LeadSource.linkedin:
        return 'LinkedIn';
      case LeadSource.whatsapp:
        return 'WhatsApp';
      case LeadSource.telegram:
        return 'Telegram';
      case LeadSource.matrimonySites:
        return 'Matrimony Sites';
      case LeadSource.familyReferral:
        return 'Family Referral';
      case LeadSource.friendReferral:
        return 'Friend Referral';
      case LeadSource.communityEvents:
        return 'Community Events';
      case LeadSource.email:
        return 'Email';
      case LeadSource.phoneCall:
        return 'Phone Call';
      case LeadSource.socialMedia:
        return 'Social Media';
      case LeadSource.other:
        return 'Other';
    }
  }
}

enum LeadStatus {
  newLead,
  followUp,
  inTalk,
  notInterested,
  converted;

  static LeadStatus fromString(String value) {
    final normalizedValue = value.toLowerCase().replaceAll(' ', '');
    return LeadStatus.values.firstWhere(
      (status) => status.name.toLowerCase() == normalizedValue,
      orElse: () => LeadStatus.newLead,
    );
  }

  String get displayName {
    switch (this) {
      case LeadStatus.newLead:
        return 'New';
      case LeadStatus.followUp:
        return 'Follow Up';
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
  final LeadSource source; // Lead source (read-only after creation)

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
    this.source = LeadSource.other,
  });
}

