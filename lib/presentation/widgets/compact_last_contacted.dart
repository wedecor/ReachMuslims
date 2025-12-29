import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/follow_up.dart';
import '../../core/utils/time_ago_helper.dart';
import '../providers/follow_up_provider.dart';

/// Compact last contacted indicator with clock icon
/// Returns null if no follow-ups exist (to hide the row)
class CompactLastContacted extends ConsumerWidget {
  final String leadId;

  const CompactLastContacted({
    super.key,
    required this.leadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUpState = ref.watch(followUpListProvider(leadId));

    // Hide if loading or no follow-ups
    if (followUpState.isLoading || followUpState.followUps.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get the most recent follow-up (already sorted by newest first)
    final latestFollowUp = followUpState.followUps.first;
    final timeAgo = TimeAgoHelper.formatTimeAgo(latestFollowUp.createdAt);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time,
          size: 12,
          color: Colors.grey[500],
        ),
        const SizedBox(width: 4),
        Text(
          timeAgo,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

