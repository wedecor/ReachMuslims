import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../core/errors/failures.dart';

final userManagementRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl();
});

class UserManagementState {
  final List<User> users;
  final bool isLoading;
  final Failure? error;

  const UserManagementState({
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  UserManagementState copyWith({
    List<User>? users,
    bool? isLoading,
    Failure? error,
    bool clearError = false,
  }) {
    return UserManagementState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final UserRepository _userRepository;

  UserManagementNotifier(this._userRepository) : super(const UserManagementState()) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final users = await _userRepository.getAllUsers();
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is Failure ? e : FirestoreFailure('Failed to load users: ${e.toString()}'),
      );
    }
  }

  Future<void> refresh() async {
    await loadUsers();
  }

  Future<bool> updateUserRole(String userId, UserRole role) async {
    try {
      await _userRepository.updateUserRole(userId: userId, role: role);
      await loadUsers(); // Refresh list
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e is Failure ? e : FirestoreFailure('Failed to update role: ${e.toString()}'),
      );
      return false;
    }
  }

  Future<bool> updateUserRegion(String userId, UserRegion region) async {
    try {
      await _userRepository.updateUserRegion(userId: userId, region: region);
      await loadUsers(); // Refresh list
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e is Failure ? e : FirestoreFailure('Failed to update region: ${e.toString()}'),
      );
      return false;
    }
  }

  Future<bool> deactivateUser(String userId) async {
    try {
      await _userRepository.deactivateUser(userId);
      await loadUsers(); // Refresh list
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e is Failure ? e : FirestoreFailure('Failed to deactivate user: ${e.toString()}'),
      );
      return false;
    }
  }

  Future<bool> activateUser(String userId) async {
    try {
      await _userRepository.activateUser(userId);
      await loadUsers(); // Refresh list
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e is Failure ? e : FirestoreFailure('Failed to activate user: ${e.toString()}'),
      );
      return false;
    }
  }
}

final userManagementProvider = StateNotifierProvider<UserManagementNotifier, UserManagementState>((ref) {
  final userRepository = ref.watch(userManagementRepositoryProvider);
  return UserManagementNotifier(userRepository);
});

