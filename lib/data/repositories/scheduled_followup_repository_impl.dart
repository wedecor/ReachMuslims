import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/scheduled_followup.dart';
import '../../domain/repositories/scheduled_followup_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/firebase_constants.dart';
import '../models/scheduled_followup_model.dart';

class ScheduledFollowUpRepositoryImpl implements ScheduledFollowUpRepository {
  final FirebaseFirestore _firestore;

  ScheduledFollowUpRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<ScheduledFollowUp> createScheduledFollowUp({
    required String leadId,
    required DateTime scheduledAt,
    String? note,
    required String createdBy,
  }) async {
    try {
      final now = DateTime.now();
      final scheduledFollowUp = ScheduledFollowUpModel(
        id: '', // Will be set after creation
        leadId: leadId,
        scheduledAt: scheduledAt,
        note: note,
        createdBy: createdBy,
        status: ScheduledFollowUpStatus.pending,
        createdAt: now,
      );

      final docRef = _firestore
          .collection(FirebaseConstants.scheduledFollowUpsCollection)
          .doc();

      await docRef.set(scheduledFollowUp.toFirestore());

      final createdDoc = await docRef.get();
      return ScheduledFollowUpModel.fromFirestore(createdDoc);
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to create scheduled follow-up: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      throw FirestoreFailure('Failed to create scheduled follow-up: ${e.toString()}');
    }
  }

  @override
  Future<List<ScheduledFollowUp>> getScheduledFollowUpsForLead(String leadId) async {
    try {
      // Proper Firestore query with composite index
      // Index required: leadId (ASC), scheduledAt (ASC)
      final snapshot = await _firestore
          .collection(FirebaseConstants.scheduledFollowUpsCollection)
          .where('leadId', isEqualTo: leadId)
          .orderBy('scheduledAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ScheduledFollowUpModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        throw FirestoreFailure(
          'Firestore index is being created. Please wait a few minutes and try again. '
          'Index: scheduled_followups (leadId, scheduledAt)',
        );
      }
      throw FirestoreFailure('Failed to get scheduled follow-ups: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      throw FirestoreFailure('Failed to get scheduled follow-ups: ${e.toString()}');
    }
  }

  @override
  Future<List<ScheduledFollowUp>> getPendingFollowUpsForUser(String userId) async {
    try {
      final now = DateTime.now();
      // Proper Firestore query with composite index
      // Index required: createdBy (ASC), status (ASC), scheduledAt (ASC)
      final snapshot = await _firestore
          .collection(FirebaseConstants.scheduledFollowUpsCollection)
          .where('createdBy', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .where('scheduledAt', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .orderBy('scheduledAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ScheduledFollowUpModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      // If index is missing, provide helpful error message
      if (e.code == 'failed-precondition') {
        throw FirestoreFailure(
          'Firestore index is being created. Please wait a few minutes and try again. '
          'Index: scheduled_followups (createdBy, status, scheduledAt)',
        );
      }
      throw FirestoreFailure('Failed to get pending follow-ups: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      throw FirestoreFailure('Failed to get pending follow-ups: ${e.toString()}');
    }
  }

  @override
  Future<List<ScheduledFollowUp>> getAllFollowUpsForUser(String userId) async {
    try {
      // Proper Firestore query with composite index
      // Index required: createdBy (ASC), scheduledAt (ASC)
      final snapshot = await _firestore
          .collection(FirebaseConstants.scheduledFollowUpsCollection)
          .where('createdBy', isEqualTo: userId)
          .orderBy('scheduledAt', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => ScheduledFollowUpModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        throw FirestoreFailure(
          'Firestore index is being created. Please wait a few minutes and try again. '
          'Index: scheduled_followups (createdBy, scheduledAt)',
        );
      }
      throw FirestoreFailure('Failed to get follow-ups: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      throw FirestoreFailure('Failed to get follow-ups: ${e.toString()}');
    }
  }

  @override
  Future<void> markAsCompleted(String scheduledFollowUpId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.scheduledFollowUpsCollection)
          .doc(scheduledFollowUpId)
          .update({'status': 'completed'});
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to mark as completed: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      throw FirestoreFailure('Failed to mark as completed: ${e.toString()}');
    }
  }

  @override
  Future<void> markAsMissed(String scheduledFollowUpId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.scheduledFollowUpsCollection)
          .doc(scheduledFollowUpId)
          .update({'status': 'missed'});
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to mark as missed: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      throw FirestoreFailure('Failed to mark as missed: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteScheduledFollowUp(String scheduledFollowUpId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.scheduledFollowUpsCollection)
          .doc(scheduledFollowUpId)
          .delete();
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to delete scheduled follow-up: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      throw FirestoreFailure('Failed to delete scheduled follow-up: ${e.toString()}');
    }
  }

  @override
  Future<ScheduledFollowUp?> getScheduledFollowUpById(String scheduledFollowUpId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.scheduledFollowUpsCollection)
          .doc(scheduledFollowUpId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return ScheduledFollowUpModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to get scheduled follow-up: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      throw FirestoreFailure('Failed to get scheduled follow-up: ${e.toString()}');
    }
  }
}

