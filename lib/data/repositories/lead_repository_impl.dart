import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/lead.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/lead_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/firebase_constants.dart';
import '../models/lead_model.dart';

class LeadRepositoryImpl implements LeadRepository {
  final FirebaseFirestore _firestore;

  LeadRepositoryImpl({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Lead>> getLeads({
    required String? userId,
    required bool isAdmin,
    UserRegion? region,
    List<LeadStatus>? statuses,
    String? assignedTo,
    String? searchQuery,
    DateTime? createdFrom,
    DateTime? createdTo,
    int limit = 20,
    String? lastDocumentId,
  }) async {
    try {
      Query query = _firestore.collection(FirebaseConstants.leadsCollection);

      // Role-based filtering
      if (!isAdmin && userId != null) {
        // Sales users only see their assigned leads
        query = query.where('assignedTo', isEqualTo: userId);
      } else if (isAdmin && region != null) {
        // Admin can filter by region
        query = query.where('region', isEqualTo: region.name);
      }

      // Status filter (multi-select support)
      if (statuses != null && statuses.isNotEmpty) {
        if (statuses.length == 1) {
          // Single status - use equality for better index usage
          query = query.where('status', isEqualTo: statuses.first.name);
        } else {
          // Multiple statuses - use whereIn (max 10 items in Firestore)
          final statusNames = statuses.take(10).map((s) => s.name).toList();
          query = query.where('status', whereIn: statusNames);
        }
      }

      // Assigned user filter (admin only)
      if (isAdmin && assignedTo != null) {
        query = query.where('assignedTo', isEqualTo: assignedTo);
      }

      // Date range filter (Created At)
      if (createdFrom != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(createdFrom));
      }
      if (createdTo != null) {
        // Add one day to include the entire end date
        final endDate = DateTime(createdTo.year, createdTo.month, createdTo.day, 23, 59, 59);
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      // Search by name or phone
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // Firestore doesn't support OR queries, so we'll filter in memory
        // For better performance, we could use Algolia or similar
        // For now, we'll search by name (case-insensitive start)
        final lowerQuery = searchQuery.toLowerCase();
        query = query.where('name', isGreaterThanOrEqualTo: lowerQuery)
            .where('name', isLessThan: lowerQuery + '\uf8ff');
      }

      // Ordering - Use createdAt if date filter is active, otherwise updatedAt
      if (createdFrom != null || createdTo != null) {
        query = query.orderBy('createdAt', descending: true);
      } else {
        query = query.orderBy('updatedAt', descending: true);
      }

      // Pagination
      if (lastDocumentId != null) {
        final lastDoc = await _firestore
            .collection(FirebaseConstants.leadsCollection)
            .doc(lastDocumentId)
            .get();
        if (lastDoc.exists) {
          query = query.startAfterDocument(lastDoc);
        }
      }

      // Limit
      query = query.limit(limit);

      final snapshot = await query.get();

      List<Lead> leads = snapshot.docs.map((doc) {
        return LeadModel.fromFirestore(doc);
      }).toList();

      // If search query provided, filter by phone in memory
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        leads = leads.where((lead) {
          return lead.name.toLowerCase().contains(lowerQuery) ||
              lead.phone.contains(searchQuery);
        }).toList();
      }

      return leads;
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to fetch leads: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Lead> createLead(Lead lead) async {
    try {
      final leadModel = LeadModel(
        id: '', // Will be set after creation
        name: lead.name,
        phone: lead.phone,
        location: lead.location,
        region: lead.region,
        status: lead.status,
        assignedTo: lead.assignedTo,
        assignedToName: lead.assignedToName,
        createdAt: lead.createdAt,
        updatedAt: lead.updatedAt,
      );

      // Create document with auto-generated ID
      final docRef = _firestore
          .collection(FirebaseConstants.leadsCollection)
          .doc();

      await docRef.set(leadModel.toFirestore());

      final createdDoc = await docRef.get();
      return LeadModel.fromFirestore(createdDoc);
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to create lead: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> updateLeadStatus(String leadId, LeadStatus status) async {
    try {
      await _firestore
          .collection(FirebaseConstants.leadsCollection)
          .doc(leadId)
          .update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to update lead status: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Lead?> getLeadById(String leadId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.leadsCollection)
          .doc(leadId)
          .get();

      if (!doc.exists) return null;

      return LeadModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to fetch lead: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> assignLead(String leadId, String? assignedTo, String? assignedToName) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (assignedTo != null) {
        updateData['assignedTo'] = assignedTo;
        if (assignedToName != null) {
          updateData['assignedToName'] = assignedToName;
        }
      } else {
        updateData['assignedTo'] = FieldValue.delete();
        updateData['assignedToName'] = FieldValue.delete();
      }

      await _firestore
          .collection(FirebaseConstants.leadsCollection)
          .doc(leadId)
          .update(updateData);
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to assign lead: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<int> getTotalLeadsCount({
    required String? userId,
    required bool isAdmin,
    UserRegion? region,
  }) async {
    try {
      Query query = _firestore.collection(FirebaseConstants.leadsCollection);

      if (!isAdmin && userId != null) {
        query = query.where('assignedTo', isEqualTo: userId);
      } else if (isAdmin && region != null) {
        query = query.where('region', isEqualTo: region.name);
      }

      // Use count query if available, otherwise fall back to fetching
      try {
        final snapshot = await query.count().get();
        return snapshot.count ?? 0;
      } catch (e) {
        // Fallback: fetch documents and count (for web compatibility)
        final snapshot = await query.limit(1000).get();
        return snapshot.docs.length;
      }
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to get total leads count: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<int> getLeadsCountByStatus({
    required String? userId,
    required bool isAdmin,
    required LeadStatus status,
    UserRegion? region,
  }) async {
    try {
      Query query = _firestore.collection(FirebaseConstants.leadsCollection);

      if (!isAdmin && userId != null) {
        query = query.where('assignedTo', isEqualTo: userId);
      } else if (isAdmin && region != null) {
        query = query.where('region', isEqualTo: region.name);
      }

      query = query.where('status', isEqualTo: status.name);

      // Use count query if available, otherwise fall back to fetching
      try {
        final snapshot = await query.count().get();
        return snapshot.count ?? 0;
      } catch (e) {
        // Fallback: fetch documents and count (for web compatibility)
        final snapshot = await query.limit(1000).get();
        return snapshot.docs.length;
      }
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to get leads count by status: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<int> getLeadsCountByRegion({
    required String? userId,
    required bool isAdmin,
    required UserRegion region,
  }) async {
    try {
      Query query = _firestore.collection(FirebaseConstants.leadsCollection);

      if (!isAdmin && userId != null) {
        query = query.where('assignedTo', isEqualTo: userId);
      }

      query = query.where('region', isEqualTo: region.name);

      // Use count query if available, otherwise fall back to fetching
      try {
        final snapshot = await query.count().get();
        return snapshot.count ?? 0;
      } catch (e) {
        // Fallback: fetch documents and count (for web compatibility)
        final snapshot = await query.limit(1000).get();
        return snapshot.docs.length;
      }
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to get leads count by region: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<int> getLeadsCreatedToday({
    required String? userId,
    required bool isAdmin,
    UserRegion? region,
  }) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      Query query = _firestore.collection(FirebaseConstants.leadsCollection);

      // Apply role-based filter first
      if (!isAdmin && userId != null) {
        query = query.where('assignedTo', isEqualTo: userId);
      } else if (isAdmin && region != null) {
        query = query.where('region', isEqualTo: region.name);
      }

      // Date range query (may require composite index)
      query = query
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay));

      // Use count query if available, otherwise fall back to fetching
      try {
        final snapshot = await query.count().get();
        return snapshot.count ?? 0;
      } catch (e) {
        // Fallback: fetch documents and count (for web compatibility)
        final snapshot = await query.limit(1000).get();
        return snapshot.docs.length;
      }
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to get leads created today: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }


  @override
  Future<int> getLeadsCreatedThisWeek({
    required String? userId,
    required bool isAdmin,
    UserRegion? region,
  }) async {
    try {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      Query query = _firestore.collection(FirebaseConstants.leadsCollection);

      if (!isAdmin && userId != null) {
        query = query.where('assignedTo', isEqualTo: userId);
      } else if (isAdmin && region != null) {
        query = query.where('region', isEqualTo: region.name);
      }

      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeekDay));

      // Use count query if available, otherwise fall back to fetching
      try {
        final snapshot = await query.count().get();
        return snapshot.count ?? 0;
      } catch (e) {
        // Fallback: fetch documents and count (for web compatibility)
        final snapshot = await query.limit(1000).get();
        return snapshot.docs.length;
      }
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to get leads created this week: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> updatePriority(String leadId, bool isPriority) async {
    try {
      await _firestore
          .collection(FirebaseConstants.leadsCollection)
          .doc(leadId)
          .update({
        'isPriority': isPriority,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to update priority: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> updateLastContactedAt(String leadId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.leadsCollection)
          .doc(leadId)
          .update({
        'lastContactedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to update last contacted: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }
}

