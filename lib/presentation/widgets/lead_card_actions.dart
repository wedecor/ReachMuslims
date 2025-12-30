import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/follow_up_repository.dart';
import '../../core/services/lead_actions_service.dart';
import '../providers/auth_provider.dart';
import '../providers/lead_list_provider.dart';
import '../providers/follow_up_provider.dart';

final leadActionsServiceProvider = Provider<LeadActionsService>((ref) {
  return LeadActionsService(
    followUpRepository: ref.watch(followUpRepositoryProvider),
    leadRepository: ref.watch(leadRepositoryProvider),
  );
});

/// Compact action icons for lead cards (Call and WhatsApp)
/// Displays as icon buttons in the card's trailing area
class LeadCardActions extends ConsumerWidget {
  final Lead lead;

  const LeadCardActions({
    super.key,
    required this.lead,
  });

  Future<void> _handleCall(BuildContext context, WidgetRef ref) async {
    final service = ref.read(leadActionsServiceProvider);
    final success = await service.callLead(lead, context);

    if (!success && context.mounted) {
      final colorScheme = Theme.of(context).colorScheme;
      if (lead.phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No phone number available for this lead.'),
            backgroundColor: colorScheme.error,
          ),
        );
      } else if (!service.isMobilePlatform(context)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Call is available on mobile only.'),
            backgroundColor: colorScheme.tertiaryContainer,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to open phone dialer.'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    } else if (success && context.mounted) {
      // Refresh lead list to get updated lastContactedAt
      ref.read(leadListProvider.notifier).refresh();
    }
  }

  Future<void> _handleWhatsAppInitial(BuildContext context, WidgetRef ref) async {
    final service = ref.read(leadActionsServiceProvider);
    final success = await service.whatsappLead(lead, context);

    if (!success && context.mounted) {
      final colorScheme = Theme.of(context).colorScheme;
      if (lead.phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No phone number available for this lead.'),
            backgroundColor: colorScheme.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to open WhatsApp.'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
    } else if (success && context.mounted) {
      // Refresh lead list to get updated lastContactedAt
      ref.read(leadListProvider.notifier).refresh();
    }
  }

  Future<void> _handleWhatsAppFollowUp(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user == null) {
      if (context.mounted) {
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User not authenticated.'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
      return;
    }

    final service = ref.read(leadActionsServiceProvider);
    final success = await service.whatsappFollowUp(lead, context, user);

    if (!success && context.mounted) {
      final colorScheme = Theme.of(context).colorScheme;
      if (lead.phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No phone number available for this lead.'),
            backgroundColor: colorScheme.error,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('WhatsApp opened, but failed to log follow-up.'),
            backgroundColor: colorScheme.tertiaryContainer,
          ),
        );
      }
    } else if (success && context.mounted) {
      // Refresh lead list to get updated lastContactedAt and follow-ups
      ref.read(leadListProvider.notifier).refresh();
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('WhatsApp follow-up logged successfully.'),
          backgroundColor: colorScheme.primaryContainer,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(leadActionsServiceProvider);
    final isMobile = service.isMobilePlatform(context);
    final hasPhone = lead.phone.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Call button (mobile only)
        Tooltip(
          message: isMobile ? 'Call lead' : 'Call is available on mobile only',
          child: IconButton(
            icon: const Icon(Icons.phone),
            color: hasPhone && isMobile 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurfaceVariant,
            onPressed: hasPhone && isMobile ? () => _handleCall(context, ref) : null,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        const SizedBox(width: 4),
        // WhatsApp initial contact
        Tooltip(
          message: 'Open WhatsApp with initial message',
          child: IconButton(
            icon: const Icon(Icons.chat),
            color: hasPhone 
                ? Theme.of(context).colorScheme.primaryContainer 
                : Theme.of(context).colorScheme.onSurfaceVariant,
            onPressed: hasPhone ? () => _handleWhatsAppInitial(context, ref) : null,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        const SizedBox(width: 4),
        // WhatsApp follow-up (logs follow-up)
        Tooltip(
          message: 'Send WhatsApp follow-up and log it',
          child: IconButton(
            icon: const Icon(Icons.notes),
            color: hasPhone 
                ? Theme.of(context).colorScheme.primaryContainer 
                : Theme.of(context).colorScheme.onSurfaceVariant,
            onPressed: hasPhone ? () => _handleWhatsAppFollowUp(context, ref) : null,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }
}

