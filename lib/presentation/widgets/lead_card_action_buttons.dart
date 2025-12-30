import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
import '../../core/services/lead_actions_service.dart';
import '../providers/auth_provider.dart';
import '../providers/lead_list_provider.dart';
import '../providers/follow_up_provider.dart';
import '../providers/connectivity_provider.dart';

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
        final colorScheme = Theme.of(context).colorScheme;
        if (widget.lead.phone.isEmpty) {
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
          final colorScheme = Theme.of(context).colorScheme;
          if (widget.lead.phone.isEmpty) {
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
          ref.read(leadListProvider.notifier).refresh();
          // Show success feedback for initial WhatsApp
          final colorScheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('WhatsApp opened successfully.'),
              backgroundColor: colorScheme.primaryContainer,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Follow-up: Use follow-up message template, log follow-up
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

        final success = await service.whatsappFollowUp(widget.lead, context, user);

        if (!success && context.mounted) {
          final colorScheme = Theme.of(context).colorScheme;
          if (widget.lead.phone.isEmpty) {
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
    final connectivityState = ref.watch(connectivityProvider);
    final isMobile = service.isMobilePlatform(context);
    final hasPhone = widget.lead.phone.isNotEmpty;
    final isOffline = !connectivityState.isOnline;
    
    // Disable Call and WhatsApp when offline
    final isCallDisabled = !hasPhone || !isMobile || _isCallLoading || isOffline;
    final isWhatsAppDisabled = !hasPhone || _isWhatsAppLoading || isOffline;

    return Row(
      children: [
        // Left button: Call
        Expanded(
          child: Tooltip(
            message: isOffline ? 'Call unavailable offline' : 'Call lead',
            child: ElevatedButton.icon(
              onPressed: isCallDisabled ? null : () => _handleCall(context, ref),
              icon: _isCallLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                      ),
                    )
                  : Icon(
                      isOffline ? Icons.phone_disabled : Icons.phone,
                      size: 20,
                    ),
              label: Text(
                isOffline ? 'OFFLINE' : 'CALL',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.width < 600 ? 14 : 12,
              ),
              minimumSize: const Size(0, 44), // Minimum tap target
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Right button: WhatsApp (smart: initial or follow-up based on contact history)
        Expanded(
          child: Tooltip(
            message: isOffline ? 'WhatsApp unavailable offline' : 'Open WhatsApp',
            child: ElevatedButton.icon(
              onPressed: isWhatsAppDisabled ? null : () => _handleWhatsApp(context, ref),
              icon: _isWhatsAppLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                      ),
                    )
                  : Icon(
                      isOffline ? Icons.chat_bubble_outline : Icons.chat,
                      size: 20,
                    ),
              label: Text(
                isOffline ? 'OFFLINE' : 'WHATSAPP',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasPhone ? const Color(0xFF25D366) : Theme.of(context).colorScheme.onSurfaceVariant,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
              padding: EdgeInsets.symmetric(
                vertical: MediaQuery.of(context).size.width < 600 ? 14 : 12,
              ),
              minimumSize: const Size(0, 44), // Minimum tap target
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            ),
          ),
        ),
      ],
    );
  }
}

