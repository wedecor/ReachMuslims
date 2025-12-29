import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
import '../providers/lead_list_provider.dart';

class StatusDropdown extends ConsumerWidget {
  final Lead lead;

  const StatusDropdown({
    super.key,
    required this.lead,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStatus = lead.status;

    return DropdownButton<LeadStatus>(
      value: currentStatus,
      isExpanded: true,
      underline: const SizedBox.shrink(),
      items: LeadStatus.values.map((status) {
        return DropdownMenuItem<LeadStatus>(
          value: status,
          child: Text(
            status.displayName,
            style: TextStyle(
              fontSize: 12,
              color: _getStatusColor(status),
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      onChanged: (LeadStatus? newStatus) {
        if (newStatus != null && newStatus != currentStatus) {
          ref.read(leadListProvider.notifier).updateStatus(lead.id, newStatus);
        }
      },
    );
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return Colors.blue;
      case LeadStatus.inTalk:
        return Colors.orange;
      case LeadStatus.notInterested:
        return Colors.red;
      case LeadStatus.converted:
        return Colors.green;
    }
  }
}

