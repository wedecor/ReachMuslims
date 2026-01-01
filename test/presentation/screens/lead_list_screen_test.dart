import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import '../../../lib/presentation/screens/lead_list_screen.dart';
import '../../../lib/presentation/providers/lead_list_provider.dart';
import '../../../lib/presentation/providers/lead_filter_provider.dart';
import '../../../lib/presentation/providers/auth_provider.dart';
import '../../../lib/domain/repositories/lead_repository.dart';
import '../../../lib/domain/repositories/auth_repository.dart';
import '../../../lib/domain/models/lead.dart';
import '../../../lib/domain/models/user.dart';
import '../../helpers/test_helpers.dart';

class MockLeadRepository extends Mock implements LeadRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('LeadListScreen', () {
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

    testWidgets('should display leads list', (WidgetTester tester) async {
      // Arrange
      final testLeads = [
        TestHelpers.createTestLead(
          id: 'lead1',
          name: 'John Doe',
          phone: '1234567890',
        ),
        TestHelpers.createTestLead(
          id: 'lead2',
          name: 'Jane Smith',
          phone: '0987654321',
        ),
      ];

      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));

      when(() => mockLeadRepository.getLeads(
            userId: any(named: 'userId'),
            isAdmin: any(named: 'isAdmin'),
            region: any(named: 'region'),
            statuses: any(named: 'statuses'),
            assignedTo: any(named: 'assignedTo'),
            searchQuery: any(named: 'searchQuery'),
            limit: any(named: 'limit'),
            lastDocumentId: any(named: 'lastDocumentId'),
          )).thenAnswer((_) async => testLeads);

      // Act
      await tester.pumpWidget(createTestWidget(const LeadListScreen()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('1234567890'), findsOneWidget);
    });

    testWidgets('should show create button for admin', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));

      when(() => mockLeadRepository.getLeads(
            userId: any(named: 'userId'),
            isAdmin: any(named: 'isAdmin'),
            region: any(named: 'region'),
            statuses: any(named: 'statuses'),
            assignedTo: any(named: 'assignedTo'),
            searchQuery: any(named: 'searchQuery'),
            limit: any(named: 'limit'),
            lastDocumentId: any(named: 'lastDocumentId'),
          )).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget(const LeadListScreen()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should not show create button for sales', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.sales));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.sales)));

      when(() => mockLeadRepository.getLeads(
            userId: any(named: 'userId'),
            isAdmin: any(named: 'isAdmin'),
            region: any(named: 'region'),
            statuses: any(named: 'statuses'),
            assignedTo: any(named: 'assignedTo'),
            searchQuery: any(named: 'searchQuery'),
            limit: any(named: 'limit'),
            lastDocumentId: any(named: 'lastDocumentId'),
          )).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget(const LeadListScreen()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('should show search field', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));

      when(() => mockLeadRepository.getLeads(
            userId: any(named: 'userId'),
            isAdmin: any(named: 'isAdmin'),
            region: any(named: 'region'),
            statuses: any(named: 'statuses'),
            assignedTo: any(named: 'assignedTo'),
            searchQuery: any(named: 'searchQuery'),
            limit: any(named: 'limit'),
            lastDocumentId: any(named: 'lastDocumentId'),
          )).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget(const LeadListScreen()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Search by name or phone'), findsOneWidget);
    });

    testWidgets('should show status filter dropdown', (WidgetTester tester) async {
      // Arrange
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));

      when(() => mockLeadRepository.getLeads(
            userId: any(named: 'userId'),
            isAdmin: any(named: 'isAdmin'),
            region: any(named: 'region'),
            statuses: any(named: 'statuses'),
            assignedTo: any(named: 'assignedTo'),
            searchQuery: any(named: 'searchQuery'),
            limit: any(named: 'limit'),
            lastDocumentId: any(named: 'lastDocumentId'),
          )).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget(const LeadListScreen()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Status'), findsOneWidget);
    });
  });
}

