import 'package:flutter/material.dart';
import '../../../domain/models/lead.dart';

/// Badge showing gender (Male/Female) with icon
class GenderBadge extends StatelessWidget {
  final Lead lead;

  const GenderBadge({
    super.key,
    required this.lead,
  });

  IconData _getGenderIcon(LeadGender gender) {
    switch (gender) {
      case LeadGender.male:
        return Icons.male;
      case LeadGender.female:
        return Icons.female;
      case LeadGender.unknown:
        return Icons.help_outline;
    }
  }

  Color _getGenderColor(BuildContext context, LeadGender gender) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (gender) {
      case LeadGender.male:
        return colorScheme.primaryContainer;
      case LeadGender.female:
        return colorScheme.secondaryContainer;
      case LeadGender.unknown:
        return colorScheme.errorContainer;
    }
  }

  Color _getGenderIconColor(BuildContext context, LeadGender gender) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (gender) {
      case LeadGender.male:
        return colorScheme.onPrimaryContainer;
      case LeadGender.female:
        return colorScheme.onSecondaryContainer;
      case LeadGender.unknown:
        return colorScheme.onErrorContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Chip(
      avatar: Icon(
        _getGenderIcon(lead.gender),
        size: 16,
        color: _getGenderIconColor(context, lead.gender),
      ),
      label: Text(
        lead.gender.displayName,
        style: TextStyle(
          fontSize: 11,
          color: _getGenderIconColor(context, lead.gender),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: _getGenderColor(context, lead.gender),
    );
  }
}

