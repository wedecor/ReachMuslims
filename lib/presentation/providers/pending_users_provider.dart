import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../core/errors/failures.dart';

final pendingUsersRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl();
});

class PendingUsersState {
  final List<User> users;
  final bool isLoading;
  final Failure? error;

  const PendingUsersState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  PendingUsersState copyWith({
    List<User>? users,
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) {
    return PendingUsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PendingUsersNotifier extends StateNotifier<PendingUsersState> {
  final UserRepository _userRepository;

  PendingUsersNotifier(this._userRepository) : super(const PendingUsersState()) {
    loadPendingUsers();
  }

  Future<void> loadPendingUsers() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final users = await _userRepository.getPendingUsers();
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e : FirestoreFailure('Failed to load pending users: ${e.toString()}'),
      );
    }
  }

  Future<void> refresh() async {
    await loadPendingUsers();
  }
}

final pendingUsersProvider = StateNotifierProvider<PendingUsersNotifier, PendingUsersState>((ref) {
  final userRepository = ref.watch(pendingUsersRepositoryProvider);
  return PendingUsersNotifier(userRepository);
});

