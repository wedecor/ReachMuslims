import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/follow_up_provider.dart';
import '../../../domain/models/lead.dart';

/// Shows last activity summary (e.g., "Last: WhatsApp 2h ago")
class LastActivitySummary extends ConsumerWidget {
  final Lead lead;

  const LastActivitySummary({
    super.key,
    required this.lead,
  });

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUpState = ref.watch(followUpListProvider(lead.id));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get last follow-up
    if (followUpState.isLoading || followUpState.followUps.isEmpty) {
      // Fallback to lastContactedAt if available
      if (lead.lastContactedAt != null) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.phone_outlined,
              size: 12,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Last: ${_formatTimeAgo(lead.lastContactedAt!)}',
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      }
      return const SizedBox.shrink();
    }

    final lastFollowUp = followUpState.followUps.first;
    final activityType = lastFollowUp.type ?? 'note';
    IconData icon;
    String label;

    switch (activityType.toLowerCase()) {
      case 'whatsapp':
        icon = Icons.chat;
        label = 'WhatsApp';
        break;
      case 'call':
        icon = Icons.phone;
        label = 'Call';
        break;
      default:
        icon = Icons.note;
        label = 'Note';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'Last: $label ${_formatTimeAgo(lastFollowUp.createdAt)}',
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

