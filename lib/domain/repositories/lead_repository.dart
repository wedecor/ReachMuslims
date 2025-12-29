import '../models/lead.dart';
import '../models/user.dart';

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

  Future<void> updatePriority(String leadId, bool isPriority);
  Future<void> updateLastContactedAt(String leadId);
}

