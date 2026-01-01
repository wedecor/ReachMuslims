import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/firebase_constants.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore _firestore;

  UserRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<User>> getUsersByRegion(UserRegion region) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('region', isEqualTo: region.name)
          .where('active', isEqualTo: true)
          .where('status', isEqualTo: UserStatus.approved.name)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to fetch users: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return UserModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to fetch user: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<List<User>> getPendingUsers() async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('status', isEqualTo: UserStatus.pending.name)
          .orderBy('createdAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to fetch pending users: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<List<User>> getAllActiveUsers() async {
    try {
      // Proper Firestore query with composite index
      // Index required: active (ASC), status (ASC), name (ASC)
      final snapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('active', isEqualTo: true)
          .where('status', isEqualTo: UserStatus.approved.name)
          .orderBy('name', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        throw FirestoreFailure(
          'Firestore index is being created. Please wait a few minutes and try again. '
          'Index: users (active, status, name)',
        );
      }
      throw FirestoreFailure('Failed to fetch active users: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<List<User>> getAllUsers() async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where('status', isEqualTo: UserStatus.approved.name)
          .orderBy('name', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to fetch users: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> approveUser({
    required String userId,
    required UserRole role,
    required UserRegion region,
    required String approvedBy,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        'status': UserStatus.approved.name,
        'active': true,
        'role': role.name,
        'region': region.name,
        'approvedBy': approvedBy,
        'approvedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to approve user: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> rejectUser({
    required String userId,
    required String rejectedBy,
    String? rejectionReason,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': UserStatus.rejected.name,
        'active': false,
        'rejectedBy': rejectedBy,
        'rejectedAt': FieldValue.serverTimestamp(),
      };

      if (rejectionReason != null && rejectionReason.isNotEmpty) {
        updateData['rejectionReason'] = rejectionReason;
      }

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update(updateData);
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to reject user: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> updateUserRole({
    required String userId,
    required UserRole role,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        'role': role.name,
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to update user role: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> updateUserRegion({
    required String userId,
    required UserRegion region,
  }) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        'region': region.name,
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to update user region: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> deactivateUser(String userId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        'active': false,
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to deactivate user: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> activateUser(String userId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({
        'active': true,
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to activate user: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }
}

