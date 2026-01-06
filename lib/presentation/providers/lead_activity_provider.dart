import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead_activity.dart';
import '../../domain/repositories/lead_activity_repository.dart';
import '../../core/errors/failures.dart';
import '../../data/repositories/lead_activity_repository_impl.dart';

/// Repository provider
final leadActivityRepositoryProvider =
    Provider<LeadActivityRepository>((ref) {
  return LeadActivityRepositoryImpl();
});

/// Activity list state for a specific lead
class LeadActivityListState {
  final List<LeadActivity> activities;
  final bool isLoading;
  final Failure? error;

  const LeadActivityListState({
    this.activities = const [],
    this.isLoading = false,
    this.error,
  });

  LeadActivityListState copyWith({
    List<LeadActivity>? activities,
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) {
    return LeadActivityListState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Activity list notifier for a specific lead
class LeadActivityListNotifier extends StateNotifier<LeadActivityListState> {
  final LeadActivityRepository _repository;
  final String _leadId;

  LeadActivityListNotifier(this._repository, this._leadId)
      : super(const LeadActivityListState()) {
    loadActivities();
    // Listen to real-time updates
    _repository.streamActivities(_leadId).listen(
      (activities) {
        if (mounted) {
          state = state.copyWith(
            activities: activities,
            isLoading: false,
            clearError: true,
          );
        }
      },
      onError: (error) {
        if (mounted) {
          state = state.copyWith(
            isLoading: false,
            error: error is Failure
                ? error
                : FirestoreFailure('Failed to stream activities: ${error.toString()}'),
          );
        }
      },
    );
  }

  Future<void> loadActivities() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final activities = await _repository.getActivities(_leadId);
      state = state.copyWith(
        activities: activities,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure
            ? e
            : FirestoreFailure('Failed to load activities: ${e.toString()}'),
      );
    }
  }

  Future<void> refresh() async {
    await loadActivities();
  }
}

/// Provider for activity list by lead ID
final leadActivityListProvider =
    StateNotifierProvider.family<LeadActivityListNotifier, LeadActivityListState, String>(
  (ref, leadId) {
    final repository = ref.watch(leadActivityRepositoryProvider);
    return LeadActivityListNotifier(repository, leadId);
  },
);

/// Provider for creating activities (not stateful, just utility)
final leadActivityCreateProvider =
    Provider<LeadActivityRepository>((ref) {
  return ref.watch(leadActivityRepositoryProvider);
});

