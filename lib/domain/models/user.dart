enum UserRole {
  admin,
  sales;

  static UserRole fromString(String value) {
    final normalizedValue = value.toLowerCase();
    return UserRole.values.firstWhere(
      (role) => role.name.toLowerCase() == normalizedValue,
      orElse: () => UserRole.sales,
    );
  }
}

enum UserRegion {
  india,
  usa;

  static UserRegion fromString(String value) {
    final normalizedValue = value.toLowerCase();
    return UserRegion.values.firstWhere(
      (region) => region.name.toLowerCase() == normalizedValue,
      orElse: () => UserRegion.india,
    );
  }
}

enum UserStatus {
  pending,
  approved,
  rejected;

  static UserStatus fromString(String value) {
    final normalizedValue = value.toLowerCase();
    return UserStatus.values.firstWhere(
      (status) => status.name.toLowerCase() == normalizedValue,
      orElse: () => UserStatus.pending,
    );
  }
}

class User {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final UserRole? role;
  final UserRegion? region;
  final bool active;
  final UserStatus status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? createdAt;

  const User({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    this.region,
    required this.active,
    this.status = UserStatus.approved,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.rejectionReason,
    this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin && status == UserStatus.approved;
  bool get isSales => role == UserRole.sales && status == UserStatus.approved;
  bool get isApproved => status == UserStatus.approved;
  bool get isPending => status == UserStatus.pending;
  bool get isRejected => status == UserStatus.rejected;
}

