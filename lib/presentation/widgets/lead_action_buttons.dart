import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/whatsapp_message_helper.dart';
import '../../domain/models/lead.dart';
import '../providers/auth_provider.dart';
import '../providers/follow_up_provider.dart';

/// Action buttons for a lead:
/// - Call (mobile only)
/// - WhatsApp initial contact
/// - WhatsApp follow-up (also logs a follow-up entry)
class LeadActionButtons extends ConsumerWidget {
  final Lead lead;

  const LeadActionButtons({
    super.key,
    required this.lead,
  });

  bool _isMobilePlatform(BuildContext context) {
    if (kIsWeb) return false;
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open the requested app.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open the requested app.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleCall(BuildContext context) async {
    if (lead.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for this lead.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: lead.phone);
    await _launchUri(context, uri);
  }

  Future<void> _handleWhatsAppInitial(BuildContext context) async {
    if (lead.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for this lead.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final message = WhatsAppMessageHelper.buildMessage(
      region: lead.region,
      type: WhatsAppMessageType.initial,
      name: lead.name,
    );

    final uri = WhatsAppMessageHelper.buildWhatsAppUri(
      phoneWithCountryCode: lead.phone,
      message: message,
    );

    await _launchUri(context, uri);
  }

  Future<void> _handleWhatsAppFollowUp(BuildContext context, WidgetRef ref) async {
    if (lead.phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available for this lead.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

    final message = WhatsAppMessageHelper.buildMessage(
      region: lead.region,
      type: WhatsAppMessageType.followUp,
      name: lead.name,
    );

    final uri = WhatsAppMessageHelper.buildWhatsAppUri(
      phoneWithCountryCode: lead.phone,
      message: message,
    );

    // Open WhatsApp
    await _launchUri(context, uri);

    // Log follow-up using existing repository logic
    final preview = WhatsAppMessageHelper.buildPreview(message);
    final followUpRepository = ref.read(followUpRepositoryProvider);

    try {
      await followUpRepository.addFollowUp(
        lead.id,
        message,
        user.uid,
        type: 'whatsapp',
        region: lead.region.name,
        messagePreview: preview,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to log WhatsApp follow-up.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = _isMobilePlatform(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Tooltip(
          message: isMobile ? 'Call lead' : 'Call is available on mobile only',
          child: ElevatedButton.icon(
            onPressed: isMobile ? () => _handleCall(context) : null,
            icon: const Icon(Icons.phone),
            label: const Text('Call'),
          ),
        ),
        Tooltip(
          message: 'Open WhatsApp with initial message',
          child: ElevatedButton.icon(
            onPressed: () => _handleWhatsAppInitial(context),
            icon: const Icon(Icons.chat),
            label: const Text('WhatsApp'),
          ),
        ),
        Tooltip(
          message: 'Send WhatsApp follow-up and log it',
          child: ElevatedButton.icon(
            onPressed: () => _handleWhatsAppFollowUp(context, ref),
            icon: const Icon(Icons.notes),
            label: const Text('Follow-up'),
          ),
        ),
      ],
    );
  }
}


