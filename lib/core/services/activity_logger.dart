import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead_activity.dart';
import '../../domain/models/lead.dart';
import '../../domain/repositories/lead_activity_repository.dart';
import '../../presentation/providers/lead_activity_provider.dart';

/// Service for logging activities on leads
/// This provides a convenient way to log activities throughout the app
class ActivityLogger {
  final LeadActivityRepository _repository;

  ActivityLogger(this._repository);

  /// Log a lead creation activity
  Future<void> logLeadCreated({
    required String leadId,
    required String createdBy,
    String? createdByName,
    required Lead lead,
  }) async {
    await _repository.createActivity(LeadActivity(
      id: '', // Will be generated
      leadId: leadId,
      type: ActivityType.leadCreated,
      performedBy: createdBy,
      performedByName: createdByName,
      performedAt: DateTime.now(),
      metadata: {
        'leadName': lead.name,
        'leadPhone': lead.phone,
        'leadSource': lead.source.name,
        'leadRegion': lead.region.name,
      },
    ));
  }

  /// Log a status change activity
  Future<void> logStatusChanged({
    required String leadId,
    required String performedBy,
    String? performedByName,
    required String oldStatus,
    required String newStatus,
  }) async {
    await _repository.createActivity(LeadActivity(
      id: '',
      leadId: leadId,
      type: ActivityType.statusChanged,
      performedBy: performedBy,
      performedByName: performedByName,
      performedAt: DateTime.now(),
      metadata: {
        'oldStatus': oldStatus,
        'newStatus': newStatus,
      },
    ));
  }

  /// Log a lead assignment activity
  Future<void> logAssigned({
    required String leadId,
    required String performedBy,
    String? performedByName,
    required String assignedTo,
    String? assignedToName,
  }) async {
    await _repository.createActivity(LeadActivity(
      id: '',
      leadId: leadId,
      type: ActivityType.assigned,
      performedBy: performedBy,
      performedByName: performedByName,
      performedAt: DateTime.now(),
      metadata: {
        'assignedTo': assignedTo,
        'assignedToName': assignedToName,
      },
    ));
  }

  /// Log a lead reassignment activity
  Future<void> logReassigned({
    required String leadId,
    required String performedBy,
    String? performedByName,
    String? oldAssignee,
    String? oldAssigneeName,
    required String newAssignee,
    String? newAssigneeName,
  }) async {
    await _repository.createActivity(LeadActivity(
      id: '',
      leadId: leadId,
      type: ActivityType.reassigned,
      performedBy: performedBy,
      performedByName: performedByName,
      performedAt: DateTime.now(),
      metadata: {
        'oldAssignee': oldAssignee,
        'oldAssigneeName': oldAssigneeName,
        'newAssignee': newAssignee,
        'newAssigneeName': newAssigneeName,
      },
    ));
  }

  /// Log a lead unassignment activity
  Future<void> logUnassigned({
    required String leadId,
    required String performedBy,
    String? performedByName,
    String? oldAssignee,
    String? oldAssigneeName,
  }) async {
    await _repository.createActivity(LeadActivity(
      id: '',
      leadId: leadId,
      type: ActivityType.unassigned,
      performedBy: performedBy,
      performedByName: performedByName,
      performedAt: DateTime.now(),
      metadata: {
        'oldAssignee': oldAssignee,
        'oldAssigneeName': oldAssigneeName,
      },
    ));
  }

  /// Log a priority change activity
  Future<void> logPriorityChanged({
    required String leadId,
    required String performedBy,
    String? performedByName,
    required bool isPriority,
  }) async {
    await _repository.createActivity(LeadActivity(
      id: '',
      leadId: leadId,
      type: ActivityType.priorityChanged,
      performedBy: performedBy,
      performedByName: performedByName,
      performedAt: DateTime.now(),
      metadata: {
        'isPriority': isPriority,
      },
    ));
  }

  /// Log a follow-up added activity
  Future<void> logFollowUpAdded({
    required String leadId,
    required String performedBy,
    String? performedByName,
    String? note,
  }) async {
    await _repository.createActivity(LeadActivity(
      id: '',
      leadId: leadId,
      type: ActivityType.followUpAdded,
      performedBy: performedBy,
      performedByName: performedByName,
      performedAt: DateTime.now(),
      metadata: {
        if (note != null) 'note': note,
      },
    ));
  }

  /// Log a follow-up scheduled activity
  Future<void> logFollowUpScheduled({
    required String leadId,
    required String performedBy,
    String? performedByName,
    required DateTime scheduledDate,
  }) async {
    await _repository.createActivity(LeadActivity(
      id: '',
      leadId: leadId,
      type: ActivityType.followUpScheduled,
      performedBy: performedBy,
      performedByName: performedByName,
      performedAt: DateTime.now(),
      metadata: {
        'scheduledDate': scheduledDate.toIso8601String(),
      },
    ));
  }

  /// Log a field edit activity
  Future<void> logFieldEdited({
    required String leadId,
    required String performedBy,
    String? performedByName,
    required String fieldName,
    String? oldValue,
    String? newValue,
  }) async {
    await _repository.createActivity(LeadActivity(
      id: '',
      leadId: leadId,
      type: ActivityType.fieldEdited,
      performedBy: performedBy,
      performedByName: performedByName,
      performedAt: DateTime.now(),
      metadata: {
        'fieldName': fieldName,
        'oldValue': oldValue,
        'newValue': newValue,
      },
    ));
  }
}

/// Provider for ActivityLogger
final activityLoggerProvider = Provider<ActivityLogger>((ref) {
  final repository = ref.watch(leadActivityRepositoryProvider);
  return ActivityLogger(repository);
});

