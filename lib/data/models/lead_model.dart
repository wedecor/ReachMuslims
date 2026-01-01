import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/lead.dart';
import '../../domain/models/user.dart' as domain;

class LeadModel extends Lead {
  const LeadModel({
    required super.id,
    required super.name,
    required super.phone,
    super.location,
    required super.region,
    required super.status,
    super.assignedTo,
    super.assignedToName,
    required super.createdAt,
    required super.updatedAt,
    super.isPriority,
    super.lastContactedAt,
    super.isDeleted,
    super.source,
  });

  factory LeadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeadModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      location: data['location'] as String?,
      region: domain.UserRegion.fromString(data['region'] as String? ?? 'india'),
      status: LeadStatus.fromString(data['status'] as String? ?? 'newLead'),
      assignedTo: data['assignedTo'] as String?,
      assignedToName: data['assignedToName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPriority: data['isPriority'] as bool? ?? false,
      lastContactedAt: (data['lastContactedAt'] as Timestamp?)?.toDate(),
      isDeleted: data['isDeleted'] as bool? ?? false,
      source: LeadSource.fromString(data['source'] as String? ?? 'other'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      if (location != null) 'location': location,
      'region': region.name,
      'status': status.name,
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (assignedToName != null) 'assignedToName': assignedToName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPriority': isPriority,
      if (lastContactedAt != null) 'lastContactedAt': Timestamp.fromDate(lastContactedAt!),
      'isDeleted': isDeleted,
      'source': source.name,
    };
  }
}

