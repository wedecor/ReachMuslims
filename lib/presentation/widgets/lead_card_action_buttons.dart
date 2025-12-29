import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
import '../../domain/models/user.dart';
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

/// Large branded action buttons for Call and WhatsApp Follow-up
class LeadCardActionButtons extends ConsumerWidget {
  final Lead lead;

  const LeadCardActionButtons({
    super.key,
    required this.lead,
  });

  Future<void> _handleCall(BuildContext context, WidgetRef ref) async {
    final service = ref.read(leadActionsServiceProvider);
    final success = await service.callLead(lead, context);

    if (!success && context.mounted) {
      if (lead.phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No phone number available for this lead.'),
            backgroundColor: Colors.red,
          ),
        );
      } else if (!service.isMobilePlatform(context)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Call is available on mobile only.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open phone dialer.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (success && context.mounted) {
      ref.read(leadListProvider.notifier).refresh();
    }
  }

  Future<void> _handleWhatsApp(BuildContext context, WidgetRef ref) async {
    final service = ref.read(leadActionsServiceProvider);
    
    // Check if lead has never been contacted
    final hasNeverBeenContacted = lead.lastContactedAt == null;
    
    if (hasNeverBeenContacted) {
      // Initial contact: Use initial message template, do NOT log follow-up
      final success = await service.whatsappLead(lead, context);
      
      if (!success && context.mounted) {
        if (lead.phone.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No phone number available for this lead.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open WhatsApp.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else if (success && context.mounted) {
        ref.read(leadListProvider.notifier).refresh();
      }
    } else {
      // Follow-up: Use follow-up message template, log follow-up
      final authState = ref.read(authProvider);
      final user = authState.user;

      if (user == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not authenticated.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final success = await service.whatsappFollowUp(lead, context, user);

      if (!success && context.mounted) {
        if (lead.phone.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No phone number available for this lead.'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp opened, but failed to log follow-up.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (success && context.mounted) {
        ref.read(leadListProvider.notifier).refresh();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp follow-up logged successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(leadActionsServiceProvider);
    final isMobile = service.isMobilePlatform(context);
    final hasPhone = lead.phone.isNotEmpty;

    return Row(
      children: [
        // Left button: Call
        Expanded(
          child: ElevatedButton.icon(
            onPressed: hasPhone && isMobile ? () => _handleCall(context, ref) : null,
            icon: const Icon(Icons.phone, size: 20),
            label: const Text(
              'CALL',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Right button: WhatsApp (smart: initial or follow-up based on contact history)
        Expanded(
          child: ElevatedButton.icon(
            onPressed: hasPhone ? () => _handleWhatsApp(context, ref) : null,
            icon: const Icon(Icons.chat, size: 20),
            label: const Text(
              'WHATSAPP',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasPhone ? const Color(0xFF25D366) : Colors.grey[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}

