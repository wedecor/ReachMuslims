import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
import '../../core/utils/status_color_utils.dart';
import '../providers/lead_list_provider.dart';

class StatusDropdown extends ConsumerWidget {
  final Lead lead;

  const StatusDropdown({
    super.key,
    required this.lead,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final currentStatus = lead.status;

      return SizedBox(
        width: 100,
        child: DropdownButton<LeadStatus>(
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
                  color: StatusColorUtils.getStatusColor(status),
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
        ),
      );
    } catch (e) {
      // Fallback to text if dropdown fails
      debugPrint('StatusDropdown error: $e');
      return Text(
        lead.status.displayName,
        style: TextStyle(
          fontSize: 12,
          color: StatusColorUtils.getStatusColor(lead.status),
          fontWeight: FontWeight.w500,
        ),
      );
    }
  }
}

