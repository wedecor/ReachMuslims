import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/models/lead.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/follow_up_repository.dart';
import '../../domain/repositories/lead_repository.dart';
import '../utils/whatsapp_message_helper.dart';
import '../utils/region_based_phone_formatter.dart';

/// UI-agnostic service for lead actions (Call, WhatsApp)
/// Handles intent launch, follow-up logging, and lastContactedAt updates
class LeadActionsService {
  final FollowUpRepository _followUpRepository;
  final LeadRepository _leadRepository;

  LeadActionsService({
    required FollowUpRepository followUpRepository,
    required LeadRepository leadRepository,
  })  : _followUpRepository = followUpRepository,
        _leadRepository = leadRepository;

  /// Checks if the current platform supports phone calls
  bool isMobilePlatform(BuildContext context) {
    if (kIsWeb) return false;
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  /// Launches a URI (call or WhatsApp)
  Future<bool> _launchUri(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Normalizes a lead's phone for WhatsApp `wa.me` links.
  /// - Expects only digits (no formatting) in [lead.phone]
  /// - Adds country code based on [lead.region] if missing
  /// - Returns `null` if we can't build a valid international number
  String? _buildWhatsAppPhone(Lead lead) {
    final digitsOnly = PhoneNumberValidator.getDigitsOnly(lead.phone);
    if (digitsOnly.isEmpty) return null;

    // If the number already looks like it has a country code, keep it
    // India: 91 + 10 digits = 12 digits
    // USA: 1 + 10 digits = 11 digits
    if ((digitsOnly.length == 12 && digitsOnly.startsWith('91')) ||
        (digitsOnly.length == 11 && digitsOnly.startsWith('1'))) {
      return digitsOnly;
    }

    // If it's just 10 digits, prepend country code based on region
    if (digitsOnly.length == 10) {
      switch (lead.region) {
        case UserRegion.india:
          return '91$digitsOnly';
        case UserRegion.usa:
          return '1$digitsOnly';
      }
    }

    // Fallback: if it's between 11-15 digits, assume it's already in intl format
    if (digitsOnly.length >= 11 && digitsOnly.length <= 15) {
      return digitsOnly;
    }

    return null;
  }

  /// Initiates a call to the lead
  /// Returns true if successful, false otherwise
  Future<bool> callLead(Lead lead, BuildContext context) async {
    if (lead.phone.isEmpty) {
      return false;
    }

    if (!isMobilePlatform(context)) {
      return false;
    }

    final uri = Uri(scheme: 'tel', path: lead.phone);
    final launched = await _launchUri(uri);

    if (launched) {
      // Update lastContactedAt on successful call
      try {
        await _leadRepository.updateLastContactedAt(lead.id);
      } catch (_) {
        // Silently fail - call was successful, timestamp update is secondary
      }
    }

    return launched;
  }

  /// Opens WhatsApp with initial contact message (does NOT log follow-up)
  /// Returns true if successful, false otherwise
  Future<bool> whatsappLead(Lead lead, BuildContext context) async {
    if (lead.phone.isEmpty) {
      return false;
    }

    final waPhone = _buildWhatsAppPhone(lead);
    if (waPhone == null) {
      return false;
    }

    final message = WhatsAppMessageHelper.buildMessage(
      region: lead.region,
      type: WhatsAppMessageType.initial,
      name: lead.name,
    );

    final uri = WhatsAppMessageHelper.buildWhatsAppUri(
      phoneWithCountryCode: waPhone,
      message: message,
    );

    final launched = await _launchUri(uri);

    if (launched) {
      // Update lastContactedAt on successful WhatsApp launch
      try {
        await _leadRepository.updateLastContactedAt(lead.id);
      } catch (_) {
        // Silently fail - WhatsApp launch was successful, timestamp update is secondary
      }
    }

    return launched;
  }

  /// Opens WhatsApp with follow-up message AND logs the follow-up
  /// Returns true if both WhatsApp launch and logging succeed
  Future<bool> whatsappFollowUp(
    Lead lead,
    BuildContext context,
    User user,
  ) async {
    if (lead.phone.isEmpty) {
      return false;
    }

    final waPhone = _buildWhatsAppPhone(lead);
    if (waPhone == null) {
      return false;
    }

    final message = WhatsAppMessageHelper.buildMessage(
      region: lead.region,
      type: WhatsAppMessageType.followUp,
      name: lead.name,
    );

    final uri = WhatsAppMessageHelper.buildWhatsAppUri(
      phoneWithCountryCode: waPhone,
      message: message,
    );

    // Open WhatsApp first
    final launched = await _launchUri(uri);
    if (!launched) {
      return false;
    }

    // Log follow-up and update lastContactedAt
    try {
      final preview = WhatsAppMessageHelper.buildPreview(message);
      await _followUpRepository.addFollowUp(
        lead.id,
        message,
        user.uid,
        type: 'whatsapp',
        region: lead.region.name,
        messagePreview: preview,
      );

      // Update lastContactedAt after successful follow-up log
      await _leadRepository.updateLastContactedAt(lead.id);

      return true;
    } catch (_) {
      // WhatsApp was launched but logging failed
      // Still update lastContactedAt since contact was made
      try {
        await _leadRepository.updateLastContactedAt(lead.id);
      } catch (_) {
        // Ignore
      }
      return false;
    }
  }
}

