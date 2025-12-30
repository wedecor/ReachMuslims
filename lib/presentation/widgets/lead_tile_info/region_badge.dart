import 'package:flutter/material.dart';
import '../../../domain/models/user.dart';
import '../../../domain/models/lead.dart';

/// Badge showing region (USA/INDIA) with flag emoji
class RegionBadge extends StatelessWidget {
  final Lead lead;

  const RegionBadge({
    super.key,
    required this.lead,
  });

  String _getRegionEmoji(UserRegion region) {
    switch (region) {
      case UserRegion.usa:
        return '🇺🇸';
      case UserRegion.india:
        return '🇮🇳';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Chip(
      avatar: Text(
        _getRegionEmoji(lead.region),
        style: const TextStyle(fontSize: 14),
      ),
      label: Text(
        lead.region.name.toUpperCase(),
        style: const TextStyle(fontSize: 11),
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
}

