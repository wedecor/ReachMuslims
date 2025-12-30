import '../models/user.dart';

abstract class UserRepository {
  Future<List<User>> getUsersByRegion(UserRegion region);
  Future<List<User>> getAllActiveUsers();
  Future<User?> getUserById(String userId);
  Future<List<User>> getPendingUsers();
  Future<List<User>> getAllUsers();
  Future<void> approveUser({
    required String userId,
    required UserRole role,
    required UserRegion region,
    required String approvedBy,
  });
  Future<void> rejectUser({
    required String userId,
    required String rejectedBy,
    String? rejectionReason,
  });
  Future<void> updateUserRole({
    required String userId,
    required UserRole role,
  });
  Future<void> updateUserRegion({
    required String userId,
    required UserRegion region,
  });
  Future<void> deactivateUser(String userId);
  Future<void> activateUser(String userId);
}

