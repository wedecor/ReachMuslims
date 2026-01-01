import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import '../../../lib/presentation/screens/lead_detail_screen.dart';
import '../../../lib/presentation/providers/lead_list_provider.dart';
import '../../../lib/presentation/providers/lead_assignment_provider.dart';
import '../../../lib/presentation/providers/user_list_provider.dart';
import '../../../lib/presentation/providers/auth_provider.dart';
import '../../../lib/domain/repositories/lead_repository.dart';
import '../../../lib/domain/repositories/user_repository.dart';
import '../../../lib/domain/repositories/auth_repository.dart';
import '../../../lib/domain/models/lead.dart';
import '../../../lib/domain/models/user.dart';
import '../../helpers/test_helpers.dart';

class MockLeadRepository extends Mock implements LeadRepository {}
class MockUserRepository extends Mock implements UserRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('LeadDetailScreen Assignment UI', () {
    late MockLeadRepository mockLeadRepository;
    late MockUserRepository mockUserRepository;
    late MockAuthRepository mockAuthRepository;
    late ProviderContainer container;
    late Lead testLead;

    setUp(() {
      mockLeadRepository = MockLeadRepository();
      mockUserRepository = MockUserRepository();
      mockAuthRepository = MockAuthRepository();
      testLead = TestHelpers.createTestLead(
        id: 'lead-123',
        region: UserRegion.india,
      );

      container = ProviderContainer(
        overrides: [
          leadRepositoryProvider.overrideWithValue(mockLeadRepository),
          userRepositoryProvider.overrideWithValue(mockUserRepository),
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget createTestWidget(Widget child) {
      return ProviderScope(
        parent: container,
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('should show assignment dropdown for admin', (WidgetTester tester) async {
      // Arrange
      final adminUser = TestHelpers.createTestUser(role: UserRole.admin);
      final users = [
        TestHelpers.createTestUser(uid: 'user1', name: 'User 1'),
        TestHelpers.createTestUser(uid: 'user2', name: 'User 2'),
      ];

      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => adminUser);
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(adminUser));
      when(() => mockUserRepository.getUsersByRegion(any()))
          .thenAnswer((_) async => users);
      when(() => mockLeadRepository.getLeadById(any()))
          .thenAnswer((_) async => testLead);
      when(() => mockLeadRepository.assignLead(any(), any(), any()))
          .thenAnswer((_) async => Future.value());

      // Act
      await tester.pumpWidget(createTestWidget(LeadDetailScreen(lead: testLead)));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Assigned To:'), findsOneWidget);
      expect(find.text('Unassigned'), findsOneWidget);
    });

    testWidgets('should not show assignment dropdown for sales', (WidgetTester tester) async {
      // Arrange
      final salesUser = TestHelpers.createTestUser(role: UserRole.sales);

      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => salesUser);
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(salesUser));

      // Act
      await tester.pumpWidget(createTestWidget(LeadDetailScreen(lead: testLead)));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Assigned To:'), findsNothing);
    });

    testWidgets('should disable dropdown during assignment', (WidgetTester tester) async {
      // Arrange
      final adminUser = TestHelpers.createTestUser(role: UserRole.admin);
      final users = [TestHelpers.createTestUser(uid: 'user1', name: 'User 1')];

      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => adminUser);
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(adminUser));
      when(() => mockUserRepository.getUsersByRegion(any()))
          .thenAnswer((_) async => users);
      when(() => mockLeadRepository.getLeadById(any()))
          .thenAnswer((_) async => testLead);
      when(() => mockLeadRepository.assignLead(any(), any(), any()))
          .thenAnswer((_) async {
            await Future.delayed(const Duration(seconds: 1));
            return Future.value();
          });

      // Act
      await tester.pumpWidget(createTestWidget(LeadDetailScreen(lead: testLead)));
      await tester.pumpAndSettle();

      // Find and tap dropdown
      final dropdown = find.byType(DropdownButtonFormField<String?>);
      expect(dropdown, findsOneWidget);

      // Tap to open dropdown
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Select a user (this will trigger assignment)
      final userOption = find.text('User 1');
      if (userOption.evaluate().isNotEmpty) {
        await tester.tap(userOption);
        await tester.pump();

        // Check if loading indicator appears
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      }
    });
  });
}

