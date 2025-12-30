import 'package:flutter/material.dart';
import '../../../domain/models/lead.dart';

/// Badge showing assigned user or "Unassigned"
class AssignedUserBadge extends StatelessWidget {
  final Lead lead;

  const AssignedUserBadge({
    super.key,
    required this.lead,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (lead.assignedToName == null || lead.assignedToName!.isEmpty) {
      return Chip(
        label: const Text(
          'Unassigned',
          style: TextStyle(fontSize: 11),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 11,
        ),
      );
    }

    return Chip(
      avatar: Icon(
        Icons.person_outline,
        size: 14,
        color: colorScheme.primary,
      ),
      label: Text(
        lead.assignedToName!,
        style: const TextStyle(fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: colorScheme.onPrimaryContainer,
        fontSize: 11,
      ),
    );
  }
}

