import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/lead.dart';
import '../providers/lead_list_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/services/lead_actions_service.dart';
import 'lead_card_action_buttons.dart';

/// Keyboard shortcuts handler for web platform
/// Shortcuts:
/// - C: Call selected lead
/// - W: WhatsApp selected lead
/// - S: Toggle star (priority)
/// - /: Focus search bar
/// - Esc: Clear filters / exit dialogs
class KeyboardShortcutsHandler extends ConsumerWidget {
  final Widget child;
  final Lead? selectedLead;
  final FocusNode? searchFocusNode;
  final VoidCallback? onClearFilters;
  final VoidCallback? onDismissDialog;

  const KeyboardShortcutsHandler({
    super.key,
    required this.child,
    this.selectedLead,
    this.searchFocusNode,
    this.onClearFilters,
    this.onDismissDialog,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only enable on web
    if (!kIsWeb) {
      return child;
    }

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          _handleKeyPress(context, ref, event);
        }
      },
      child: child,
    );
  }

  void _handleKeyPress(BuildContext context, WidgetRef ref, KeyDownEvent event) {
    // Don't trigger shortcuts when typing in text fields
    final focusNode = FocusScope.of(context).focusedChild;
    if (focusNode != null) {
      // Check if focus is on a text field
      if (focusNode.context?.widget is TextField ||
          focusNode.context?.widget is TextFormField) {
        return;
      }
    }

    // Check for modifier keys - we want single key shortcuts
    if (event.logicalKey == LogicalKeyboardKey.metaLeft ||
        event.logicalKey == LogicalKeyboardKey.metaRight ||
        event.logicalKey == LogicalKeyboardKey.controlLeft ||
        event.logicalKey == LogicalKeyboardKey.controlRight ||
        event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight) {
      return;
    }

    final key = event.logicalKey;

    // C - Call selected lead
    if (key == LogicalKeyboardKey.keyC && selectedLead != null) {
      _handleCall(context, ref, selectedLead!);
      return;
    }

    // W - WhatsApp selected lead
    if (key == LogicalKeyboardKey.keyW && selectedLead != null) {
      _handleWhatsApp(context, ref, selectedLead!);
      return;
    }

    // S - Toggle star (priority)
    if (key == LogicalKeyboardKey.keyS && selectedLead != null) {
      _handleToggleStar(context, ref, selectedLead!);
      return;
    }

    // / - Focus search bar
    if (key == LogicalKeyboardKey.slash && searchFocusNode != null) {
      searchFocusNode!.requestFocus();
      return;
    }

    // Esc - Clear filters or exit dialogs
    if (key == LogicalKeyboardKey.escape) {
      if (onDismissDialog != null) {
        onDismissDialog!();
      } else if (onClearFilters != null) {
        onClearFilters!();
      }
      return;
    }
  }

  Future<void> _handleCall(BuildContext context, WidgetRef ref, Lead lead) async {
    if (lead.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No phone number available'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final service = ref.read(leadActionsServiceProvider);
    final success = await service.callLead(lead, context);

    if (success && context.mounted) {
      ref.read(leadListProvider.notifier).refresh();
    }
  }

  Future<void> _handleWhatsApp(BuildContext context, WidgetRef ref, Lead lead) async {
    if (lead.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No phone number available'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final service = ref.read(leadActionsServiceProvider);
    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User not authenticated'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final hasNeverBeenContacted = lead.lastContactedAt == null;
    
    if (hasNeverBeenContacted) {
      await service.whatsappLead(lead, context);
    } else {
      await service.whatsappFollowUp(lead, context, user);
    }

    if (context.mounted) {
      ref.read(leadListProvider.notifier).refresh();
    }
  }

  Future<void> _handleToggleStar(BuildContext context, WidgetRef ref, Lead lead) async {
    // Toggle priority/star - use the same logic as PriorityStarToggle widget
    // For now, just show a message that this feature needs a selected lead context
    // In a real implementation, you'd need to track selected lead state
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a lead first to toggle priority'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}

