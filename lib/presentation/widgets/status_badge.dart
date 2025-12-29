import 'package:flutter/material.dart';
import '../../domain/models/lead.dart';

/// Status badge widget showing lead status as a colored chip
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
        color: _getStatusBackgroundColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getStatusTextColor(status),
        ),
      ),
    );
  }

  Color _getStatusBackgroundColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return Colors.blue[50]!;
      case LeadStatus.inTalk:
        return Colors.orange[50]!;
      case LeadStatus.notInterested:
        return Colors.red[50]!;
      case LeadStatus.converted:
        return Colors.green[50]!;
    }
  }

  Color _getStatusTextColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return Colors.blue[700]!;
      case LeadStatus.inTalk:
        return Colors.orange[700]!;
      case LeadStatus.notInterested:
        return Colors.red[700]!;
      case LeadStatus.converted:
        return Colors.green[700]!;
    }
  }
}

