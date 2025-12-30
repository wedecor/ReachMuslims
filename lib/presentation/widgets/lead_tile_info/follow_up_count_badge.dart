import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/follow_up_provider.dart';

/// Badge showing follow-up count for a lead
class FollowUpCountBadge extends ConsumerWidget {
  final String leadId;

  const FollowUpCountBadge({
    super.key,
    required this.leadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use a future provider to avoid blocking the UI
    final followUpState = ref.watch(followUpListProvider(leadId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Don't show loading state - just hide until data is ready
    if (followUpState.isLoading) {
      return const SizedBox.shrink();
    }

    final count = followUpState.followUps.length;
    if (count == 0) {
      return const SizedBox.shrink();
    }

    return Chip(
      avatar: Icon(
        Icons.note_outlined,
        size: 14,
        color: colorScheme.tertiary,
      ),
      label: Text(
        '$count ${count == 1 ? 'follow-up' : 'follow-ups'}',
        style: const TextStyle(fontSize: 11),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: colorScheme.tertiaryContainer,
      labelStyle: TextStyle(
        color: colorScheme.onTertiaryContainer,
        fontSize: 11,
      ),
    );
  }
}

