import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/scheduled_followup_provider.dart';

/// Displays next scheduled follow-up reminder
class NextScheduledFollowUp extends ConsumerWidget {
  final String leadId;

  const NextScheduledFollowUp({
    super.key,
    required this.leadId,
  });

  String _formatScheduledTime(DateTime scheduledAt) {
    final now = DateTime.now();
    final difference = scheduledAt.difference(now);

    if (difference.inDays == 0) {
      if (difference.inHours > 0) {
        return 'Today ${DateFormat('h:mm a').format(scheduledAt)}';
      } else if (difference.inMinutes > 0) {
        return 'In ${difference.inMinutes} min';
      } else {
        return 'Now';
      }
    } else if (difference.inDays == 1) {
      return 'Tomorrow ${DateFormat('h:mm a').format(scheduledAt)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE h:mm a').format(scheduledAt);
    } else {
      return DateFormat('MMM d, h:mm a').format(scheduledAt);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledFollowUpState = ref.watch(scheduledFollowUpListProvider(leadId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (scheduledFollowUpState.isLoading) {
      return const SizedBox.shrink();
    }

    // Get next pending follow-up
    final now = DateTime.now();
    final nextFollowUp = scheduledFollowUpState.scheduledFollowUps
        .where((sf) => sf.status.name == 'pending' && sf.scheduledAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    if (nextFollowUp.isEmpty) {
      return const SizedBox.shrink();
    }

    final next = nextFollowUp.first;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.schedule,
          size: 12,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            _formatScheduledTime(next.scheduledAt),
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

