import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/scheduled_followup.dart';
import '../../domain/repositories/scheduled_followup_repository.dart';
import '../../data/repositories/scheduled_followup_repository_impl.dart';
import '../../core/errors/failures.dart';
import '../providers/connectivity_provider.dart';
import '../providers/offline_sync_provider.dart';

final scheduledFollowUpRepositoryProvider = Provider<ScheduledFollowUpRepository>((ref) {
  return ScheduledFollowUpRepositoryImpl();
});

class ScheduledFollowUpListState {
  final List<ScheduledFollowUp> scheduledFollowUps;
  final bool isLoading;
  final Failure? error;

  const ScheduledFollowUpListState({
    this.scheduledFollowUps = const [],
    this.isLoading = false,
    this.error,
  });

  ScheduledFollowUpListState copyWith({
    List<ScheduledFollowUp>? scheduledFollowUps,
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) {
    return ScheduledFollowUpListState(
      scheduledFollowUps: scheduledFollowUps ?? this.scheduledFollowUps,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ScheduledFollowUpListNotifier extends StateNotifier<ScheduledFollowUpListState> {
  final ScheduledFollowUpRepository _repository;
  final String _leadId;
  final Ref _ref;

  ScheduledFollowUpListNotifier(this._repository, this._leadId, this._ref)
      : super(const ScheduledFollowUpListState()) {
    loadScheduledFollowUps();
  }

  Future<void> loadScheduledFollowUps() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final followUps = await _repository.getScheduledFollowUpsForLead(_leadId);
      state = state.copyWith(
        scheduledFollowUps: followUps,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e : FirestoreFailure('Failed to load scheduled follow-ups: ${e.toString()}'),
      );
    }
  }

  Future<bool> createScheduledFollowUp({
    required DateTime scheduledAt,
    String? note,
    required String createdBy,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Mark write as pending if offline
      final connectivityState = _ref.read(connectivityProvider);
      if (!connectivityState.isOnline) {
        _ref.read(offlineSyncProvider.notifier).markWritePending();
      }

      await _repository.createScheduledFollowUp(
        leadId: _leadId,
        scheduledAt: scheduledAt,
        note: note,
        createdBy: createdBy,
      );
      
      // Mark as synced if online
      if (connectivityState.isOnline) {
        _ref.read(offlineSyncProvider.notifier).markWriteSynced();
      }
      
      await loadScheduledFollowUps();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e : FirestoreFailure('Failed to create scheduled follow-up: ${e.toString()}'),
      );
      return false;
    }
  }

  Future<bool> markAsCompleted(String scheduledFollowUpId) async {
    try {
      await _repository.markAsCompleted(scheduledFollowUpId);
      await loadScheduledFollowUps();
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e is Failure ? e : FirestoreFailure('Failed to mark as completed: ${e.toString()}'),
      );
      return false;
    }
  }

  Future<bool> markAsMissed(String scheduledFollowUpId) async {
    try {
      await _repository.markAsMissed(scheduledFollowUpId);
      await loadScheduledFollowUps();
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e is Failure ? e : FirestoreFailure('Failed to mark as missed: ${e.toString()}'),
      );
      return false;
    }
  }

  Future<bool> deleteScheduledFollowUp(String scheduledFollowUpId) async {
    try {
      await _repository.deleteScheduledFollowUp(scheduledFollowUpId);
      await loadScheduledFollowUps();
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e is Failure ? e : FirestoreFailure('Failed to delete scheduled follow-up: ${e.toString()}'),
      );
      return false;
    }
  }
}

final scheduledFollowUpListProvider = StateNotifierProvider.family<
    ScheduledFollowUpListNotifier, ScheduledFollowUpListState, String>((ref, leadId) {
  final repository = ref.watch(scheduledFollowUpRepositoryProvider);
  return ScheduledFollowUpListNotifier(repository, leadId, ref);
});

// Provider for user's pending tasks
class UserTasksState {
  final List<ScheduledFollowUp> pendingTasks;
  final bool isLoading;
  final Failure? error;

  const UserTasksState({
    this.pendingTasks = const [],
    this.isLoading = false,
    this.error,
  });

  UserTasksState copyWith({
    List<ScheduledFollowUp>? pendingTasks,
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) {
    return UserTasksState(
      pendingTasks: pendingTasks ?? this.pendingTasks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UserTasksNotifier extends StateNotifier<UserTasksState> {
  final ScheduledFollowUpRepository _repository;
  final String _userId;

  UserTasksNotifier(this._repository, this._userId) : super(const UserTasksState()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tasks = await _repository.getPendingFollowUpsForUser(_userId);
      state = state.copyWith(
        pendingTasks: tasks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e : FirestoreFailure('Failed to load tasks: ${e.toString()}'),
      );
    }
  }

  Future<void> refresh() async {
    await loadTasks();
  }
}

final userTasksProvider = StateNotifierProvider.family<UserTasksNotifier, UserTasksState, String>((ref, userId) {
  final repository = ref.watch(scheduledFollowUpRepositoryProvider);
  return UserTasksNotifier(repository, userId);
});

