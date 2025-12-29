import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import '../../../lib/presentation/providers/lead_assignment_provider.dart';
import '../../../lib/presentation/providers/lead_list_provider.dart';
import '../../../lib/presentation/providers/auth_provider.dart';
import '../../../lib/domain/repositories/lead_repository.dart';
import '../../../lib/domain/repositories/auth_repository.dart';
import '../../../lib/domain/models/lead.dart';
import '../../../lib/domain/models/user.dart';
import '../../../lib/core/errors/failures.dart';
import '../../helpers/test_helpers.dart';

class MockLeadRepository extends Mock implements LeadRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('LeadAssignmentProvider', () {
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

    Future<void> initializeAuth(User user) async {
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => user);
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(user));
      // Trigger auth provider initialization
      container.read(authProvider);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    tearDown(() {
      container.dispose();
    });

    test('should allow admin to assign lead', () async {
      // Arrange
      const leadId = 'lead-123';
      final adminUser = TestHelpers.createTestUser(role: UserRole.admin);
      final lead = TestHelpers.createTestLead(id: leadId);

      await initializeAuth(adminUser);

      when(() => mockLeadRepository.getLeadById(leadId))
          .thenAnswer((_) async => lead);
      when(() => mockLeadRepository.assignLead(leadId, 'sales-123', 'Sales User'))
          .thenAnswer((_) async => Future.value());

      // Act
      final notifier = container.read(leadAssignmentProvider(leadId).notifier);
      final result = await notifier.assignLead('sales-123', 'Sales User');

      // Assert
      expect(result, isTrue);
      verify(() => mockLeadRepository.assignLead(leadId, 'sales-123', 'Sales User')).called(1);
    });

    test('should block sales from assigning leads', () async {
      // Arrange
      const leadId = 'lead-123';
      final salesUser = TestHelpers.createTestUser(role: UserRole.sales);

      await initializeAuth(salesUser);

      // Act
      final notifier = container.read(leadAssignmentProvider(leadId).notifier);
      final result = await notifier.assignLead('user-123', 'User Name');

      // Assert
      expect(result, isFalse);
      final state = container.read(leadAssignmentProvider(leadId));
      expect(state.error, isNotNull);
      expect(state.error?.message, contains('Only admins'));
      verifyNever(() => mockLeadRepository.assignLead(any(), any(), any()));
    });

    test('should block inactive users from assigning', () async {
      // Arrange
      const leadId = 'lead-123';
      final inactiveAdmin = TestHelpers.createTestUser(
        role: UserRole.admin,
        active: false,
      );

      await initializeAuth(inactiveAdmin);

      // Act
      final notifier = container.read(leadAssignmentProvider(leadId).notifier);
      final result = await notifier.assignLead('user-123', 'User Name');

      // Assert
      expect(result, isFalse);
      final state = container.read(leadAssignmentProvider(leadId));
      expect(state.error, isNotNull);
      expect(state.error?.message, contains('Inactive'));
      verifyNever(() => mockLeadRepository.assignLead(any(), any(), any()));
    });

    test('should allow unassigning lead', () async {
      // Arrange
      const leadId = 'lead-123';
      final adminUser = TestHelpers.createTestUser(role: UserRole.admin);
      final lead = TestHelpers.createTestLead(id: leadId);

      await initializeAuth(adminUser);

      when(() => mockLeadRepository.getLeadById(leadId))
          .thenAnswer((_) async => lead);
      when(() => mockLeadRepository.assignLead(leadId, null, null))
          .thenAnswer((_) async => Future.value());

      // Act
      final notifier = container.read(leadAssignmentProvider(leadId).notifier);
      final result = await notifier.assignLead(null, null);

      // Assert
      expect(result, isTrue);
      verify(() => mockLeadRepository.assignLead(leadId, null, null)).called(1);
    });

    test('should handle assignment errors', () async {
      // Arrange
      const leadId = 'lead-123';
      final adminUser = TestHelpers.createTestUser(role: UserRole.admin);
      final lead = TestHelpers.createTestLead(id: leadId);

      await initializeAuth(adminUser);

      when(() => mockLeadRepository.getLeadById(leadId))
          .thenAnswer((_) async => lead);
      when(() => mockLeadRepository.assignLead(leadId, any(), any()))
          .thenThrow(const FirestoreFailure('Assignment failed'));

      // Act
      final notifier = container.read(leadAssignmentProvider(leadId).notifier);
      final result = await notifier.assignLead('user-123', 'User Name');

      // Assert
      expect(result, isFalse);
      final state = container.read(leadAssignmentProvider(leadId));
      expect(state.error, isNotNull);
      expect(state.error?.message, contains('Assignment failed'));
    });
  });
}

