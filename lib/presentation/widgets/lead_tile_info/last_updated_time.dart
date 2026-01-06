import 'package:flutter/material.dart';
import '../../../domain/models/lead.dart';
import '../../../core/utils/time_ago_helper.dart';

/// Widget showing when the lead was last updated
class LastUpdatedTime extends StatelessWidget {
  final Lead lead;

  const LastUpdatedTime({
    super.key,
    required this.lead,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final timeAgo = TimeAgoHelper.formatRelativeTime(lead.updatedAt);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.update_outlined,
          size: 12,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          'Updated $timeAgo',
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

