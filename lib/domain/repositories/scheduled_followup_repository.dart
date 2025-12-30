import '../models/scheduled_followup.dart';

abstract class ScheduledFollowUpRepository {
  /// Create a new scheduled follow-up
  Future<ScheduledFollowUp> createScheduledFollowUp({
    required String leadId,
    required DateTime scheduledAt,
    String? note,
    required String createdBy,
  });

  /// Get all scheduled follow-ups for a specific lead
  Future<List<ScheduledFollowUp>> getScheduledFollowUpsForLead(String leadId);

  /// Get all pending scheduled follow-ups for a user
  Future<List<ScheduledFollowUp>> getPendingFollowUpsForUser(String userId);

  /// Get all scheduled follow-ups (pending, completed, missed) for a user
  Future<List<ScheduledFollowUp>> getAllFollowUpsForUser(String userId);

  /// Mark a scheduled follow-up as completed
  Future<void> markAsCompleted(String scheduledFollowUpId);

  /// Mark a scheduled follow-up as missed
  Future<void> markAsMissed(String scheduledFollowUpId);

  /// Delete a scheduled follow-up
  Future<void> deleteScheduledFollowUp(String scheduledFollowUpId);

  /// Get a scheduled follow-up by ID
  Future<ScheduledFollowUp?> getScheduledFollowUpById(String scheduledFollowUpId);
}

