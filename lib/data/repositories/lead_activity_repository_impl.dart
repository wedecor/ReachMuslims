import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/lead_activity.dart';
import '../../domain/repositories/lead_activity_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/firebase_constants.dart';
import '../models/lead_activity_model.dart';

class LeadActivityRepositoryImpl implements LeadActivityRepository {
  final FirebaseFirestore _firestore;

  LeadActivityRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<LeadActivity>> getActivities(String leadId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.leadActivitiesCollection)
          .where('leadId', isEqualTo: leadId)
          .orderBy('performedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LeadActivityModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
          'Failed to fetch activities: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Stream<List<LeadActivity>> streamActivities(String leadId) {
    try {
      return _firestore
          .collection(FirebaseConstants.leadActivitiesCollection)
          .where('leadId', isEqualTo: leadId)
          .orderBy('performedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => LeadActivityModel.fromFirestore(doc))
              .toList());
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
          'Failed to stream activities: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<LeadActivity> createActivity(LeadActivity activity) async {
    try {
      final docRef = _firestore
          .collection(FirebaseConstants.leadActivitiesCollection)
          .doc();
      
      final activityModel = LeadActivityModel(
        id: docRef.id,
        leadId: activity.leadId,
        type: activity.type,
        performedBy: activity.performedBy,
        performedByName: activity.performedByName,
        performedAt: activity.performedAt,
        metadata: activity.metadata,
      );

      await docRef.set(activityModel.toFirestore());
      return activityModel;
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
          'Failed to create activity: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> createActivities(List<LeadActivity> activities) async {
    if (activities.isEmpty) return;

    try {
      final batch = _firestore.batch();
      
      for (final activity in activities) {
        final docRef = _firestore
            .collection(FirebaseConstants.leadActivitiesCollection)
            .doc();
        
        final activityModel = LeadActivityModel(
          id: docRef.id,
          leadId: activity.leadId,
          type: activity.type,
          performedBy: activity.performedBy,
          performedByName: activity.performedByName,
          performedAt: activity.performedAt,
          metadata: activity.metadata,
        );

        batch.set(docRef, activityModel.toFirestore());
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw FirestoreFailure(
          'Failed to create activities: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }
}

