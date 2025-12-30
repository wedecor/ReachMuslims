import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/time_ago_helper.dart';
import '../providers/lead_list_provider.dart';
import '../../domain/models/lead.dart';

/// Widget that displays when a lead was last contacted
/// Shows "Last contacted: X ago" or "Not contacted yet"
/// Uses lastContactedAt field from lead for accurate display
class LastContactedIndicator extends ConsumerWidget {
  final String leadId;

  const LastContactedIndicator({
    super.key,
    required this.leadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final leadListState = ref.watch(leadListProvider);
    
    // Find the lead in the list
    Lead? lead;
    try {
      lead = leadListState.leads.firstWhere((l) => l.id == leadId);
    } catch (_) {
      // Lead not found in list, show not contacted
      return Text(
        'Not contacted yet',
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    // Show "Not contacted yet" if lastContactedAt is null
    if (lead.lastContactedAt == null) {
      return Text(
        'Not contacted yet',
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final relativeTime = TimeAgoHelper.formatRelativeTime(lead.lastContactedAt);
    
    // Fallback if formatting fails
    if (relativeTime.isEmpty) {
      return Text(
        'Not contacted yet',
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          'Last contacted: $relativeTime',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

