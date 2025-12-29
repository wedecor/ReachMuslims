import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../lib/data/repositories/follow_up_repository_impl.dart';
import '../../../lib/core/constants/firebase_constants.dart';
import '../../../lib/core/errors/failures.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('FollowUpRepositoryImpl', () {
    late FakeFirebaseFirestore firestore;
    late FollowUpRepositoryImpl repository;

    setUp(() {
      firestore = TestHelpers.createMockFirestore();
      repository = FollowUpRepositoryImpl(firestore: firestore);
    });

    group('addFollowUp', () {
      test('should create follow-up in subcollection', () async {
        // Arrange
        const leadId = 'lead-123';
        const note = 'Test follow-up note';
        const createdBy = 'user-123';

        // Act
        final result = await repository.addFollowUp(leadId, note, createdBy);

        // Assert
        expect(result, isNotNull);
        expect(result.note, equals(note));
        expect(result.createdBy, equals(createdBy));

        // Verify in Firestore
        final followUps = await firestore
            .collection(FirebaseConstants.leadsCollection)
            .doc(leadId)
            .collection('followUps')
            .get();

        expect(followUps.docs.length, equals(1));
        expect(followUps.docs[0].data()['note'], equals(note));
        expect(followUps.docs[0].data()['createdBy'], equals(createdBy));
      });

      test('should trim note whitespace', () async {
        // Arrange
        const leadId = 'lead-123';
        const note = '  Test note with spaces  ';
        const createdBy = 'user-123';

        // Act
        final result = await repository.addFollowUp(leadId, note, createdBy);

        // Assert
        expect(result.note, equals('Test note with spaces'));
      });
    });

    group('streamFollowUps', () {
      test('should stream follow-ups ordered by createdAt DESC', () async {
        // Arrange
        const leadId = 'lead-123';
        final now = DateTime.now();

        // Add follow-ups in order
        await firestore
            .collection(FirebaseConstants.leadsCollection)
            .doc(leadId)
            .collection('followUps')
            .add({
          'note': 'First note',
          'createdBy': 'user-1',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 2))),
        });

        await firestore
            .collection(FirebaseConstants.leadsCollection)
            .doc(leadId)
            .collection('followUps')
            .add({
          'note': 'Second note',
          'createdBy': 'user-2',
          'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
        });

        await firestore
            .collection(FirebaseConstants.leadsCollection)
            .doc(leadId)
            .collection('followUps')
            .add({
          'note': 'Third note',
          'createdBy': 'user-3',
          'createdAt': Timestamp.fromDate(now),
        });

        // Act
        final stream = repository.streamFollowUps(leadId);
        final followUps = await stream.first;

        // Assert
        expect(followUps.length, equals(3));
        // Should be ordered DESC (newest first)
        expect(followUps[0].note, equals('Third note'));
        expect(followUps[1].note, equals('Second note'));
        expect(followUps[2].note, equals('First note'));
      });

      test('should stream empty list when no follow-ups', () async {
        // Arrange
        const leadId = 'lead-123';

        // Act
        final stream = repository.streamFollowUps(leadId);
        final followUps = await stream.first;

        // Assert
        expect(followUps, isEmpty);
      });

      test('should update stream when new follow-up added', () async {
        // Arrange
        const leadId = 'lead-123';
        final stream = repository.streamFollowUps(leadId);

        // Get initial state
        final initialFollowUps = await stream.first;
        expect(initialFollowUps, isEmpty);

        // Add a follow-up
        await repository.addFollowUp(leadId, 'New note', 'user-123');

        // Wait a bit for stream to update
        await Future.delayed(const Duration(milliseconds: 100));

        // Get updated state
        final updatedFollowUps = await stream.first;
        expect(updatedFollowUps.length, equals(1));
        expect(updatedFollowUps[0].note, equals('New note'));
      });
    });
  });
}

