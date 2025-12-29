import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/user.dart' as domain;
import '../../domain/repositories/auth_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/firebase_constants.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<domain.User> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw const AuthFailure('Login failed: No user returned');
      }

      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw const AuthFailure('User document not found');
      }

      final user = UserModel.fromFirestore(userDoc);

      if (!user.isApproved) {
        await _auth.signOut();
        throw const AuthFailure('Account pending approval. Please wait for admin activation.');
      }

      if (!user.active) {
        await _auth.signOut();
        throw const AuthFailure('User account is inactive');
      }

      // Force token refresh to get custom claims (if set by Cloud Functions)
      try {
        await credential.user!.getIdToken(true);
      } catch (e) {
        // Ignore token refresh errors - custom claims might not be set yet
        // Rules will fall back to Firestore document reads
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure('Login failed: ${e.message ?? 'Unknown error'}');
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to fetch user: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw AuthFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<domain.User> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String region,
  }) async {
    try {
      // 1) Create Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw const AuthFailure('Registration failed: No user returned');
      }

      final uid = credential.user!.uid;

      // 2) Create Firestore user document
      // Convert region to lowercase to match enum (india/usa)
      final regionLower = region.toLowerCase();
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .set({
        'uid': uid,
        'name': name,
        'email': email,
        'role': role.toLowerCase(), // Store as lowercase (admin/sales)
        'region': regionLower == 'india' || regionLower == 'usa' 
            ? regionLower 
            : 'india', // Default to india if invalid
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3) Fetch and return the created user
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw const AuthFailure('User document creation failed');
      }

      return UserModel.fromFirestore(userDoc);
    } on FirebaseAuthException catch (e) {
      // If Auth creation succeeded but Firestore failed, clean up Auth user
      if (_auth.currentUser != null) {
        try {
          await _auth.currentUser!.delete();
        } catch (_) {
          // Ignore cleanup errors
        }
      }
      throw AuthFailure('Registration failed: ${e.message ?? 'Unknown error'}');
    } on FirebaseException catch (e) {
      // If Auth creation succeeded but Firestore failed, clean up Auth user
      if (_auth.currentUser != null) {
        try {
          await _auth.currentUser!.delete();
        } catch (_) {
          // Ignore cleanup errors
        }
      }
      throw FirestoreFailure('Failed to create user profile: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      // If Auth creation succeeded but something else failed, clean up Auth user
      if (_auth.currentUser != null) {
        try {
          await _auth.currentUser!.delete();
        } catch (_) {
          // Ignore cleanup errors
        }
      }
      if (e is Failure) rethrow;
      throw AuthFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> requestAccess({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      // 1) Create Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw const AuthFailure('Access request failed: No user returned');
      }

      final uid = credential.user!.uid;

      // 2) Create Firestore user document with pending status
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(uid)
          .set({
        'name': name,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'status': 'pending',
        'active': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3) Sign out immediately - user cannot login until approved
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      // If Auth creation succeeded but Firestore failed, clean up Auth user
      if (_auth.currentUser != null) {
        try {
          await _auth.currentUser!.delete();
        } catch (_) {
          // Ignore cleanup errors
        }
      }
      if (e.code == 'email-already-in-use') {
        throw const AuthFailure('Email already registered. Please use login or contact admin.');
      }
      throw AuthFailure('Access request failed: ${e.message ?? 'Unknown error'}');
    } on FirebaseException catch (e) {
      // If Auth creation succeeded but Firestore failed, clean up Auth user
      if (_auth.currentUser != null) {
        try {
          await _auth.currentUser!.delete();
        } catch (_) {
          // Ignore cleanup errors
        }
      }
      // Provide more specific error messages
      String errorMessage = 'Failed to submit access request';
      if (e.code == 'permission-denied') {
        errorMessage = 'Permission denied. Please ensure Firestore rules are deployed. Contact admin if issue persists.';
      } else if (e.code == 'already-exists') {
        errorMessage = 'Access request already exists for this email. Please contact admin.';
      } else {
        errorMessage = 'Failed to submit access request: ${e.message ?? 'Unknown error'}';
      }
      throw FirestoreFailure(errorMessage);
    } catch (e) {
      // If Auth creation succeeded but something else failed, clean up Auth user
      if (_auth.currentUser != null) {
        try {
          await _auth.currentUser!.delete();
        } catch (_) {
          // Ignore cleanup errors
        }
      }
      if (e is Failure) rethrow;
      throw AuthFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw const AuthFailure('No user logged in');
      }

      if (user.email == null) {
        throw const AuthFailure('User email not found');
      }

      // Re-authenticate with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw const AuthFailure('Current password is incorrect');
      } else if (e.code == 'weak-password') {
        throw const AuthFailure('New password is too weak');
      }
      throw AuthFailure('Password change failed: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw AuthFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthFailure('Logout failed: ${e.toString()}');
    }
  }

  @override
  Future<domain.User?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) return null;

      final user = UserModel.fromFirestore(userDoc);
      if (!user.isApproved || !user.active) return null;

      return user;
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to fetch user: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw AuthFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Stream<domain.User?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final userDoc = await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(firebaseUser.uid)
            .get();

        if (!userDoc.exists) return null;

        final user = UserModel.fromFirestore(userDoc);
        if (!user.isApproved || !user.active) return null;

        return user;
      } catch (e) {
        return null;
      }
    });
  }
}

