import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import '../../../lib/presentation/screens/lead_detail_screen.dart';
import '../../../lib/presentation/providers/lead_list_provider.dart';
import '../../../lib/core/errors/failures.dart';
import '../../../lib/presentation/providers/follow_up_provider.dart';
import '../../../lib/presentation/providers/auth_provider.dart';
import '../../../lib/domain/repositories/follow_up_repository.dart';
import '../../../lib/domain/repositories/lead_repository.dart';
import '../../../lib/domain/repositories/auth_repository.dart';
import '../../../lib/domain/models/lead.dart';
import '../../../lib/domain/models/user.dart';
import '../../helpers/test_helpers.dart';

class MockFollowUpRepository extends Mock implements FollowUpRepository {}
class MockLeadRepository extends Mock implements LeadRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('LeadDetailScreen', () {
    late MockFollowUpRepository mockFollowUpRepository;
    late MockLeadRepository mockLeadRepository;
    late MockAuthRepository mockAuthRepository;
    late ProviderContainer container;
    late Lead testLead;

    setUp(() {
      mockFollowUpRepository = MockFollowUpRepository();
      mockLeadRepository = MockLeadRepository();
      mockAuthRepository = MockAuthRepository();
      testLead = TestHelpers.createTestLead(
        id: 'lead-123',
        name: 'Test Lead',
        phone: '1234567890',
      );

      container = ProviderContainer(
        overrides: [
          followUpRepositoryProvider.overrideWithValue(mockFollowUpRepository),
          leadRepositoryProvider.overrideWithValue(mockLeadRepository),
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

    testWidgets('should display lead details', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));
      when(() => mockFollowUpRepository.streamFollowUps(any()))
          .thenAnswer((_) => Stream.value([]));

      // Act
      await tester.pumpWidget(createTestWidget(LeadDetailScreen(lead: testLead)));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Lead'), findsOneWidget);
      expect(find.text('Phone: 1234567890'), findsOneWidget);
    });

    testWidgets('should show empty state when no follow-ups', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));
      when(() => mockFollowUpRepository.streamFollowUps(any()))
          .thenAnswer((_) => Stream.value([]));

      // Act
      await tester.pumpWidget(createTestWidget(LeadDetailScreen(lead: testLead)));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No follow-ups yet'), findsOneWidget);
      expect(find.text('Add your first follow-up note above'), findsOneWidget);
    });

    testWidgets('should display follow-up timeline', (WidgetTester tester) async {
      // Arrange
      final testFollowUps = [
        TestHelpers.createTestFollowUp(
          id: 'fu1',
          note: 'First follow-up',
          createdByName: 'John Doe',
        ),
        TestHelpers.createTestFollowUp(
          id: 'fu2',
          note: 'Second follow-up',
          createdByName: 'Jane Smith',
        ),
      ];

      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));
      when(() => mockFollowUpRepository.streamFollowUps(any()))
          .thenAnswer((_) => Stream.value(testFollowUps));

      // Act
      await tester.pumpWidget(createTestWidget(LeadDetailScreen(lead: testLead)));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('First follow-up'), findsOneWidget);
      expect(find.text('Second follow-up'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets('should show follow-up input for active users', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));
      when(() => mockFollowUpRepository.streamFollowUps(any()))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockLeadRepository.getLeadById(any()))
          .thenAnswer((_) async => testLead);
      when(() => mockFollowUpRepository.addFollowUp(any(), any(), any()))
          .thenAnswer((_) async => TestHelpers.createTestFollowUp());

      // Act
      await tester.pumpWidget(createTestWidget(LeadDetailScreen(lead: testLead)));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Add a follow-up note...'), findsOneWidget);
      expect(find.text('Add Follow-Up'), findsOneWidget);
    });

    testWidgets('should add follow-up when submit button pressed', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));
      when(() => mockFollowUpRepository.streamFollowUps(any()))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockLeadRepository.getLeadById(any()))
          .thenAnswer((_) async => testLead);
      when(() => mockFollowUpRepository.addFollowUp(any(), any(), any()))
          .thenAnswer((_) async => TestHelpers.createTestFollowUp());

      // Act
      await tester.pumpWidget(createTestWidget(LeadDetailScreen(lead: testLead)));
      await tester.pumpAndSettle();

      // Enter note
      final noteField = find.widgetWithText(TextField, 'Add a follow-up note...');
      await tester.enterText(noteField, 'Test follow-up note');
      await tester.pumpAndSettle();

      // Tap submit
      final submitButton = find.text('Add Follow-Up');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Assert
      verify(() => mockFollowUpRepository.addFollowUp(
            'lead-123',
            'Test follow-up note',
            any(),
          )).called(1);
    });

    testWidgets('should clear input after successful submission', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));
      when(() => mockFollowUpRepository.streamFollowUps(any()))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockLeadRepository.getLeadById(any()))
          .thenAnswer((_) async => testLead);
      when(() => mockFollowUpRepository.addFollowUp(any(), any(), any()))
          .thenAnswer((_) async => TestHelpers.createTestFollowUp());

      // Act
      await tester.pumpWidget(createTestWidget(LeadDetailScreen(lead: testLead)));
      await tester.pumpAndSettle();

      // Enter note
      final noteField = find.widgetWithText(TextField, 'Add a follow-up note...');
      await tester.enterText(noteField, 'Test note');
      await tester.pumpAndSettle();

      // Verify text is entered
      expect(find.text('Test note'), findsOneWidget);

      // Tap submit
      final submitButton = find.text('Add Follow-Up');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Assert - input should be cleared
      final textField = tester.widget<TextField>(noteField);
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('should show error message on add failure', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));
      when(() => mockFollowUpRepository.streamFollowUps(any()))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockLeadRepository.getLeadById(any()))
          .thenAnswer((_) async => testLead);
      when(() => mockFollowUpRepository.addFollowUp(any(), any(), any()))
          .thenThrow(const FirestoreFailure('Failed to add'));

      // Act
      await tester.pumpWidget(createTestWidget(LeadDetailScreen(lead: testLead)));
      await tester.pumpAndSettle();

      // Enter note and submit
      final noteField = find.widgetWithText(TextField, 'Add a follow-up note...');
      await tester.enterText(noteField, 'Test note');
      await tester.pumpAndSettle();

      final submitButton = find.text('Add Follow-Up');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Assert - error should be shown in snackbar
      expect(find.text('Error: Failed to add'), findsOneWidget);
    });
  });
}

