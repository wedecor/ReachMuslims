import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
import 'lead_card_action_buttons.dart';
import '../providers/auth_provider.dart';
import '../providers/lead_list_provider.dart';
import '../providers/connectivity_provider.dart';
import '../../core/services/lead_actions_service.dart';

/// Swipeable lead card with mobile swipe actions
/// - Swipe LEFT: WhatsApp
/// - Swipe RIGHT: Call
/// Only enabled on mobile platforms
class SwipeableLeadCard extends ConsumerStatefulWidget {
  final Lead lead;
  final Widget child;

  const SwipeableLeadCard({
    super.key,
    required this.lead,
    required this.child,
  });

  @override
  ConsumerState<SwipeableLeadCard> createState() => _SwipeableLeadCardState();
}

class _SwipeableLeadCardState extends ConsumerState<SwipeableLeadCard> {

  bool _isMobile() {
    return Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.android;
  }

  Future<void> _handleSwipeCall() async {
    final connectivityState = ref.read(connectivityProvider);
    final colorScheme = Theme.of(context).colorScheme;
    if (!connectivityState.isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Call unavailable offline'),
            backgroundColor: colorScheme.tertiaryContainer,
          ),
        );
      }
      return;
    }

    if (widget.lead.phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No phone number available'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
      return;
    }

    // Haptic feedback
    HapticFeedback.mediumImpact();

    final service = ref.read(leadActionsServiceProvider);
    final success = await service.callLead(widget.lead, context);

    if (success && mounted) {
      ref.read(leadListProvider.notifier).refresh();
    }
  }

  Future<void> _handleSwipeWhatsApp() async {
    final connectivityState = ref.read(connectivityProvider);
    final colorScheme = Theme.of(context).colorScheme;
    if (!connectivityState.isOnline) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('WhatsApp unavailable offline'),
            backgroundColor: colorScheme.tertiaryContainer,
          ),
        );
      }
      return;
    }

    if (widget.lead.phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No phone number available'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
      return;
    }

    // Haptic feedback
    HapticFeedback.mediumImpact();

    final service = ref.read(leadActionsServiceProvider);
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User not authenticated'),
            backgroundColor: colorScheme.error,
          ),
        );
      }
      return;
    }

    final hasNeverBeenContacted = widget.lead.lastContactedAt == null;
    
    if (hasNeverBeenContacted) {
      await service.whatsappLead(widget.lead, context);
    } else {
      await service.whatsappFollowUp(widget.lead, context, user);
    }

    if (mounted) {
      ref.read(leadListProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only enable swipe on mobile
    if (!_isMobile()) {
      return widget.child;
    }

    final hasPhone = widget.lead.phone.isNotEmpty;
    final isMobile = _isMobile();

    return Dismissible(
      key: Key('swipe_${widget.lead.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF25D366), // WhatsApp green
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.chat, color: Theme.of(context).colorScheme.onPrimary, size: 28),
            const SizedBox(width: 12),
            Text(
              'WhatsApp',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Call',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.phone, color: Theme.of(context).colorScheme.onPrimary, size: 28),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        // Prevent accidental swipes - require threshold
        if (direction == DismissDirection.startToEnd) {
          // Swipe right -> Call
          if (hasPhone && isMobile) {
            await _handleSwipeCall();
          }
        } else if (direction == DismissDirection.endToStart) {
          // Swipe left -> WhatsApp
          if (hasPhone) {
            await _handleSwipeWhatsApp();
          }
        }
        // Don't actually dismiss the card, just trigger action
        return false;
      },
      onDismissed: (direction) {
        // This won't be called since confirmDismiss returns false
        // But we handle actions in confirmDismiss
      },
      child: widget.child,
    );
  }
}

