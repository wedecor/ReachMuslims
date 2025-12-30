import 'package:flutter/material.dart';
import '../../domain/models/lead.dart';
import '../../core/utils/status_color_utils.dart';

/// Status badge widget showing lead status as a colored chip.
/// Uses centralized color mapping from StatusColorUtils.
class StatusBadge extends StatelessWidget {
  final LeadStatus status;

  const StatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: StatusColorUtils.getStatusBackgroundColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: StatusColorUtils.getStatusTextColor(status),
        ),
      ),
    );
  }
}

