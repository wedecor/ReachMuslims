import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/lead_repository.dart';
import '../../core/errors/failures.dart';
import '../providers/auth_provider.dart';
import 'lead_list_provider.dart';

class LeadDeleteState {
  final bool isLoading;
  final Failure? error;

  const LeadDeleteState({
    this.isLoading = false,
    this.error,
  });

  LeadDeleteState copyWith({
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) {
    return LeadDeleteState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LeadDeleteNotifier extends StateNotifier<LeadDeleteState> {
  final LeadRepository _leadRepository;
  final Ref _ref;
  final String _leadId;

  LeadDeleteNotifier(this._leadRepository, this._ref, this._leadId)
      : super(const LeadDeleteState());

  Future<bool> deleteLead() async {
    try {
      final authState = _ref.read(authProvider);
      if (!authState.isAuthenticated || authState.user == null) {
        state = state.copyWith(
          error: const AuthFailure('User not authenticated'),
        );
        return false;
      }

      final user = authState.user!;
      if (!user.active) {
        state = state.copyWith(
          error: const AuthFailure('Inactive users cannot delete leads'),
        );
        return false;
      }

      // Permission check: Only Admin can delete
      if (!user.isAdmin) {
        state = state.copyWith(
          error: const AuthFailure('Only admins can delete leads'),
        );
        return false;
      }

      state = state.copyWith(isLoading: true, clearError: true);

      await _leadRepository.softDeleteLead(
        leadId: _leadId,
        userId: user.uid,
        isAdmin: user.isAdmin,
      );

      // Refresh lead list to reflect deletion
      _ref.read(leadListProvider.notifier).refresh();

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e : FirestoreFailure('Failed to delete lead: ${e.toString()}'),
      );
      return false;
    }
  }
}

final leadDeleteProvider = StateNotifierProvider.family<LeadDeleteNotifier, LeadDeleteState, String>(
  (ref, leadId) {
    final leadRepository = ref.watch(leadRepositoryProvider);
    return LeadDeleteNotifier(leadRepository, ref, leadId);
  },
);

