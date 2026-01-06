import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/lead_activity.dart';
import '../../domain/models/lead.dart';
import '../providers/lead_activity_provider.dart';
import '../../core/utils/time_ago_helper.dart';
import '../../core/utils/status_color_utils.dart';

/// Beautiful timeline widget showing all activities for a lead
class LeadActivityTimelineWidget extends ConsumerWidget {
  final String leadId;

  const LeadActivityTimelineWidget({
    super.key,
    required this.leadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityState = ref.watch(leadActivityListProvider(leadId));

    if (activityState.isLoading && activityState.activities.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (activityState.error != null && activityState.activities.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading activity: ${activityState.error!.message}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(leadActivityListProvider(leadId).notifier).refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (activityState.activities.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'No activity yet',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Activity timeline will appear here',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group activities by date
    final groupedActivities = _groupByDate(activityState.activities);

    return RefreshIndicator(
      onRefresh: () => ref.read(leadActivityListProvider(leadId).notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: groupedActivities.length,
        itemBuilder: (context, index) {
          final dateGroup = groupedActivities[index];
          return _buildDateGroup(context, dateGroup.date, dateGroup.activities);
        },
      ),
    );
  }

  Widget _buildDateGroup(BuildContext context, DateTime date, List<LeadActivity> activities) {
    final theme = Theme.of(context);
    final isToday = _isToday(date);
    final isYesterday = _isYesterday(date);
    
    String dateLabel;
    if (isToday) {
      dateLabel = 'Today';
    } else if (isYesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('MMM dd, yyyy').format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 2,
                height: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                dateLabel,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        ...activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          final isLast = index == activities.length - 1;
          return _buildTimelineItem(context, activity, isLast);
        }),
      ],
    );
  }

  Widget _buildTimelineItem(BuildContext context, LeadActivity activity, bool isLast) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and icon
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getActivityColor(activity.type, colorScheme).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getActivityColor(activity.type, colorScheme),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getActivityIcon(activity.type),
                  size: 20,
                  color: _getActivityColor(activity.type, colorScheme),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: colorScheme.outline.withOpacity(0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Activity content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activity.displayTitle,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _getActivityColor(activity.type, colorScheme),
                                  ),
                                ),
                              ),
                              Text(
                                TimeAgoHelper.formatTimelineDate(activity.performedAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Description
                          Text(
                            activity.displayDescription,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          // Additional details based on type
                          if (activity.type == ActivityType.statusChanged) ...[
                            const SizedBox(height: 8),
                            _buildStatusChangeDetails(context, activity),
                          ] else if (activity.type == ActivityType.fieldEdited) ...[
                            const SizedBox(height: 8),
                            _buildFieldEditDetails(context, activity),
                          ],
                          // Performed by
                          if (activity.performedByName != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  activity.performedByName!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChangeDetails(BuildContext context, LeadActivity activity) {
    final theme = Theme.of(context);
    final oldStatusStr = activity.metadata['oldStatus'] as String?;
    final newStatusStr = activity.metadata['newStatus'] as String?;
    
    if (oldStatusStr == null || newStatusStr == null) return const SizedBox.shrink();

    // Parse status strings to LeadStatus enum for colors
    LeadStatus? oldStatus, newStatus;
    try {
      oldStatus = LeadStatus.values.firstWhere(
        (s) => s.name == oldStatusStr,
      );
      newStatus = LeadStatus.values.firstWhere(
        (s) => s.name == newStatusStr,
      );
    } catch (e) {
      // If parsing fails, just show text
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'From: $oldStatusStr',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'To: $newStatusStr',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: StatusColorUtils.getStatusBackgroundColor(oldStatus),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                oldStatus.displayName,
                style: TextStyle(
                  color: StatusColorUtils.getStatusTextColor(oldStatus),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: StatusColorUtils.getStatusBackgroundColor(newStatus),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                newStatus.displayName,
                style: TextStyle(
                  color: StatusColorUtils.getStatusTextColor(newStatus),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldEditDetails(BuildContext context, LeadActivity activity) {
    final theme = Theme.of(context);
    final fieldName = activity.metadata['fieldName'] as String? ?? 'Field';
    final oldValue = activity.metadata['oldValue'] as String?;
    final newValue = activity.metadata['newValue'] as String?;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fieldName,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (oldValue != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'From: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Text(
                    oldValue.isEmpty ? '(empty)' : oldValue,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      decoration: TextDecoration.lineThrough,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (newValue != null) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  'To: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Text(
                    newValue.isEmpty ? '(empty)' : newValue,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getActivityColor(ActivityType type, ColorScheme colorScheme) {
    switch (type) {
      case ActivityType.leadCreated:
        return Colors.green;
      case ActivityType.statusChanged:
        return colorScheme.primary;
      case ActivityType.assigned:
      case ActivityType.reassigned:
        return Colors.blue;
      case ActivityType.unassigned:
        return Colors.orange;
      case ActivityType.priorityChanged:
        return Colors.amber;
      case ActivityType.followUpAdded:
      case ActivityType.followUpScheduled:
        return Colors.purple;
      case ActivityType.fieldEdited:
        return Colors.teal;
      case ActivityType.leadDeleted:
        return Colors.red;
      case ActivityType.leadRestored:
        return Colors.green;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.leadCreated:
        return Icons.add_circle_outline;
      case ActivityType.statusChanged:
        return Icons.swap_horiz;
      case ActivityType.assigned:
      case ActivityType.reassigned:
        return Icons.person_add;
      case ActivityType.unassigned:
        return Icons.person_remove;
      case ActivityType.priorityChanged:
        return Icons.star;
      case ActivityType.followUpAdded:
        return Icons.note_add;
      case ActivityType.followUpScheduled:
        return Icons.schedule;
      case ActivityType.fieldEdited:
        return Icons.edit;
      case ActivityType.leadDeleted:
        return Icons.delete;
      case ActivityType.leadRestored:
        return Icons.restore;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  List<DateGroup> _groupByDate(List<LeadActivity> activities) {
    final Map<String, List<LeadActivity>> grouped = {};

    for (final activity in activities) {
      final dateKey = DateFormat('yyyy-MM-dd').format(activity.performedAt);
      grouped.putIfAbsent(dateKey, () => []).add(activity);
    }

    return grouped.entries.map((entry) {
      final date = DateFormat('yyyy-MM-dd').parse(entry.key);
      return DateGroup(date: date, activities: entry.value);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first
  }
}

class DateGroup {
  final DateTime date;
  final List<LeadActivity> activities;

  DateGroup({
    required this.date,
    required this.activities,
  });
}

