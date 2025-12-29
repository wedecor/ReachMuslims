import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
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
class LeadCardActionButtons extends ConsumerStatefulWidget {
  final Lead lead;

  const LeadCardActionButtons({
    super.key,
    required this.lead,
  });

  @override
  ConsumerState<LeadCardActionButtons> createState() => _LeadCardActionButtonsState();
}

class _LeadCardActionButtonsState extends ConsumerState<LeadCardActionButtons> {
  bool _isCallLoading = false;
  bool _isWhatsAppLoading = false;

  Future<void> _handleCall(BuildContext context, WidgetRef ref) async {
    if (_isCallLoading) return; // Prevent rapid taps

    setState(() {
      _isCallLoading = true;
    });

    try {
      final service = ref.read(leadActionsServiceProvider);
      final success = await service.callLead(widget.lead, context);

      if (!success && context.mounted) {
        if (widget.lead.phone.isEmpty) {
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
    } finally {
      if (mounted) {
        setState(() {
          _isCallLoading = false;
        });
      }
    }
  }

  Future<void> _handleWhatsApp(BuildContext context, WidgetRef ref) async {
    if (_isWhatsAppLoading) return; // Prevent rapid taps

    setState(() {
      _isWhatsAppLoading = true;
    });

    try {
      final service = ref.read(leadActionsServiceProvider);
      
      // Check if lead has never been contacted
      final hasNeverBeenContacted = widget.lead.lastContactedAt == null;
      
      if (hasNeverBeenContacted) {
        // Initial contact: Use initial message template, do NOT log follow-up
        final success = await service.whatsappLead(widget.lead, context);
        
        if (!success && context.mounted) {
          if (widget.lead.phone.isEmpty) {
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
          // Show success feedback for initial WhatsApp
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp opened successfully.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
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

        final success = await service.whatsappFollowUp(widget.lead, context, user);

        if (!success && context.mounted) {
          if (widget.lead.phone.isEmpty) {
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
    } finally {
      if (mounted) {
        setState(() {
          _isWhatsAppLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.read(leadActionsServiceProvider);
    final isMobile = service.isMobilePlatform(context);
    final hasPhone = widget.lead.phone.isNotEmpty;
    final isCallDisabled = !hasPhone || !isMobile || _isCallLoading;
    final isWhatsAppDisabled = !hasPhone || _isWhatsAppLoading;

    return Row(
      children: [
        // Left button: Call
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isCallDisabled ? null : () => _handleCall(context, ref),
            icon: _isCallLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.phone, size: 20),
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
            onPressed: isWhatsAppDisabled ? null : () => _handleWhatsApp(context, ref),
            icon: _isWhatsAppLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.chat, size: 20),
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

