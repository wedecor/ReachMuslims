import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/lead_repository.dart';
import '../../domain/models/lead_edit_history.dart';
import '../../core/errors/failures.dart';
import '../providers/auth_provider.dart';
import 'lead_list_provider.dart';
import 'lead_edit_history_provider.dart';

class LeadEditState {
  final bool isLoading;
  final Failure? error;

  const LeadEditState({
    this.isLoading = false,
    this.error,
  });

  LeadEditState copyWith({
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) {
    return LeadEditState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LeadEditNotifier extends StateNotifier<LeadEditState> {
  final LeadRepository _leadRepository;
  final Ref _ref;
  final String _leadId;

  LeadEditNotifier(this._leadRepository, this._ref, this._leadId)
      : super(const LeadEditState());

  Future<bool> updateLead({
    required String name,
    required String phone,
    String? location,
  }) async {
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
          error: const AuthFailure('Inactive users cannot edit leads'),
        );
        return false;
      }

      state = state.copyWith(isLoading: true, clearError: true);

      // Get current lead to detect changes
      final currentLead = await _leadRepository.getLeadById(_leadId);
      if (currentLead == null) {
        state = state.copyWith(
          isLoading: false,
          error: const FirestoreFailure('Lead not found'),
        );
        return false;
      }

      // Detect changes for audit trail
      final trimmedName = name.trim();
      final trimmedPhone = phone.trim();
      final trimmedLocation = location?.trim();
      
      final changes = <String, FieldChange>{};
      
      if (currentLead.name != trimmedName) {
        changes['name'] = FieldChange(oldValue: currentLead.name, newValue: trimmedName);
      }
      if (currentLead.phone != trimmedPhone) {
        changes['phone'] = FieldChange(oldValue: currentLead.phone, newValue: trimmedPhone);
      }
      
      // Handle location: compare old value with new (null/empty treated as empty)
      final oldLocation = currentLead.location ?? '';
      final newLocation = trimmedLocation ?? '';
      if (oldLocation != newLocation) {
        changes['location'] = FieldChange(
          oldValue: oldLocation.isEmpty ? null : oldLocation,
          newValue: newLocation.isEmpty ? null : newLocation,
        );
      }

      // Update the lead
      await _leadRepository.updateLead(
        leadId: _leadId,
        name: trimmedName,
        phone: trimmedPhone,
        location: trimmedLocation,
        userId: user.uid,
        isAdmin: user.isAdmin,
      );

      // Log edit history if there are actual changes
      if (changes.isNotEmpty) {
        try {
          await _leadRepository.logEditHistory(
            leadId: _leadId,
            editedBy: user.uid,
            editedByName: user.name,
            editedByEmail: user.email,
            changes: changes,
          );
          
          // Refresh edit history to show the new entry
          // Note: This provider may not exist yet if user hasn't viewed edit history
          try {
            _ref.read(leadEditHistoryProvider(_leadId).notifier).refresh();
          } catch (e) {
            // Provider may not be initialized yet, that's okay
            debugPrint('Edit history provider not initialized: $e');
          }
        } catch (e) {
          // Log error but don't fail the edit operation
          // Edit history is important but not critical
          debugPrint('Failed to log edit history: $e');
        }
      }

      // Refresh lead list to reflect changes
      _ref.read(leadListProvider.notifier).refresh();

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e : FirestoreFailure('Failed to update lead: ${e.toString()}'),
      );
      return false;
    }
  }
}

final leadEditProvider = StateNotifierProvider.family<LeadEditNotifier, LeadEditState, String>(
  (ref, leadId) {
    final leadRepository = ref.watch(leadRepositoryProvider);
    return LeadEditNotifier(leadRepository, ref, leadId);
  },
);

