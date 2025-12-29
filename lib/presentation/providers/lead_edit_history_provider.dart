import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/lead_repository.dart';
import '../../domain/models/lead_edit_history.dart';
import '../../core/errors/failures.dart';
import 'lead_list_provider.dart';

class LeadEditHistoryState {
  final List<LeadEditHistory> history;
  final bool isLoading;
  final Failure? error;

  const LeadEditHistoryState({
    this.history = const [],
    this.isLoading = false,
    this.error,
  });

  LeadEditHistoryState copyWith({
    List<LeadEditHistory>? history,
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) {
    return LeadEditHistoryState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LeadEditHistoryNotifier extends StateNotifier<LeadEditHistoryState> {
  final LeadRepository _leadRepository;
  final String _leadId;

  LeadEditHistoryNotifier(this._leadRepository, this._leadId)
      : super(const LeadEditHistoryState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final history = await _leadRepository.getEditHistory(_leadId);

      state = state.copyWith(
        history: history,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e : FirestoreFailure('Failed to load edit history: ${e.toString()}'),
      );
    }
  }

  Future<void> refresh() async {
    await loadHistory();
  }
}

final leadEditHistoryProvider =
    StateNotifierProvider.family<LeadEditHistoryNotifier, LeadEditHistoryState, String>(
  (ref, leadId) {
    final leadRepository = ref.watch(leadRepositoryProvider);
    return LeadEditHistoryNotifier(leadRepository, leadId);
  },
);

