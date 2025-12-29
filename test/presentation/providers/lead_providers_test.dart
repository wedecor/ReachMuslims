import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import '../../../lib/presentation/providers/lead_list_provider.dart';
import '../../../lib/presentation/providers/lead_filter_provider.dart';
import '../../../lib/presentation/providers/lead_create_provider.dart';
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
  group('LeadFilterProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with empty filters', () {
      final state = container.read(leadFilterProvider);
      expect(state.status, isNull);
      expect(state.assignedTo, isNull);
      expect(state.searchQuery, isNull);
      expect(state.hasFilters, isFalse);
    });

    test('should set status filter', () {
      final notifier = container.read(leadFilterProvider.notifier);
      notifier.setStatus(LeadStatus.inTalk);

      final state = container.read(leadFilterProvider);
      expect(state.status, equals(LeadStatus.inTalk));
      expect(state.hasFilters, isTrue);
    });

    test('should clear status filter', () {
      final notifier = container.read(leadFilterProvider.notifier);
      notifier.setStatus(LeadStatus.inTalk);
      notifier.setStatus(null);

      final state = container.read(leadFilterProvider);
      expect(state.status, isNull);
    });

    test('should set search query', () {
      final notifier = container.read(leadFilterProvider.notifier);
      notifier.setSearchQuery('test query');

      final state = container.read(leadFilterProvider);
      expect(state.searchQuery, equals('test query'));
      expect(state.hasFilters, isTrue);
    });

    test('should clear all filters', () {
      final notifier = container.read(leadFilterProvider.notifier);
      notifier.setStatus(LeadStatus.inTalk);
      notifier.setAssignedTo('user123');
      notifier.setSearchQuery('test');
      notifier.clearFilters();

      final state = container.read(leadFilterProvider);
      expect(state.status, isNull);
      expect(state.assignedTo, isNull);
      expect(state.searchQuery, isNull);
      expect(state.hasFilters, isFalse);
    });
  });

  group('LeadCreateProvider', () {
    late MockLeadRepository mockLeadRepository;
    late ProviderContainer container;

    setUp(() {
      mockLeadRepository = MockLeadRepository();
      container = ProviderContainer(
        overrides: [
          leadRepositoryProvider.overrideWithValue(mockLeadRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should initialize with default values', () {
      final state = container.read(leadCreateProvider);
      expect(state.name, isEmpty);
      expect(state.phone, isEmpty);
      expect(state.region, equals(UserRegion.india));
      expect(state.status, equals(LeadStatus.newLead));
      expect(state.isLoading, isFalse);
    });

    test('should validate name is required', () {
      final notifier = container.read(leadCreateProvider.notifier);
      notifier.setPhone('1234567890');

      final state = container.read(leadCreateProvider);
      expect(state.isValid, isFalse);
      expect(state.validationErrors['name'], equals('Name is required'));
    });

    test('should validate phone is required', () {
      final notifier = container.read(leadCreateProvider.notifier);
      notifier.setName('Test Lead');

      final state = container.read(leadCreateProvider);
      expect(state.isValid, isFalse);
      expect(state.validationErrors['phone'], equals('Phone is required'));
    });

    test('should validate phone format', () {
      final notifier = container.read(leadCreateProvider.notifier);
      notifier.setName('Test Lead');
      notifier.setPhone('123'); // Too short

      final state = container.read(leadCreateProvider);
      expect(state.isValid, isFalse);
      expect(state.validationErrors['phone'], equals('Please enter a valid phone number'));
    });

    test('should be valid with correct data', () {
      final notifier = container.read(leadCreateProvider.notifier);
      notifier.setName('Test Lead');
      notifier.setPhone('1234567890');

      final state = container.read(leadCreateProvider);
      expect(state.isValid, isTrue);
      expect(state.validationErrors.isEmpty, isTrue);
    });

    test('should create lead successfully', () async {
      // Arrange
      final createdLead = TestHelpers.createTestLead(
        id: 'new-lead-123',
        name: 'Test Lead',
        phone: '1234567890',
      );

      when(() => mockLeadRepository.createLead(any()))
          .thenAnswer((_) async => createdLead);

      final notifier = container.read(leadCreateProvider.notifier);
      notifier.setName('Test Lead');
      notifier.setPhone('1234567890');

      // Act
      final result = await notifier.createLead();

      // Assert
      expect(result, isNotNull);
      expect(result?.name, equals('Test Lead'));
      verify(() => mockLeadRepository.createLead(any())).called(1);
    });

    test('should handle create lead error', () async {
      // Arrange
      when(() => mockLeadRepository.createLead(any()))
          .thenThrow(const FirestoreFailure('Failed to create'));

      final notifier = container.read(leadCreateProvider.notifier);
      notifier.setName('Test Lead');
      notifier.setPhone('1234567890');

      // Act
      final result = await notifier.createLead();

      // Assert
      expect(result, isNull);
      final state = container.read(leadCreateProvider);
      expect(state.error, isNotNull);
      expect(state.error, isA<FirestoreFailure>());
    });
  });

  group('LeadListProvider', () {
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

    test('should load leads for admin', () async {
      // Arrange
      final testLeads = [
        TestHelpers.createTestLead(id: 'lead1'),
        TestHelpers.createTestLead(id: 'lead2'),
      ];

      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));

      when(() => mockLeadRepository.getLeads(
            userId: any(named: 'userId'),
            isAdmin: any(named: 'isAdmin'),
            region: any(named: 'region'),
            status: any(named: 'status'),
            assignedTo: any(named: 'assignedTo'),
            searchQuery: any(named: 'searchQuery'),
            limit: any(named: 'limit'),
            lastDocumentId: any(named: 'lastDocumentId'),
          )).thenAnswer((_) async => testLeads);

      // Act
      final notifier = container.read(leadListProvider.notifier);
      await notifier.loadLeads(refresh: true);
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      final state = container.read(leadListProvider);
      expect(state.leads.length, equals(2));
      expect(state.isLoading, isFalse);
      verify(() => mockLeadRepository.getLeads(
            userId: any(named: 'userId'),
            isAdmin: true,
            region: any(named: 'region'),
            status: any(named: 'status'),
            assignedTo: any(named: 'assignedTo'),
            searchQuery: any(named: 'searchQuery'),
            limit: 20,
            lastDocumentId: any(named: 'lastDocumentId'),
          )).called(1);
    });

    test('should load leads for sales user', () async {
      // Arrange
      final testLeads = [TestHelpers.createTestLead(id: 'lead1')];

      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.sales));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.sales)));

      when(() => mockLeadRepository.getLeads(
            userId: any(named: 'userId'),
            isAdmin: false,
            region: any(named: 'region'),
            status: any(named: 'status'),
            assignedTo: any(named: 'assignedTo'),
            searchQuery: any(named: 'searchQuery'),
            limit: any(named: 'limit'),
            lastDocumentId: any(named: 'lastDocumentId'),
          )).thenAnswer((_) async => testLeads);

      // Act
      final notifier = container.read(leadListProvider.notifier);
      await notifier.loadLeads(refresh: true);
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      final state = container.read(leadListProvider);
      expect(state.leads.length, equals(1));
      verify(() => mockLeadRepository.getLeads(
            userId: any(named: 'userId'),
            isAdmin: false,
            region: any(named: 'region'),
            status: any(named: 'status'),
            assignedTo: any(named: 'assignedTo'),
            searchQuery: any(named: 'searchQuery'),
            limit: 20,
            lastDocumentId: any(named: 'lastDocumentId'),
          )).called(1);
    });

    test('should update lead status', () async {
      // Arrange
      final testLead = TestHelpers.createTestLead(id: 'lead1', status: LeadStatus.newLead);
      final testLeads = [testLead];

      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));

      when(() => mockLeadRepository.getLeads(
            userId: any(named: 'userId'),
            isAdmin: any(named: 'isAdmin'),
            region: any(named: 'region'),
            status: any(named: 'status'),
            assignedTo: any(named: 'assignedTo'),
            searchQuery: any(named: 'searchQuery'),
            limit: any(named: 'limit'),
            lastDocumentId: any(named: 'lastDocumentId'),
          )).thenAnswer((_) async => testLeads);

      when(() => mockLeadRepository.updateLeadStatus('lead1', LeadStatus.inTalk))
          .thenAnswer((_) async => Future.value());

      // Act
      final notifier = container.read(leadListProvider.notifier);
      await notifier.loadLeads(refresh: true);
      await Future.delayed(const Duration(milliseconds: 100));

      // Update status
      await notifier.updateStatus('lead1', LeadStatus.inTalk);
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      verify(() => mockLeadRepository.updateLeadStatus('lead1', LeadStatus.inTalk)).called(1);
    });

    test('should handle pagination', () async {
      // Arrange
      final firstBatch = List.generate(20, (i) => TestHelpers.createTestLead(id: 'lead$i'));
      final secondBatch = [TestHelpers.createTestLead(id: 'lead20')];

      when(() => mockAuthRepository.getCurrentUser())
          .thenAnswer((_) async => TestHelpers.createTestUser(role: UserRole.admin));
      when(() => mockAuthRepository.authStateChanges())
          .thenAnswer((_) => Stream.value(TestHelpers.createTestUser(role: UserRole.admin)));

      when(() => mockLeadRepository.getLeads(
            userId: any(named: 'userId'),
            isAdmin: any(named: 'isAdmin'),
            region: any(named: 'region'),
            status: any(named: 'status'),
            assignedTo: any(named: 'assignedTo'),
            searchQuery: any(named: 'searchQuery'),
            limit: 20,
            lastDocumentId: any(named: 'lastDocumentId'),
          )).thenAnswer((_) async {
        final lastDocId = container.read(leadListProvider).lastDocumentId;
        if (lastDocId == null) {
          return firstBatch;
        } else {
          return secondBatch;
        }
      });

      // Act - Load first batch
      final notifier = container.read(leadListProvider.notifier);
      await notifier.loadLeads(refresh: true);
      await Future.delayed(const Duration(milliseconds: 100));

      var state = container.read(leadListProvider);
      expect(state.leads.length, equals(20));
      expect(state.hasMore, isTrue);

      // Load more
      await notifier.loadMore();
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      state = container.read(leadListProvider);
      expect(state.leads.length, equals(21));
    });
  });
}

