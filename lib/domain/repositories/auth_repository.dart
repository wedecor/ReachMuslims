import '../models/user.dart';

abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<User> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String region,
  });
  Future<void> requestAccess({
    required String name,
    required String email,
    required String password,
    String? phone,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> logout();
  Future<User?> getCurrentUser();
  Stream<User?> authStateChanges();
}

