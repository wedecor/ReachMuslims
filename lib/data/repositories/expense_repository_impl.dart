import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/firebase_constants.dart';
import '../models/expense_model.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final FirebaseFirestore _firestore;

  ExpenseRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Expense>> getExpenses({
    UserRegion? region,
    String? platform,
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection(FirebaseConstants.expensesCollection)
          .orderBy('date', descending: true);

      // Region filter
      if (region != null) {
        query = query.where('region', isEqualTo: region.name);
      }

      // Platform filter
      if (platform != null && platform.isNotEmpty) {
        query = query.where('platform', isEqualTo: platform);
      }

      // Date range filters
      if (dateFrom != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateFrom));
      }

      if (dateTo != null) {
        // Add one day to include the end date fully
        final endDate = DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59, 59);
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Apply limit
      query = query.limit(limit);

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to fetch expenses: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Expense?> getExpenseById(String expenseId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.expensesCollection)
          .doc(expenseId)
          .get();

      if (!doc.exists) return null;

      return ExpenseModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to fetch expense: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Expense> createExpense(Expense expense) async {
    try {
      // Create document reference with auto-generated ID
      final docRef = _firestore
          .collection(FirebaseConstants.expensesCollection)
          .doc();

      final expenseModel = ExpenseModel(
        id: docRef.id, // Use Firestore auto-generated ID
        platform: expense.platform,
        amount: expense.amount,
        currency: expense.currency,
        date: expense.date,
        description: expense.description,
        category: expense.category,
        createdBy: expense.createdBy,
        region: expense.region,
        createdAt: expense.createdAt,
        updatedAt: expense.updatedAt,
      );

      await docRef.set(expenseModel.toFirestore());

      final createdDoc = await docRef.get();
      return ExpenseModel.fromFirestore(createdDoc);
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to create expense: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    try {
      final expenseModel = ExpenseModel(
        id: expense.id,
        platform: expense.platform,
        amount: expense.amount,
        currency: expense.currency,
        date: expense.date,
        description: expense.description,
        category: expense.category,
        createdBy: expense.createdBy,
        region: expense.region,
        createdAt: expense.createdAt,
        updatedAt: expense.updatedAt,
      );

      await _firestore
          .collection(FirebaseConstants.expensesCollection)
          .doc(expense.id)
          .update(expenseModel.toFirestore());
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to update expense: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.expensesCollection)
          .doc(expenseId)
          .delete();
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to delete expense: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Stream<List<Expense>> streamExpenses({
    UserRegion? region,
    String? platform,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) {
    try {
      Query query = _firestore
          .collection(FirebaseConstants.expensesCollection)
          .orderBy('date', descending: true);

      // Region filter
      if (region != null) {
        query = query.where('region', isEqualTo: region.name);
      }

      // Platform filter
      if (platform != null && platform.isNotEmpty) {
        query = query.where('platform', isEqualTo: platform);
      }

      // Date range filters
      if (dateFrom != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dateFrom));
      }

      if (dateTo != null) {
        final endDate = DateTime(dateTo.year, dateTo.month, dateTo.day, 23, 59, 59);
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList();
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to stream expenses: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }
}

