import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import '../../../lib/presentation/screens/lead_create_screen.dart';
import '../../../lib/presentation/providers/lead_create_provider.dart';
import '../../../lib/presentation/providers/lead_list_provider.dart';
import '../../../lib/presentation/providers/auth_provider.dart';
import '../../../lib/domain/repositories/lead_repository.dart';
import '../../../lib/domain/repositories/auth_repository.dart';
import '../../../lib/domain/models/lead.dart';
import '../../../lib/domain/models/user.dart';
import '../../helpers/test_helpers.dart';

class MockLeadRepository extends Mock implements LeadRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('LeadCreateScreen', () {
    late MockLeadRepository mockLeadRepository;
    late MockAuthRepository mockAuthRepository;
    late ProviderContainer container;

    setUp(() {
      mockLeadRepository = MockLeadRepository();
      mockAuthRepository = MockAuthRepository();
      container = ProviderContainer(
        overrides: [
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

    testWidgets('should show form fields', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));

      // Act
      await tester.pumpWidget(createTestWidget(const LeadCreateScreen()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Name *'), findsOneWidget);
      expect(find.text('Phone *'), findsOneWidget);
      expect(find.text('Location (optional)'), findsOneWidget);
      expect(find.text('Region *'), findsOneWidget);
      expect(find.text('Status *'), findsOneWidget);
    });

    testWidgets('should validate required fields', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));

      // Act
      await tester.pumpWidget(createTestWidget(const LeadCreateScreen()));
      await tester.pumpAndSettle();

      // Try to submit without filling required fields
      final submitButton = find.text('Create Lead');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Assert - form should show validation errors
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Phone is required'), findsOneWidget);
    });

    testWidgets('should validate phone number format', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));

      // Act
      await tester.pumpWidget(createTestWidget(const LeadCreateScreen()));
      await tester.pumpAndSettle();

      // Enter invalid phone
      final phoneField = find.widgetWithText(TextFormField, 'Phone *');
      await tester.enterText(phoneField, '123');
      await tester.pumpAndSettle();

      // Try to submit
      final submitButton = find.text('Create Lead');
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Please enter a valid phone number (at least 10 digits)'), findsOneWidget);
    });

    testWidgets('should block access for sales users', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.sales));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.sales)));

      // Act
      await tester.pumpWidget(createTestWidget(const LeadCreateScreen()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Access denied. Admin only.'), findsOneWidget);
      expect(find.text('Name *'), findsNothing);
    });
  });
}

