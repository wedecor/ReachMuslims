import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/lead_activity_provider.dart';
import '../../../domain/models/lead.dart';
import '../../../domain/models/lead_activity.dart';
import '../../../core/utils/time_ago_helper.dart';

/// Widget showing when the lead's status was last changed
class StatusChangeTime extends ConsumerWidget {
  final String leadId;
  final LeadStatus currentStatus;

  const StatusChangeTime({
    super.key,
    required this.leadId,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityState = ref.watch(leadActivityListProvider(leadId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (activityState.isLoading || activityState.activities.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find the most recent status change activity
    LeadActivity? lastStatusChange;
    for (final activity in activityState.activities) {
      if (activity.type == ActivityType.statusChanged) {
        final newStatus = activity.metadata['newStatus'] as String?;
        if (newStatus == currentStatus.name) {
          lastStatusChange = activity;
          break;
        }
      }
    }

    if (lastStatusChange == null) {
      return const SizedBox.shrink();
    }

    final timeAgo = TimeAgoHelper.formatRelativeTime(lastStatusChange.performedAt);
    final daysInStatus = DateTime.now().difference(lastStatusChange.performedAt).inDays;

    String displayText;
    if (daysInStatus == 0) {
      displayText = 'Status changed today';
    } else if (daysInStatus == 1) {
      displayText = 'In $currentStatus.displayName for 1 day';
    } else {
      displayText = 'In ${currentStatus.displayName} for $daysInStatus days';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.swap_horiz,
          size: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

