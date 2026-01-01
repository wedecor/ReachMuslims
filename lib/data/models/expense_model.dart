import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/user.dart' as domain;

class ExpenseModel extends Expense {
  const ExpenseModel({
    required super.id,
    required super.platform,
    required super.amount,
    required super.currency,
    required super.date,
    super.description,
    super.category,
    required super.createdBy,
    required super.region,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      platform: data['platform'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency'] as String? ?? 'USD',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: data['description'] as String?,
      category: data['category'] as String?,
      createdBy: data['createdBy'] as String? ?? '',
      region: domain.UserRegion.fromString(data['region'] as String? ?? 'india'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'platform': platform,
      'amount': amount,
      'currency': currency,
      'date': Timestamp.fromDate(date),
      if (description != null && description!.isNotEmpty) 'description': description,
      if (category != null && category!.isNotEmpty) 'category': category,
      'createdBy': createdBy,
      'region': region.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

