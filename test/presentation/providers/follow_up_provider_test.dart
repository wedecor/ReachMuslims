import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import '../../../lib/presentation/providers/follow_up_provider.dart';
import '../../../lib/presentation/providers/auth_provider.dart';
import '../../../lib/presentation/providers/lead_list_provider.dart';
import '../../../lib/domain/repositories/follow_up_repository.dart';
import '../../../lib/domain/repositories/lead_repository.dart';
import '../../../lib/domain/repositories/auth_repository.dart';
import '../../../lib/domain/models/follow_up.dart';
import '../../../lib/domain/models/lead.dart';
import '../../../lib/domain/models/user.dart';
import '../../../lib/core/errors/failures.dart';
import '../../helpers/test_helpers.dart';

class MockFollowUpRepository extends Mock implements FollowUpRepository {}
class MockLeadRepository extends Mock implements LeadRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('FollowUpListProvider', () {
    late MockFollowUpRepository mockFollowUpRepository;
    late ProviderContainer container;

    setUp(() {
      mockFollowUpRepository = MockFollowUpRepository();
      container = ProviderContainer(
        overrides: [
          followUpRepositoryProvider.overrideWithValue(mockFollowUpRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with loading state', () {
      // Arrange
      const leadId = 'lead-123';
      when(() => mockFollowUpRepository.streamFollowUps(leadId))
          .thenAnswer((_) => Stream.value([]));

      // Act
      container.read(followUpListProvider(leadId).notifier);
      final state = container.read(followUpListProvider(leadId));

      // Assert
      expect(state.isLoading, isTrue);
      expect(state.followUps, isEmpty);
    });

    test('should update state when follow-ups stream emits', () async {
      // Arrange
      const leadId = 'lead-123';
      final testFollowUps = [
        TestHelpers.createTestFollowUp(id: 'fu1', note: 'Note 1'),
        TestHelpers.createTestFollowUp(id: 'fu2', note: 'Note 2'),
      ];

      when(() => mockFollowUpRepository.streamFollowUps(leadId))
          .thenAnswer((_) => Stream.value(testFollowUps));

      // Act
      await Future.delayed(const Duration(milliseconds: 100));
      final state = container.read(followUpListProvider(leadId));

      // Assert
      expect(state.isLoading, isFalse);
      expect(state.followUps.length, equals(2));
      expect(state.followUps[0].note, equals('Note 1'));
    });
  });

  group('AddFollowUpProvider', () {
    late MockFollowUpRepository mockFollowUpRepository;
    late MockLeadRepository mockLeadRepository;
    late MockAuthRepository mockAuthRepository;
    late ProviderContainer container;

    setUp(() {
      mockFollowUpRepository = MockFollowUpRepository();
      mockLeadRepository = MockLeadRepository();
      mockAuthRepository = MockAuthRepository();
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

    test('should reject empty note', () async {
      // Arrange
      const leadId = 'lead-123';
      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));

      // Act
      final notifier = container.read(addFollowUpProvider(leadId).notifier);
      final result = await notifier.addFollowUp('');

      // Assert
      expect(result, isFalse);
      final state = container.read(addFollowUpProvider(leadId));
      expect(state.error, isNotNull);
      expect(state.error?.message, contains('cannot be empty'));
    });

    test('should allow admin to add follow-up to lead in region', () async {
      // Arrange
      const leadId = 'lead-123';
      final adminUser = TestHelpers.createTestUser(
        role: UserRole.admin,
        region: UserRegion.india,
      );
      final lead = TestHelpers.createTestLead(
        id: leadId,
        region: UserRegion.india,
      );

      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => adminUser);
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(adminUser));
      when(() => mockLeadRepository.getLeadById(leadId))
          .thenAnswer((_) async => lead);
      when(() => mockFollowUpRepository.addFollowUp(leadId, any(), any()))
          .thenAnswer((_) async => TestHelpers.createTestFollowUp());

      // Act
      final notifier = container.read(addFollowUpProvider(leadId).notifier);
      final result = await notifier.addFollowUp('Test note');

      // Assert
      expect(result, isTrue);
      verify(() => mockFollowUpRepository.addFollowUp(leadId, 'Test note', adminUser.uid)).called(1);
    });

    test('should block admin from adding to lead in different region', () async {
      // Arrange
      const leadId = 'lead-123';
      final adminUser = TestHelpers.createTestUser(
        role: UserRole.admin,
        region: UserRegion.india,
      );
      final lead = TestHelpers.createTestLead(
        id: leadId,
        region: UserRegion.usa, // Different region
      );

      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => adminUser);
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(adminUser));
      when(() => mockLeadRepository.getLeadById(leadId))
          .thenAnswer((_) async => lead);

      // Act
      final notifier = container.read(addFollowUpProvider(leadId).notifier);
      final result = await notifier.addFollowUp('Test note');

      // Assert
      expect(result, isFalse);
      final state = container.read(addFollowUpProvider(leadId));
      expect(state.error, isNotNull);
      expect(state.error?.message, contains('region'));
      verifyNever(() => mockFollowUpRepository.addFollowUp(any(), any(), any()));
    });

    test('should allow sales to add to assigned lead', () async {
      // Arrange
      const leadId = 'lead-123';
      final salesUser = TestHelpers.createTestUser(
        role: UserRole.sales,
        uid: 'sales-123',
      );
      final lead = TestHelpers.createTestLead(
        id: leadId,
        assignedTo: 'sales-123', // Assigned to this sales user
      );

      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => salesUser);
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(salesUser));
      when(() => mockLeadRepository.getLeadById(leadId))
          .thenAnswer((_) async => lead);
      when(() => mockFollowUpRepository.addFollowUp(leadId, any(), any()))
          .thenAnswer((_) async => TestHelpers.createTestFollowUp());

      // Act
      final notifier = container.read(addFollowUpProvider(leadId).notifier);
      final result = await notifier.addFollowUp('Test note');

      // Assert
      expect(result, isTrue);
      verify(() => mockFollowUpRepository.addFollowUp(leadId, 'Test note', salesUser.uid)).called(1);
    });

    test('should block sales from adding to unassigned lead', () async {
      // Arrange
      const leadId = 'lead-123';
      final salesUser = TestHelpers.createTestUser(
        role: UserRole.sales,
        uid: 'sales-123',
      );
      final lead = TestHelpers.createTestLead(
        id: leadId,
        assignedTo: 'other-sales-456', // Assigned to different user
      );

      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => salesUser);
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(salesUser));
      when(() => mockLeadRepository.getLeadById(leadId))
          .thenAnswer((_) async => lead);

      // Act
      final notifier = container.read(addFollowUpProvider(leadId).notifier);
      final result = await notifier.addFollowUp('Test note');

      // Assert
      expect(result, isFalse);
      final state = container.read(addFollowUpProvider(leadId));
      expect(state.error, isNotNull);
      expect(state.error?.message, contains('assigned'));
      verifyNever(() => mockFollowUpRepository.addFollowUp(any(), any(), any()));
    });

    test('should block inactive users', () async {
      // Arrange
      const leadId = 'lead-123';
      final inactiveUser = TestHelpers.createTestUser(
        role: UserRole.admin,
        active: false,
      );

      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => inactiveUser);
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(inactiveUser));

      // Act
      final notifier = container.read(addFollowUpProvider(leadId).notifier);
      final result = await notifier.addFollowUp('Test note');

      // Assert
      expect(result, isFalse);
      final state = container.read(addFollowUpProvider(leadId));
      expect(state.error, isNotNull);
      expect(state.error?.message, contains('Inactive'));
      verifyNever(() => mockFollowUpRepository.addFollowUp(any(), any(), any()));
    });
  });
}

