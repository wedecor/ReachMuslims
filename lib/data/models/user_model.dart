import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/user.dart';

class UserModel extends User {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
    super.phone,
    super.role,
    super.region,
    required super.active,
    super.status = UserStatus.approved,
    super.approvedBy,
    super.approvedAt,
    super.rejectedBy,
    super.rejectedAt,
    super.rejectionReason,
    super.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      role: data['role'] != null
          ? UserRole.fromString(data['role'] as String)
          : null,
      region: data['region'] != null
          ? UserRegion.fromString(data['region'] as String)
          : null,
      active: data['active'] as bool? ?? false,
      status: UserStatus.fromString(data['status'] as String? ?? 'approved'),
      approvedBy: data['approvedBy'] as String?,
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      rejectedBy: data['rejectedBy'] as String?,
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      if (role != null) 'role': role!.name,
      if (region != null) 'region': region!.name,
      'active': active,
      'status': status.name,
      if (approvedBy != null) 'approvedBy': approvedBy,
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      if (rejectedBy != null) 'rejectedBy': rejectedBy,
      if (rejectedAt != null) 'rejectedAt': Timestamp.fromDate(rejectedAt!),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}

