import 'package:flutter/material.dart';
import '../../../domain/models/lead.dart';
import '../../../core/utils/time_ago_helper.dart';

/// Widget showing last contacted time separately for Phone and WhatsApp
class LastContactedByMethod extends StatelessWidget {
  final Lead lead;

  const LastContactedByMethod({
    super.key,
    required this.lead,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasPhone = lead.lastPhoneContactedAt != null;
    final hasWhatsApp = lead.lastWhatsAppContactedAt != null;

    // Fallback to old lastContactedAt if new fields don't exist
    final fallbackLastContacted = !hasPhone && !hasWhatsApp ? lead.lastContactedAt : null;

    if (!hasPhone && !hasWhatsApp && fallbackLastContacted == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasPhone)
          _buildContactMethod(
            context,
            icon: Icons.phone_outlined,
            label: 'Phone',
            time: lead.lastPhoneContactedAt!,
            colorScheme: colorScheme,
          ),
        if (hasPhone && hasWhatsApp) const SizedBox(height: 4),
        if (hasWhatsApp)
          _buildContactMethod(
            context,
            icon: Icons.chat_bubble_outline,
            label: 'WhatsApp',
            time: lead.lastWhatsAppContactedAt!,
            colorScheme: colorScheme,
          ),
        if (fallbackLastContacted != null && !hasPhone && !hasWhatsApp)
          _buildContactMethod(
            context,
            icon: Icons.phone_outlined,
            label: 'Contacted',
            time: fallbackLastContacted,
            colorScheme: colorScheme,
          ),
      ],
    );
  }

  Widget _buildContactMethod(
    BuildContext context, {
    required IconData icon,
    required String label,
    required DateTime time,
    required ColorScheme colorScheme,
  }) {
    final timeAgo = TimeAgoHelper.formatRelativeTime(time);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          '$label: $timeAgo',
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

