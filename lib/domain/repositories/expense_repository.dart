import '../models/expense.dart';
import '../models/user.dart';

abstract class ExpenseRepository {
  /// Get all expenses with optional filters
  Future<List<Expense>> getExpenses({
    UserRegion? region,
    String? platform,
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 100,
  });

  /// Get expense by ID
  Future<Expense?> getExpenseById(String expenseId);

  /// Create a new expense
  Future<Expense> createExpense(Expense expense);

  /// Update an existing expense
  Future<void> updateExpense(Expense expense);

  /// Delete an expense
  Future<void> deleteExpense(String expenseId);

  /// Stream expenses for real-time updates
  Stream<List<Expense>> streamExpenses({
    UserRegion? region,
    String? platform,
    DateTime? dateFrom,
    DateTime? dateTo,
  });
}

