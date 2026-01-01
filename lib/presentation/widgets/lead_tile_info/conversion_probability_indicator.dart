import 'package:flutter/material.dart';
import '../../../domain/models/lead.dart';
import '../../../core/utils/status_color_utils.dart';

/// Visual indicator showing conversion probability based on status
class ConversionProbabilityIndicator extends StatelessWidget {
  final Lead lead;

  const ConversionProbabilityIndicator({
    super.key,
    required this.lead,
  });

  double _getProgress(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return 0.25;
      case LeadStatus.followUp:
        return 0.40;
      case LeadStatus.inTalk:
        return 0.60;
      case LeadStatus.notInterested:
        return 0.0;
      case LeadStatus.converted:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress = _getProgress(lead.status);
    final color = StatusColorUtils.getStatusColor(lead.status);

    if (lead.status == LeadStatus.converted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            'Converted',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          height: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${(progress * 100).toInt()}%',
          style: TextStyle(
            fontSize: 10,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

