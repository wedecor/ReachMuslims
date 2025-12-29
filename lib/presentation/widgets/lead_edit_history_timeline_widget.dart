import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead_edit_history.dart';
import '../../core/utils/time_ago_helper.dart';
import '../providers/lead_edit_history_provider.dart';

/// Read-only timeline widget showing lead edit history
class LeadEditHistoryTimelineWidget extends ConsumerWidget {
  final String leadId;

  const LeadEditHistoryTimelineWidget({
    super.key,
    required this.leadId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyState = ref.watch(leadEditHistoryProvider(leadId));

    if (historyState.isLoading && historyState.history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (historyState.error != null && historyState.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[300],
            ),
            const SizedBox(height: 8),
            Text(
              'Error loading edit history: ${historyState.error!.message}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (historyState.history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_note,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No edit history yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: historyState.history.length,
      itemBuilder: (context, index) {
        final history = historyState.history[index];
        return _buildTimelineItem(context, history);
      },
    );
  }

  Widget _buildTimelineItem(BuildContext context, LeadEditHistory history) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Edit icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 18,
                    color: Colors.purple[700],
                  ),
                ),
                const SizedBox(width: 8),
                // Edit label
                Text(
                  'Data Edited',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                // Date & time
                Text(
                  TimeAgoHelper.formatTimelineDate(history.editedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            // Changes
            ...history.changes.entries.map((entry) {
              final field = entry.key;
              final change = entry.value;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildChangeItem(context, field, change),
              );
            }),
            // Editor info
            if (history.editedByName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Edited by ${history.editedByName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
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

  Widget _buildChangeItem(
    BuildContext context,
    String field,
    FieldChange change,
  ) {
    final fieldName = _getFieldDisplayName(field);
    final oldValue = change.oldValue ?? '(empty)';
    final newValue = change.newValue ?? '(empty)';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fieldName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Old:',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      oldValue,
                      style: const TextStyle(
                        fontSize: 12,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New:',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      newValue,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFieldDisplayName(String field) {
    switch (field) {
      case 'name':
        return 'Name';
      case 'phone':
        return 'Phone';
      case 'location':
        return 'Location';
      default:
        return field;
    }
  }
}

