import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/follow_up.dart';
import '../../core/utils/time_ago_helper.dart';
import '../providers/follow_up_provider.dart';

/// Read-only timeline widget showing follow-up history
class FollowUpTimelineWidget extends ConsumerWidget {
  final String leadId;

  const FollowUpTimelineWidget({
    super.key,
    required this.leadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUpState = ref.watch(followUpListProvider(leadId));

    if (followUpState.isLoading && followUpState.followUps.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (followUpState.error != null && followUpState.followUps.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading follow-ups: ${followUpState.error!.message}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (followUpState.followUps.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'No follow-ups yet',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: followUpState.followUps.length,
      itemBuilder: (context, index) {
        final followUp = followUpState.followUps[index];
        return _buildTimelineItem(context, followUp, index == 0);
      },
    );
  }

  Widget _buildTimelineItem(BuildContext context, FollowUp followUp, bool isFirst) {
    final isWhatsApp = followUp.type == 'whatsapp';
    final preview = followUp.messagePreview ?? followUp.note;
    final previewText = preview.length > 50 ? '${preview.substring(0, 50)}...' : preview;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Contact type icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isWhatsApp 
                        ? Theme.of(context).colorScheme.primaryContainer 
                        : Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isWhatsApp ? Icons.chat : Icons.note,
                    size: 18,
                    color: isWhatsApp 
                        ? Theme.of(context).colorScheme.onPrimaryContainer 
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                // Contact type label
                Text(
                  isWhatsApp ? 'WhatsApp' : 'Note',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isWhatsApp 
                        ? Theme.of(context).colorScheme.onPrimaryContainer 
                        : Theme.of(context).colorScheme.onSecondaryContainer,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                // Date & time
                Text(
                  TimeAgoHelper.formatTimelineDate(followUp.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (previewText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                previewText,
                style: const TextStyle(fontSize: 13),
              ),
            ],
            if (followUp.createdByName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Contacted by ${followUp.createdByName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

