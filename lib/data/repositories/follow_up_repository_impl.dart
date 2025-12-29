import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/follow_up.dart';
import '../../domain/repositories/follow_up_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/firebase_constants.dart';
import '../models/follow_up_model.dart';

class FollowUpRepositoryImpl implements FollowUpRepository {
  final FirebaseFirestore _firestore;

  FollowUpRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<FollowUp> addFollowUp(
    String leadId,
    String note,
    String createdBy, {
    String? type,
    String? region,
    String? messagePreview,
  }) async {
    try {
      // Create document with auto-generated ID in subcollection
      final docRef = _firestore
          .collection(FirebaseConstants.leadsCollection)
          .doc(leadId)
          .collection('followUps')
          .doc();

      final data = <String, dynamic>{
        'note': note.trim(),
        'createdBy': createdBy,
        // Use server timestamp so audit data is consistent
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Optional metadata for WhatsApp-based follow-ups
      if (type != null) data['type'] = type;
      if (region != null) data['region'] = region;
      if (messagePreview != null) data['messagePreview'] = messagePreview;

      await docRef.set(data);

      final createdDoc = await docRef.get();
      return FollowUpModel.fromFirestore(createdDoc);
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to add follow-up: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Stream<List<FollowUp>> streamFollowUps(String leadId) {
    try {
      return _firestore
          .collection(FirebaseConstants.leadsCollection)
          .doc(leadId)
          .collection('followUps')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => FollowUpModel.fromFirestore(doc))
            .toList();
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to stream follow-ups: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<List<FollowUp>> getFollowUps(String leadId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.leadsCollection)
          .doc(leadId)
          .collection('followUps')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FollowUpModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to get follow-ups: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }
}

