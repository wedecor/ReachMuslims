import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/expense.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../core/errors/failures.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl();
});

class ExpenseListState {
  final List<Expense> expenses;
  final bool isLoading;
  final Failure? error;
  final UserRegion? selectedRegion;
  final String? selectedPlatform;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const ExpenseListState({
    this.expenses = const [],
    this.isLoading = false,
    this.error,
    this.selectedRegion,
    this.selectedPlatform,
    this.dateFrom,
    this.dateTo,
  });

  ExpenseListState copyWith({
    List<Expense>? expenses,
    bool? isLoading,
    Failure? error,
    UserRegion? selectedRegion,
    String? selectedPlatform,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearError = false,
  }) {
    return ExpenseListState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedRegion: selectedRegion ?? this.selectedRegion,
      selectedPlatform: selectedPlatform ?? this.selectedPlatform,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }
}

class ExpenseListNotifier extends StateNotifier<ExpenseListState> {
  final ExpenseRepository _expenseRepository;

  ExpenseListNotifier(this._expenseRepository)
      : super(const ExpenseListState());

  Future<void> loadExpenses() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final expenses = await _expenseRepository.getExpenses(
        region: state.selectedRegion,
        platform: state.selectedPlatform,
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
        limit: 500, // Load more expenses since we don't have pagination yet
      );

      state = state.copyWith(
        expenses: expenses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e : FirestoreFailure(e.toString()),
      );
    }
  }

  Future<void> refresh() async {
    await loadExpenses();
  }

  void setRegionFilter(UserRegion? region) {
    state = state.copyWith(selectedRegion: region);
    loadExpenses();
  }

  void setPlatformFilter(String? platform) {
    state = state.copyWith(selectedPlatform: platform);
    loadExpenses();
  }

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(dateFrom: from, dateTo: to);
    loadExpenses();
  }

  void clearFilters() {
    state = state.copyWith(
      selectedRegion: null,
      selectedPlatform: null,
      dateFrom: null,
      dateTo: null,
    );
    loadExpenses();
  }
}

final expenseListProvider =
    StateNotifierProvider<ExpenseListNotifier, ExpenseListState>((ref) {
  final repository = ref.read(expenseRepositoryProvider);
  final notifier = ExpenseListNotifier(repository);
  // Load expenses on provider creation
  Future.microtask(() => notifier.loadExpenses());
  return notifier;
});

// Provider for creating expenses
class ExpenseCreateState {
  final bool isLoading;
  final Failure? error;
  final bool isSuccess;

  const ExpenseCreateState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  ExpenseCreateState copyWith({
    bool? isLoading,
    Failure? error,
    bool? isSuccess,
    bool clearError = false,
  }) {
    return ExpenseCreateState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ExpenseCreateNotifier extends StateNotifier<ExpenseCreateState> {
  final ExpenseRepository _expenseRepository;

  ExpenseCreateNotifier(this._expenseRepository)
      : super(const ExpenseCreateState());

  Future<bool> createExpense(Expense expense) async {
    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);

    try {
      await _expenseRepository.createExpense(expense);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e : FirestoreFailure(e.toString()),
        isSuccess: false,
      );
      return false;
    }
  }

  void reset() {
    state = const ExpenseCreateState();
  }
}

final expenseCreateProvider =
    StateNotifierProvider<ExpenseCreateNotifier, ExpenseCreateState>((ref) {
  final repository = ref.read(expenseRepositoryProvider);
  return ExpenseCreateNotifier(repository);
});

// Provider for updating expenses
class ExpenseUpdateState {
  final bool isLoading;
  final Failure? error;
  final bool isSuccess;

  const ExpenseUpdateState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  ExpenseUpdateState copyWith({
    bool? isLoading,
    Failure? error,
    bool? isSuccess,
    bool clearError = false,
  }) {
    return ExpenseUpdateState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ExpenseUpdateNotifier extends StateNotifier<ExpenseUpdateState> {
  final ExpenseRepository _expenseRepository;

  ExpenseUpdateNotifier(this._expenseRepository)
      : super(const ExpenseUpdateState());

  Future<bool> updateExpense(Expense expense) async {
    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);

    try {
      await _expenseRepository.updateExpense(expense);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e : FirestoreFailure(e.toString()),
        isSuccess: false,
      );
      return false;
    }
  }

  void reset() {
    state = const ExpenseUpdateState();
  }
}

final expenseUpdateProvider =
    StateNotifierProvider<ExpenseUpdateNotifier, ExpenseUpdateState>((ref) {
  final repository = ref.read(expenseRepositoryProvider);
  return ExpenseUpdateNotifier(repository);
});

// Provider for deleting expenses
class ExpenseDeleteState {
  final bool isLoading;
  final Failure? error;
  final bool isSuccess;

  const ExpenseDeleteState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  ExpenseDeleteState copyWith({
    bool? isLoading,
    Failure? error,
    bool? isSuccess,
    bool clearError = false,
  }) {
    return ExpenseDeleteState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ExpenseDeleteNotifier extends StateNotifier<ExpenseDeleteState> {
  final ExpenseRepository _expenseRepository;

  ExpenseDeleteNotifier(this._expenseRepository)
      : super(const ExpenseDeleteState());

  Future<bool> deleteExpense(String expenseId) async {
    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);

    try {
      await _expenseRepository.deleteExpense(expenseId);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e : FirestoreFailure(e.toString()),
        isSuccess: false,
      );
      return false;
    }
  }

  void reset() {
    state = const ExpenseDeleteState();
  }
}

final expenseDeleteProvider =
    StateNotifierProvider<ExpenseDeleteNotifier, ExpenseDeleteState>((ref) {
  final repository = ref.read(expenseRepositoryProvider);
  return ExpenseDeleteNotifier(repository);
});

