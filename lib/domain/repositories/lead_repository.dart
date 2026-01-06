import '../models/lead.dart';
import '../models/user.dart';
import '../models/lead_edit_history.dart';

abstract class LeadRepository {
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
  });

  Future<Lead> createLead(Lead lead);
  Future<void> updateLeadStatus(String leadId, LeadStatus status);
  Future<Lead?> getLeadById(String leadId);
  Future<void> assignLead(String leadId, String? assignedTo, String? assignedToName);
  
  /// Check if a lead with the given phone number already exists
  /// Returns the existing lead if found, null otherwise
  /// Admin: checks all leads
  /// Sales: checks assigned + unassigned leads (read-only check)
  Future<Lead?> findDuplicateByPhone({
    required String phone,
    required String? userId,
    required bool isAdmin,
  });

  // Dashboard statistics
  Future<int> getTotalLeadsCount({
    required String? userId,
    required bool isAdmin,
    UserRegion? region,
  });

  Future<int> getLeadsCountByStatus({
    required String? userId,
    required bool isAdmin,
    required LeadStatus status,
    UserRegion? region,
  });

  Future<int> getLeadsCountByRegion({
    required String? userId,
    required bool isAdmin,
    required UserRegion region,
  });

  Future<int> getLeadsCreatedToday({
    required String? userId,
    required bool isAdmin,
    UserRegion? region,
  });

  Future<int> getLeadsCreatedThisWeek({
    required String? userId,
    required bool isAdmin,
    UserRegion? region,
  });

  Future<int> getPriorityLeadsCount({
    required String? userId,
    required bool isAdmin,
    UserRegion? region,
  });

  Future<int> getFollowUpLeadsCount({
    required String? userId,
    required bool isAdmin,
    UserRegion? region,
  });

  /// Get count of leads contacted today (lastContactedAt is today)
  /// Uses efficient query instead of fetching all leads
  Future<int> getLeadsContactedTodayCount({
    required String? userId,
    required bool isAdmin,
    UserRegion? region,
  });

  Future<void> updatePriority(String leadId, bool isPriority);
  Future<void> updateLastContactedAt(String leadId); // Deprecated - use updateLastPhoneContactedAt or updateLastWhatsAppContactedAt
  Future<void> updateLastPhoneContactedAt(String leadId);
  Future<void> updateLastWhatsAppContactedAt(String leadId);
  
  /// Update lead basic details (name, phone, location)
  /// Only updates the specified fields, preserves all other fields
  /// Permission checks: Admin can edit any lead, Sales can edit only assigned leads
  Future<void> updateLead({
    required String leadId,
    required String name,
    required String phone,
    String? location,
    required String? userId,
    required bool isAdmin,
  });

  /// Soft delete a lead (sets isDeleted = true)
  /// Only Admin can delete leads
  /// Does NOT physically delete the document or any related data
  Future<void> softDeleteLead({
    required String leadId,
    required String? userId,
    required bool isAdmin,
  });

  /// Log edit history for a lead
  /// Creates an entry in the edit_history subcollection
  Future<void> logEditHistory({
    required String leadId,
    required String editedBy,
    String? editedByName,
    String? editedByEmail,
    required Map<String, FieldChange> changes,
  });

  /// Get edit history for a lead
  /// Returns list of edit history entries, sorted by editedAt descending
  Future<List<LeadEditHistory>> getEditHistory(String leadId);
}

