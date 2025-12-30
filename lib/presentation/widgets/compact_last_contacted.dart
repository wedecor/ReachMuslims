import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/time_ago_helper.dart';
import '../providers/lead_list_provider.dart';
import '../../domain/models/lead.dart';

/// Compact last contacted indicator with clock icon
/// Uses lastContactedAt field from lead for accurate display
class CompactLastContacted extends ConsumerWidget {
  final String leadId;

  const CompactLastContacted({
    super.key,
    required this.leadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadListState = ref.watch(leadListProvider);
    
    // Find the lead in the list
    Lead? lead;
    try {
      lead = leadListState.leads.firstWhere((l) => l.id == leadId);
    } catch (_) {
      // Lead not found in list, hide indicator
      return const SizedBox.shrink();
    }

    // Hide if lastContactedAt is null
    if (lead.lastContactedAt == null) {
      return const SizedBox.shrink();
    }

    final relativeTime = TimeAgoHelper.formatRelativeTime(lead.lastContactedAt);
    
    // Hide if formatting returned empty string
    if (relativeTime.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time,
          size: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          relativeTime,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

