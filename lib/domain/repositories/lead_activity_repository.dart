import '../models/lead_activity.dart';

abstract class LeadActivityRepository {
  /// Get all activities for a lead, ordered by most recent first
  Future<List<LeadActivity>> getActivities(String leadId);
  
  /// Stream activities for a lead in real-time
  Stream<List<LeadActivity>> streamActivities(String leadId);
  
  /// Create a new activity
  Future<LeadActivity> createActivity(LeadActivity activity);
  
  /// Create multiple activities in a batch (for efficiency)
  Future<void> createActivities(List<LeadActivity> activities);
}

