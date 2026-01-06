import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/follow_up_provider.dart';
import '../../../domain/models/lead.dart';
import '../../../core/utils/time_ago_helper.dart';

/// Widget showing a preview of the most recent follow-up note
class NotesPreview extends ConsumerWidget {
  final String leadId;

  const NotesPreview({
    super.key,
    required this.leadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUpState = ref.watch(followUpListProvider(leadId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (followUpState.isLoading || followUpState.followUps.isEmpty) {
      return const SizedBox.shrink();
    }

    final lastFollowUp = followUpState.followUps.first;
    final preview = lastFollowUp.messagePreview ?? lastFollowUp.note;
    
    if (preview.isEmpty) {
      return const SizedBox.shrink();
    }

    // Truncate to 60 characters for preview
    final previewText = preview.length > 60 ? '${preview.substring(0, 60)}...' : preview;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.note_outlined,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                previewText,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                TimeAgoHelper.formatRelativeTime(lastFollowUp.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

