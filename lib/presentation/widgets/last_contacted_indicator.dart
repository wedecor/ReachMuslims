import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/follow_up.dart';
import '../../core/utils/time_ago_helper.dart';
import '../providers/follow_up_provider.dart';

/// Widget that displays when a lead was last contacted
/// Shows "Last contacted: X ago" or "Not contacted yet"
class LastContactedIndicator extends ConsumerWidget {
  final String leadId;

  const LastContactedIndicator({
    super.key,
    required this.leadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUpState = ref.watch(followUpListProvider(leadId));

    if (followUpState.isLoading || followUpState.followUps.isEmpty) {
      return Text(
        'Not contacted yet',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Get the most recent follow-up (already sorted by newest first)
    final latestFollowUp = followUpState.followUps.first;
    final timeAgo = TimeAgoHelper.formatTimeAgo(latestFollowUp.createdAt);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          'Last contacted: $timeAgo',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

