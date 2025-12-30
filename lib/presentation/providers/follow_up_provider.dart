import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/follow_up.dart';
import '../../domain/repositories/follow_up_repository.dart';
import '../../domain/repositories/lead_repository.dart';
import '../../data/repositories/follow_up_repository_impl.dart';
import '../../core/errors/failures.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/offline_sync_provider.dart';
import 'lead_list_provider.dart';

final followUpRepositoryProvider = Provider<FollowUpRepository>((ref) {
  return FollowUpRepositoryImpl();
});

class FollowUpListState {
  final List<FollowUp> followUps;
  final bool isLoading;
  final Failure? error;

  const FollowUpListState({
    this.followUps = const [],
    this.isLoading = true,
    this.error,
  });

  FollowUpListState copyWith({
    List<FollowUp>? followUps,
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) {
    return FollowUpListState(
      followUps: followUps ?? this.followUps,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FollowUpListNotifier extends StateNotifier<FollowUpListState> {
  final FollowUpRepository _followUpRepository;
  final String _leadId;
  StreamSubscription<List<FollowUp>>? _subscription;

  FollowUpListNotifier(this._followUpRepository, this._leadId)
      : super(const FollowUpListState()) {
    _init();
  }

  void _init() {
    _subscription = _followUpRepository.streamFollowUps(_leadId).listen(
      (followUps) {
        state = state.copyWith(followUps: followUps, isLoading: false, clearError: true);
      },
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          error: error is Failure ? error : FirestoreFailure('Failed to load follow-ups: ${error.toString()}'),
        );
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final followUpListProvider = StateNotifierProvider.family<FollowUpListNotifier, FollowUpListState, String>((ref, leadId) {
  final followUpRepository = ref.watch(followUpRepositoryProvider);
  return FollowUpListNotifier(followUpRepository, leadId);
});

class AddFollowUpState {
  final bool isLoading;
  final Failure? error;

  const AddFollowUpState({
    this.isLoading = false,
    this.error,
  });

  AddFollowUpState copyWith({
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) {
    return AddFollowUpState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AddFollowUpNotifier extends StateNotifier<AddFollowUpState> {
  final FollowUpRepository _followUpRepository;
  final LeadRepository _leadRepository;
  final Ref _ref;
  final String _leadId;

  AddFollowUpNotifier(this._followUpRepository, this._leadRepository, this._ref, this._leadId)
      : super(const AddFollowUpState());

  Future<bool> addFollowUp(String note) async {
    if (note.trim().isEmpty) {
      state = state.copyWith(
        error: const AuthFailure('Note cannot be empty'),
      );
      return false;
    }

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
        error: const AuthFailure('Inactive users cannot add follow-ups'),
      );
      return false;
    }

    // Get lead to check permissions
    final lead = await _leadRepository.getLeadById(_leadId);
    if (lead == null) {
      state = state.copyWith(
        error: const AuthFailure('Lead not found'),
      );
      return false;
    }

    // Check role-based permissions
    if (user.isSales) {
      // Sales can only add to assigned leads
      if (lead.assignedTo != user.uid) {
        state = state.copyWith(
          error: const AuthFailure('You can only add follow-ups to your assigned leads'),
        );
        return false;
      }
    } else if (user.isAdmin) {
      // Admin can add to any lead in their region
      if (user.region != null && lead.region != user.region) {
        state = state.copyWith(
          error: const AuthFailure('You can only add follow-ups to leads in your region'),
        );
        return false;
      }
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Mark write as pending if offline
      final connectivityState = _ref.read(connectivityProvider);
      if (!connectivityState.isOnline) {
        _ref.read(offlineSyncProvider.notifier).markWritePending();
      }

      await _followUpRepository.addFollowUp(_leadId, note, user.uid);
      
      // Mark as synced if online
      if (connectivityState.isOnline) {
        _ref.read(offlineSyncProvider.notifier).markWriteSynced();
      }
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e : FirestoreFailure('Failed to add follow-up: ${e.toString()}'),
      );
      return false;
    }
  }
}

final addFollowUpProvider = StateNotifierProvider.family<AddFollowUpNotifier, AddFollowUpState, String>((ref, leadId) {
  final followUpRepository = ref.watch(followUpRepositoryProvider);
  final leadRepository = ref.watch(leadRepositoryProvider);
  return AddFollowUpNotifier(followUpRepository, leadRepository, ref, leadId);
});

