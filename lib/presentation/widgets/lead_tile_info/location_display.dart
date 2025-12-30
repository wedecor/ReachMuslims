import 'package:flutter/material.dart';
import '../../../domain/models/lead.dart';

/// Displays location if available
class LocationDisplay extends StatelessWidget {
  final Lead lead;

  const LocationDisplay({
    super.key,
    required this.lead,
  });

  @override
  Widget build(BuildContext context) {
    if (lead.location == null || lead.location!.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on_outlined,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            lead.location!,
            style: TextStyle(
              fontSize: 12,
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

