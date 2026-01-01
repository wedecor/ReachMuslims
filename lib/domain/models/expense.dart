import 'user.dart';

class Expense {
  final String id;
  final String platform; // Customizable platform name
  final double amount;
  final String currency; // USD or INR based on region
  final DateTime date;
  final String? description;
  final String? category; // Optional category
  final String createdBy; // User UID
  final UserRegion region;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Expense({
    required this.id,
    required this.platform,
    required this.amount,
    required this.currency,
    required this.date,
    this.description,
    this.category,
    required this.createdBy,
    required this.region,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get currency symbol
  String get currencySymbol {
    switch (currency.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'INR':
        return '₹';
      default:
        return currency;
    }
  }

  /// Get formatted amount with currency
  String get formattedAmount {
    return '$currencySymbol${amount.toStringAsFixed(2)}';
  }
}

