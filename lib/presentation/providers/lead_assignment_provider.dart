import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/lead_repository.dart';
import '../../core/errors/failures.dart';
import 'lead_list_provider.dart';
import 'auth_provider.dart';

class LeadAssignmentState {
  final bool isLoading;
  final Failure? error;

  const LeadAssignmentState({
    this.isLoading = false,
    this.error,
  });

  LeadAssignmentState copyWith({
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) {
    return LeadAssignmentState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LeadAssignmentNotifier extends StateNotifier<LeadAssignmentState> {
  final LeadRepository _leadRepository;
  final Ref _ref;
  final String _leadId;

  LeadAssignmentNotifier(this._leadRepository, this._ref, this._leadId)
      : super(const LeadAssignmentState());

  Future<bool> assignLead(String? assignedTo, String? assignedToName) async {
    // Check business rules
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
        error: const AuthFailure('Inactive users cannot assign leads'),
      );
      return false;
    }

    // Only admin can assign leads
    if (!user.isAdmin) {
      state = state.copyWith(
        error: const AuthFailure('Only admins can assign leads'),
      );
      return false;
    }

    // Get lead to check region
    final lead = await _leadRepository.getLeadById(_leadId);
    if (lead == null) {
      state = state.copyWith(
        error: const AuthFailure('Lead not found'),
      );
      return false;
    }

    // If assigning to a user, verify they're in the same region
    // Note: Region validation will be handled by Cloud Functions
    // We trust the assignment here and let backend validate

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _leadRepository.assignLead(_leadId, assignedTo, assignedToName);
      
      // Refresh lead list to reflect changes
      _ref.read(leadListProvider.notifier).refresh();
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e : FirestoreFailure('Failed to assign lead: ${e.toString()}'),
      );
      return false;
    }
  }
}

final leadAssignmentProvider = StateNotifierProvider.family<LeadAssignmentNotifier, LeadAssignmentState, String>((ref, leadId) {
  final leadRepository = ref.watch(leadRepositoryProvider);
  return LeadAssignmentNotifier(leadRepository, ref, leadId);
});

