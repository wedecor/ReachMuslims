import 'package:flutter/material.dart';
import '../../../domain/models/lead.dart';

/// Badge showing lead source with icon
class LeadSourceBadge extends StatelessWidget {
  final Lead lead;

  const LeadSourceBadge({
    super.key,
    required this.lead,
  });

  IconData _getSourceIcon(LeadSource source) {
    switch (source) {
      case LeadSource.website:
        return Icons.language;
      case LeadSource.referral:
        return Icons.people;
      case LeadSource.socialMedia:
        return Icons.share;
      case LeadSource.whatsapp:
        return Icons.chat;
      case LeadSource.other:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Chip(
      avatar: Icon(
        _getSourceIcon(lead.source),
        size: 14,
        color: colorScheme.secondary,
      ),
      label: Text(
        lead.source.displayName,
        style: const TextStyle(fontSize: 11),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color: colorScheme.onSecondaryContainer,
        fontSize: 11,
      ),
    );
  }
}

