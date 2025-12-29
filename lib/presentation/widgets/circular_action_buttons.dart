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

/// Circular action buttons for Call and WhatsApp
class CircularActionButtons extends ConsumerWidget {
  final Lead lead;

  const CircularActionButtons({
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


  Future<void> _handleWhatsAppFollowUp(BuildContext context, WidgetRef ref) async {
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

    final service = ref.read(leadActionsServiceProvider);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(leadActionsServiceProvider);
    final isMobile = service.isMobilePlatform(context);
    final hasPhone = lead.phone.isNotEmpty;

    // Both buttons must always be visible if phone number exists
    if (!hasPhone) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Call button (green circular) - always visible if phone exists
        Tooltip(
          message: isMobile ? 'Call lead' : 'Call (mobile only)',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isMobile ? () => _handleCall(context, ref) : null,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isMobile ? Colors.green : Colors.grey[400],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // WhatsApp Follow-up button (WhatsApp-green circular) - always visible if phone exists
        Tooltip(
          message: 'WhatsApp Follow-up',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleWhatsAppFollowUp(context, ref),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366), // WhatsApp green
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'WA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

