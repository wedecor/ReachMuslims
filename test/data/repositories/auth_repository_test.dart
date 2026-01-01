import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import '../../../lib/data/repositories/auth_repository_impl.dart';
import '../../../lib/core/errors/failures.dart';
import '../../../lib/domain/models/user.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('AuthRepositoryImpl', () {
    late FakeFirebaseFirestore firestore;
    late MockFirebaseAuth mockAuth;
    late AuthRepositoryImpl repository;

    setUp(() {
      firestore = TestHelpers.createMockFirestore();
      mockAuth = TestHelpers.createMockAuth();
      repository = AuthRepositoryImpl(
        auth: mockAuth,
        firestore: firestore,
      );
    });

    group('login', () {
      test('should return user when login is successful and user is active', () async {
        // Arrange
        const email = 'admin@example.com';
        const password = 'password123';
        const uid = 'test-uid-123';

        // Create user document in Firestore
        await TestHelpers.addUserToFirestore(
          firestore,
          uid,
          'Admin User',
          email,
          UserRole.admin,
          UserRegion.india,
          true,
        );

        // Mock successful authentication - MockFirebaseAuth will sign in when
        // signInWithEmailAndPassword is called with matching email
        mockAuth = MockFirebaseAuth(
          signedIn: false,
          mockUser: MockUser(uid: uid, email: email),
        );
        repository = AuthRepositoryImpl(
          auth: mockAuth,
          firestore: firestore,
        );

        // Act
        final result = await repository.login(email, password);

        // Assert
        expect(result, isNotNull);
        expect(result.uid, equals(uid));
        expect(result.email, equals(email));
        expect(result.name, equals('Admin User'));
        expect(result.role, equals(UserRole.admin));
        expect(result.active, isTrue);
      });

      test('should throw AuthFailure when user document does not exist', () async {
        // Arrange
        const email = 'user@example.com';
        const password = 'password123';

        mockAuth = TestHelpers.createMockAuth(
          uid: 'non-existent-uid',
          email: email,
          signedIn: false,
        );
        repository = AuthRepositoryImpl(
          auth: mockAuth,
          firestore: firestore,
        );

        // Act & Assert
        expect(
          () => repository.login(email, password),
          throwsA(isA<AuthFailure>()),
        );
      });

      test('should throw AuthFailure when user is inactive', () async {
        // Arrange
        const email = 'inactive@example.com';
        const password = 'password123';
        const uid = 'inactive-uid-123';

        // Create inactive user document
        await TestHelpers.addUserToFirestore(
          firestore,
          uid,
          'Inactive User',
          email,
          UserRole.sales,
          UserRegion.usa,
          false, // inactive
        );

        mockAuth = TestHelpers.createMockAuth(
          uid: uid,
          email: email,
          signedIn: false,
        );
        repository = AuthRepositoryImpl(
          auth: mockAuth,
          firestore: firestore,
        );

        // Act & Assert
        expect(
          () => repository.login(email, password),
          throwsA(isA<AuthFailure>()),
        );
      });

      test('should throw AuthFailure when Firebase Auth fails', () async {
        // Arrange
        const email = 'wrong@example.com';
        const password = 'wrongpassword';

        // Create mock auth that will fail - MockFirebaseAuth throws by default
        // when signInWithEmailAndPassword is called without proper setup
        mockAuth = MockFirebaseAuth(signedIn: false);
        repository = AuthRepositoryImpl(
          auth: mockAuth,
          firestore: firestore,
        );

        // Act & Assert
        // Note: MockFirebaseAuth will throw an exception when signInWithEmailAndPassword
        // is called without a signed-in user, which will be caught and converted to AuthFailure
        expect(
          () => repository.login(email, password),
          throwsA(isA<AuthFailure>()),
        );
      });

      test('should return sales user when login is successful', () async {
        // Arrange
        const email = 'sales@example.com';
        const password = 'password123';
        const uid = 'sales-uid-456';

        await TestHelpers.addUserToFirestore(
          firestore,
          uid,
          'Sales User',
          email,
          UserRole.sales,
          UserRegion.usa,
          true,
        );

        mockAuth = MockFirebaseAuth(
          signedIn: false,
          mockUser: MockUser(uid: uid, email: email),
        );
        repository = AuthRepositoryImpl(
          auth: mockAuth,
          firestore: firestore,
        );

        // Act
        final result = await repository.login(email, password);

        // Assert
        expect(result.role, equals(UserRole.sales));
        expect(result.region, equals(UserRegion.usa));
      });
    });

    group('logout', () {
      test('should successfully logout', () async {
        // Arrange
        mockAuth = TestHelpers.createMockAuth(signedIn: true);
        repository = AuthRepositoryImpl(
          auth: mockAuth,
          firestore: firestore,
        );

        // Act
        await repository.logout();

        // Assert
        expect(mockAuth.currentUser, isNull);
      });

      test('should clear auth state on logout', () async {
        // Arrange
        mockAuth = TestHelpers.createMockAuth(signedIn: true);
        repository = AuthRepositoryImpl(
          auth: mockAuth,
          firestore: firestore,
        );

        // Act
        await repository.logout();

        // Assert
        expect(mockAuth.currentUser, isNull);
      });
    });

    group('getCurrentUser', () {
      test('should return null when no user is signed in', () async {
        // Arrange
        mockAuth = TestHelpers.createMockAuth(signedIn: false);
        repository = AuthRepositoryImpl(
          auth: mockAuth,
          firestore: firestore,
        );

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, isNull);
      });

      test('should return active admin user when signed in', () async {
        // Arrange
        const uid = 'current-user-123';
        mockAuth = TestHelpers.createMockAuth(
          uid: uid,
          signedIn: true,
        );

        await TestHelpers.addUserToFirestore(
          firestore,
          uid,
          'Current Admin',
          'admin@example.com',
          UserRole.admin,
          UserRegion.india,
          true,
        );

        repository = AuthRepositoryImpl(
          auth: mockAuth,
          firestore: firestore,
        );

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, isNotNull);
        expect(result?.uid, equals(uid));
        expect(result?.role, equals(UserRole.admin));
        expect(result?.active, isTrue);
      });

      test('should return active sales user when signed in', () async {
        // Arrange
        const uid = 'current-sales-456';
        mockAuth = TestHelpers.createMockAuth(
          uid: uid,
          signedIn: true,
        );

        await TestHelpers.addUserToFirestore(
          firestore,
          uid,
          'Current Sales',
          'sales@example.com',
          UserRole.sales,
          UserRegion.usa,
          true,
        );

        repository = AuthRepositoryImpl(
          auth: mockAuth,
          firestore: firestore,
        );

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, isNotNull);
        expect(result?.role, equals(UserRole.sales));
        expect(result?.active, isTrue);
      });

      test('should return null when user is inactive', () async {
        // Arrange
        const uid = 'inactive-current-789';
        mockAuth = TestHelpers.createMockAuth(
          uid: uid,
          signedIn: true,
        );

        await TestHelpers.addUserToFirestore(
          firestore,
          uid,
          'Inactive Current',
          'inactive@example.com',
          UserRole.admin,
          UserRegion.india,
          false, // inactive
        );

        repository = AuthRepositoryImpl(
          auth: mockAuth,
          firestore: firestore,
        );

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, isNull);
      });

      test('should return null when user document does not exist', () async {
        // Arrange
        const uid = 'non-existent-uid';
        mockAuth = TestHelpers.createMockAuth(
          uid: uid,
          signedIn: true,
        );

        repository = AuthRepositoryImpl(
          auth: mockAuth,
          firestore: firestore,
        );

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, isNull);
      });
    });

    group('authStateChanges', () {
      test('should emit null when user signs out', () async {
        // Arrange
        mockAuth = TestHelpers.createMockAuth(signedIn: true);
        repository = AuthRepositoryImpl(
          auth: mockAuth,
          firestore: firestore,
        );

        // Act
        final stream = repository.authStateChanges();
        final firstValue = await stream.first;

        // Assert
        expect(firstValue, isNull);
      });

      test('should emit user when active user signs in', () async {
        // Arrange
        const uid = 'stream-user-123';
        mockAuth = TestHelpers.createMockAuth(
          uid: uid,
          signedIn: true,
        );

        await TestHelpers.addUserToFirestore(
          firestore,
          uid,
          'Stream User',
          'stream@example.com',
          UserRole.admin,
          UserRegion.india,
          true,
        );

        repository = AuthRepositoryImpl(
          auth: mockAuth,
          firestore: firestore,
        );

        // Act
        final stream = repository.authStateChanges();
        final firstValue = await stream.first;

        // Assert
        expect(firstValue, isNotNull);
        expect(firstValue?.uid, equals(uid));
        expect(firstValue?.active, isTrue);
      });

      test('should emit null when inactive user signs in', () async {
        // Arrange
        const uid = 'inactive-stream-456';
        mockAuth = TestHelpers.createMockAuth(
          uid: uid,
          signedIn: true,
        );

        await TestHelpers.addUserToFirestore(
          firestore,
          uid,
          'Inactive Stream',
          'inactive-stream@example.com',
          UserRole.sales,
          UserRegion.usa,
          false, // inactive
        );

        repository = AuthRepositoryImpl(
          auth: mockAuth,
          firestore: firestore,
        );

        // Act
        final stream = repository.authStateChanges();
        final firstValue = await stream.first;

        // Assert
        expect(firstValue, isNull);
      });
    });
  });
}

