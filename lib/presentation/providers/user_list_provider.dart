import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../core/errors/failures.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl();
});

class UserListState {
  final List<User> users;
  final bool isLoading;
  final Failure? error;

  const UserListState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  UserListState copyWith({
    List<User>? users,
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) {
    return UserListState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UserListNotifier extends StateNotifier<UserListState> {
  final UserRepository _userRepository;
  final UserRegion _region;

  UserListNotifier(this._userRepository, this._region)
      : super(const UserListState()) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final users = await _userRepository.getUsersByRegion(_region);
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e : FirestoreFailure('Failed to load users: ${e.toString()}'),
      );
    }
  }
}

final userListProvider = StateNotifierProvider.family<UserListNotifier, UserListState, UserRegion>((ref, region) {
  final userRepository = ref.watch(userRepositoryProvider);
  return UserListNotifier(userRepository, region);
});

