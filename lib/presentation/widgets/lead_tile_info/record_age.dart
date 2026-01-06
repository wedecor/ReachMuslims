import 'package:flutter/material.dart';
import '../../../domain/models/lead.dart';
import '../../../core/utils/time_ago_helper.dart';

/// Widget showing the age of the lead record with more detail
class RecordAge extends StatelessWidget {
  final Lead lead;

  const RecordAge({
    super.key,
    required this.lead,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final now = DateTime.now();
    final age = now.difference(lead.createdAt);
    final days = age.inDays;
    final months = (days / 30).floor();
    final years = (days / 365).floor();

    String ageText;
    if (years > 0) {
      ageText = '$years ${years == 1 ? 'year' : 'years'} old';
    } else if (months > 0) {
      ageText = '$months ${months == 1 ? 'month' : 'months'} old';
    } else if (days > 0) {
      ageText = '$days ${days == 1 ? 'day' : 'days'} old';
    } else {
      ageText = 'Created today';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.calendar_today_outlined,
          size: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          ageText,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

