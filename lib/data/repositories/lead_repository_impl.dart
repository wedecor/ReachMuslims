import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/lead.dart';
import '../../domain/models/user.dart';
import '../../domain/models/lead_edit_history.dart';
import '../../domain/repositories/lead_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/constants/firebase_constants.dart';
import '../models/lead_model.dart';
import '../models/lead_edit_history_model.dart';

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

      // Note: We don't filter isDeleted in query to maintain backward compatibility
      // with existing leads that don't have the field. We filter in memory instead.

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
      // Note: Firestore doesn't support full-text search (contains), so we'll
      // fetch leads and filter in memory. For better performance with large datasets,
      // we increase the limit when searching.
      // Don't add Firestore query for search - we'll filter in memory instead

      // Ordering - Use createdAt if date filter is active, otherwise updatedAt
      // When we have name range filters, we must order by updatedAt (not name)
      // because Firestore requires orderBy to come after range filters
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

      // Limit - increase limit when searching to allow better in-memory filtering
      final searchLimit = (searchQuery != null && searchQuery.isNotEmpty) ? (limit * 5) : limit;
      query = query.limit(searchLimit);

      final snapshot = await query.get();

      List<Lead> leads = snapshot.docs.map((doc) {
        return LeadModel.fromFirestore(doc);
      }).toList();

      // Filter out soft-deleted leads (handle backward compatibility: old leads may not have isDeleted field)
      // If isDeleted is null (old lead), treat as not deleted
      leads = leads.where((lead) => !lead.isDeleted).toList();

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
  Future<Lead?> findDuplicateByPhone({
    required String phone,
    required String? userId,
    required bool isAdmin,
  }) async {
    try {
      // Normalize phone number (digits only)
      final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
      if (digitsOnly.isEmpty) return null;

      Query query = _firestore.collection(FirebaseConstants.leadsCollection);
      
      // Filter by phone number (exact match on digits)
      // Note: We search by phone field which should contain digits only
      // For better performance, we could create a phoneDigits field
      query = query.where('phone', isEqualTo: digitsOnly);
      
      // Role-based scope:
      // Admin: all leads (no additional filter)
      // Sales: check assigned to them OR unassigned (read-only check)
      // Note: Firestore doesn't support whereIn with null, so we need two queries
      if (!isAdmin && userId != null) {
        // For sales users, we'll check both assigned and unassigned
        // First check assigned leads
        var assignedQuery = _firestore.collection(FirebaseConstants.leadsCollection)
            .where('phone', isEqualTo: digitsOnly)
            .where('assignedTo', isEqualTo: userId)
            .where('isDeleted', isEqualTo: false)
            .limit(1);
        final assignedSnapshot = await assignedQuery.get();
        if (assignedSnapshot.docs.isNotEmpty) {
          return LeadModel.fromFirestore(assignedSnapshot.docs.first);
        }
        // Then check unassigned leads (assignedTo field doesn't exist or is null)
        // We'll fetch all leads with this phone and filter in memory
        // This is acceptable since we limit to a small number
        var unassignedQuery = _firestore.collection(FirebaseConstants.leadsCollection)
            .where('phone', isEqualTo: digitsOnly)
            .where('isDeleted', isEqualTo: false)
            .limit(10); // Small limit for in-memory filtering
        final unassignedSnapshot = await unassignedQuery.get();
        for (var doc in unassignedSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          final assignedTo = data['assignedTo'] as String?;
          if (assignedTo == null || assignedTo.isEmpty) {
            return LeadModel.fromFirestore(doc);
          }
        }
        return null; // No duplicate found
      }
      
      // For admin: check all leads
      // Exclude deleted leads
      query = query.where('isDeleted', isEqualTo: false);
      
      // Limit to 1 (we only need to know if duplicate exists)
      query = query.limit(1);
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        return null;
      }
      
      // Return the first matching lead
      return LeadModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      // If query fails (e.g., missing index), return null to allow creation
      // This is a safety measure - we don't want to block creation due to query errors
      debugPrint('Error checking duplicate: $e');
      return null;
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
        source: lead.source,
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

      // Note: We don't filter isDeleted in query to maintain backward compatibility
      // with existing leads that don't have the field. We filter in memory instead.

      if (!isAdmin && userId != null) {
        query = query.where('assignedTo', isEqualTo: userId);
      } else if (isAdmin && region != null) {
        query = query.where('region', isEqualTo: region.name);
      }

      // Use count query if available, otherwise fall back to fetching
      // Note: We need to filter deleted leads in memory for accuracy
      try {
        final snapshot = await query.limit(1000).get();
        final leads = snapshot.docs.map((doc) => LeadModel.fromFirestore(doc)).toList();
        return leads.where((lead) => !lead.isDeleted).length;
      } catch (e) {
        // Fallback: fetch documents and count (for web compatibility)
        final snapshot = await query.limit(1000).get();
        final leads = snapshot.docs.map((doc) => LeadModel.fromFirestore(doc)).toList();
        return leads.where((lead) => !lead.isDeleted).length;
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

      // Note: We don't filter isDeleted in query to maintain backward compatibility
      // with existing leads that don't have the field. We filter in memory instead.

      if (!isAdmin && userId != null) {
        query = query.where('assignedTo', isEqualTo: userId);
      } else if (isAdmin && region != null) {
        query = query.where('region', isEqualTo: region.name);
      }

      query = query.where('status', isEqualTo: status.name);

      // Use count query if available, otherwise fall back to fetching
      // Note: We need to filter deleted leads in memory for accuracy
      try {
        final snapshot = await query.limit(1000).get();
        final leads = snapshot.docs.map((doc) => LeadModel.fromFirestore(doc)).toList();
        return leads.where((lead) => !lead.isDeleted).length;
      } catch (e) {
        // Fallback: fetch documents and count (for web compatibility)
        final snapshot = await query.limit(1000).get();
        final leads = snapshot.docs.map((doc) => LeadModel.fromFirestore(doc)).toList();
        return leads.where((lead) => !lead.isDeleted).length;
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

      // Note: We don't filter isDeleted in query to maintain backward compatibility
      // with existing leads that don't have the field. We filter in memory instead.

      if (!isAdmin && userId != null) {
        query = query.where('assignedTo', isEqualTo: userId);
      }

      query = query.where('region', isEqualTo: region.name);

      // Use count query if available, otherwise fall back to fetching
      // Note: We need to filter deleted leads in memory for accuracy
      try {
        final snapshot = await query.limit(1000).get();
        final leads = snapshot.docs.map((doc) => LeadModel.fromFirestore(doc)).toList();
        return leads.where((lead) => !lead.isDeleted).length;
      } catch (e) {
        // Fallback: fetch documents and count (for web compatibility)
        final snapshot = await query.limit(1000).get();
        final leads = snapshot.docs.map((doc) => LeadModel.fromFirestore(doc)).toList();
        return leads.where((lead) => !lead.isDeleted).length;
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

      // Note: We don't filter isDeleted in query to maintain backward compatibility
      // with existing leads that don't have the field. We filter in memory instead.

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
      // Note: We need to filter deleted leads in memory for accuracy
      try {
        final snapshot = await query.limit(1000).get();
        final leads = snapshot.docs.map((doc) => LeadModel.fromFirestore(doc)).toList();
        return leads.where((lead) => !lead.isDeleted).length;
      } catch (e) {
        // Fallback: fetch documents and count (for web compatibility)
        final snapshot = await query.limit(1000).get();
        final leads = snapshot.docs.map((doc) => LeadModel.fromFirestore(doc)).toList();
        return leads.where((lead) => !lead.isDeleted).length;
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

      // Note: We don't filter isDeleted in query to maintain backward compatibility
      // with existing leads that don't have the field. We filter in memory instead.

      if (!isAdmin && userId != null) {
        query = query.where('assignedTo', isEqualTo: userId);
      } else if (isAdmin && region != null) {
        query = query.where('region', isEqualTo: region.name);
      }

      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeekDay));

      // Use count query if available, otherwise fall back to fetching
      // Note: We need to filter deleted leads in memory for accuracy
      try {
        final snapshot = await query.limit(1000).get();
        final leads = snapshot.docs.map((doc) => LeadModel.fromFirestore(doc)).toList();
        return leads.where((lead) => !lead.isDeleted).length;
      } catch (e) {
        // Fallback: fetch documents and count (for web compatibility)
        final snapshot = await query.limit(1000).get();
        final leads = snapshot.docs.map((doc) => LeadModel.fromFirestore(doc)).toList();
        return leads.where((lead) => !lead.isDeleted).length;
      }
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to get leads created this week: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<int> getPriorityLeadsCount({
    required String? userId,
    required bool isAdmin,
    UserRegion? region,
  }) async {
    try {
      Query query = _firestore.collection(FirebaseConstants.leadsCollection);

      // Note: We don't filter isDeleted in query to maintain backward compatibility
      // with existing leads that don't have the field. We filter in memory instead.

      if (!isAdmin && userId != null) {
        query = query.where('assignedTo', isEqualTo: userId);
      } else if (isAdmin && region != null) {
        query = query.where('region', isEqualTo: region.name);
      }

      query = query.where('isPriority', isEqualTo: true);

      // Fetch and filter deleted leads in memory
      try {
        final snapshot = await query.limit(1000).get();
        final leads = snapshot.docs.map((doc) => LeadModel.fromFirestore(doc)).toList();
        return leads.where((lead) => !lead.isDeleted).length;
      } catch (e) {
        // Fallback: fetch documents and count (for web compatibility)
        final snapshot = await query.limit(1000).get();
        final leads = snapshot.docs.map((doc) => LeadModel.fromFirestore(doc)).toList();
        return leads.where((lead) => !lead.isDeleted).length;
      }
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to get priority leads count: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<int> getFollowUpLeadsCount({
    required String? userId,
    required bool isAdmin,
    UserRegion? region,
  }) async {
    try {
      Query query = _firestore.collection(FirebaseConstants.leadsCollection);

      // Note: We don't filter isDeleted in query to maintain backward compatibility
      // with existing leads that don't have the field. We filter in memory instead.

      if (!isAdmin && userId != null) {
        query = query.where('assignedTo', isEqualTo: userId);
      } else if (isAdmin && region != null) {
        query = query.where('region', isEqualTo: region.name);
      }

      // Fetch all leads and filter in memory for lastContactedAt != null
      // Note: Firestore doesn't support != null queries directly, so we fetch and filter
      try {
        final snapshot = await query.limit(1000).get();
        final leads = snapshot.docs.map((doc) => LeadModel.fromFirestore(doc)).toList();
        return leads.where((lead) => !lead.isDeleted && lead.lastContactedAt != null).length;
      } catch (e) {
        // Fallback: fetch documents and count (for web compatibility)
        final snapshot = await query.limit(1000).get();
        final leads = snapshot.docs.map((doc) => LeadModel.fromFirestore(doc)).toList();
        return leads.where((lead) => !lead.isDeleted && lead.lastContactedAt != null).length;
      }
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to get follow-up leads count: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<int> getLeadsContactedTodayCount({
    required String? userId,
    required bool isAdmin,
    UserRegion? region,
  }) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    Query query = _firestore.collection(FirebaseConstants.leadsCollection);

    // Apply role-based filtering
    if (!isAdmin && userId != null) {
      query = query.where('assignedTo', isEqualTo: userId);
    } else if (isAdmin && region != null) {
      query = query.where('region', isEqualTo: region.name);
    }

    // Filter by lastContactedAt date range (today)
    query = query
        .where('lastContactedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('lastContactedAt', isLessThan: Timestamp.fromDate(todayEnd))
        .orderBy('lastContactedAt', descending: true);

    // Fetch and filter deleted leads in memory
    try {
      final snapshot = await query.limit(1000).get();
      final leads = snapshot.docs.map((doc) => LeadModel.fromFirestore(doc)).toList();
      return leads.where((lead) => !lead.isDeleted).length;
    } on FirebaseException catch (e) {
      // Check if it's a missing index error
      if (e.code == 'failed-precondition') {
        debugPrint('Firestore index missing for leads contacted today query. '
            'This is a non-critical error - returning 0. '
            'Index needed: leads (assignedTo/region, lastContactedAt)');
        return 0; // Return 0 instead of throwing to prevent dashboard from breaking
      }
      // For other errors, also return 0 to prevent dashboard breakage
      debugPrint('Error querying leads contacted today: ${e.message}');
      return 0;
    } catch (e) {
      // Catch all other errors and return 0
      debugPrint('Unexpected error in getLeadsContactedTodayCount: $e');
      return 0;
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

  @override
  Future<void> updateLead({
    required String leadId,
    required String name,
    required String phone,
    String? location,
    required String? userId,
    required bool isAdmin,
  }) async {
    try {
      // Get lead to check permissions
      final lead = await getLeadById(leadId);
      if (lead == null) {
        throw FirestoreFailure('Lead not found');
      }

      // Permission check: Admin can edit any lead, Sales can edit only assigned leads
      if (!isAdmin && lead.assignedTo != userId) {
        throw FirestoreFailure('You do not have permission to edit this lead');
      }

      // Build update data - only update specified fields
      final updateData = <String, dynamic>{
        'name': name.trim(),
        'phone': phone.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Handle location: if null, delete the field; if provided, set it
      if (location == null || location.trim().isEmpty) {
        updateData['location'] = FieldValue.delete();
      } else {
        updateData['location'] = location.trim();
      }

      // Update only the specified fields - preserves all other fields
      await _firestore
          .collection(FirebaseConstants.leadsCollection)
          .doc(leadId)
          .update(updateData);
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to update lead: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> softDeleteLead({
    required String leadId,
    required String? userId,
    required bool isAdmin,
  }) async {
    try {
      // Permission check: Only Admin can delete leads
      if (!isAdmin) {
        throw FirestoreFailure('Only admins can delete leads');
      }

      // Verify lead exists
      final lead = await getLeadById(leadId);
      if (lead == null) {
        throw FirestoreFailure('Lead not found');
      }

      // Soft delete: Set isDeleted = true, update updatedAt
      // Does NOT delete the document or any related data
      await _firestore
          .collection(FirebaseConstants.leadsCollection)
          .doc(leadId)
          .update({
        'isDeleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to delete lead: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<void> logEditHistory({
    required String leadId,
    required String editedBy,
    String? editedByName,
    String? editedByEmail,
    required Map<String, FieldChange> changes,
  }) async {
    try {
      // Only log if there are actual changes
      if (changes.isEmpty) {
        return;
      }

      final docRef = _firestore
          .collection(FirebaseConstants.leadsCollection)
          .doc(leadId)
          .collection('edit_history')
          .doc();

      final historyData = <String, dynamic>{
        'leadId': leadId,
        'editedBy': editedBy,
        'editedAt': FieldValue.serverTimestamp(),
        'changes': {},
      };

      if (editedByName != null) {
        historyData['editedByName'] = editedByName;
      }
      if (editedByEmail != null) {
        historyData['editedByEmail'] = editedByEmail;
      }

      // Convert changes to Firestore format
      final changesData = <String, Map<String, String?>>{};
      changes.forEach((field, change) {
        changesData[field] = {
          'old': change.oldValue,
          'new': change.newValue,
        };
      });
      historyData['changes'] = changesData;

      await docRef.set(historyData);
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to log edit history: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<List<LeadEditHistory>> getEditHistory(String leadId) async {
    try {
      final snapshot = await _firestore
          .collection(FirebaseConstants.leadsCollection)
          .doc(leadId)
          .collection('edit_history')
          .orderBy('editedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LeadEditHistoryModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw FirestoreFailure('Failed to get edit history: ${e.message ?? 'Unknown error'}');
    } catch (e) {
      if (e is Failure) rethrow;
      throw FirestoreFailure('Unexpected error: ${e.toString()}');
    }
  }
}

