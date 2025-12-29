import '../../domain/models/user.dart';

/// Helper for building region-aware WhatsApp messages.
///
/// Keeps message templates out of the UI and returns messages that are safe to
/// use in WhatsApp `wa.me` links (URL-encoded).
class WhatsAppMessageHelper {
  WhatsAppMessageHelper._();

  /// Builds the plain text message (not encoded) for the given [region] and [type].
  static String buildMessage({
    required UserRegion region,
    required WhatsAppMessageType type,
    required String name,
  }) {
    final trimmedName = name.trim().isEmpty ? 'there' : name.trim();

    switch (region) {
      case UserRegion.india:
        return type == WhatsAppMessageType.initial
            ? _indiaInitial(trimmedName)
            : _indiaFollowUp(trimmedName);
      case UserRegion.usa:
        return type == WhatsAppMessageType.initial
            ? _usaInitial(trimmedName)
            : _usaFollowUp(trimmedName);
    }
  }

  /// Returns the message encoded for use as a `text` query parameter in
  /// `https://wa.me/<phone>?text=<encodedMessage>`.
  static String encodeForWhatsApp(String message) {
    return Uri.encodeComponent(message);
  }

  /// Builds the full WhatsApp URI for a given [phoneWithCountryCode] and [message].
  static Uri buildWhatsAppUri({
    required String phoneWithCountryCode,
    required String message,
  }) {
    final encoded = encodeForWhatsApp(message);
    return Uri.parse('https://wa.me/$phoneWithCountryCode?text=$encoded');
  }

  /// Returns a short preview (first 50 characters) of the message.
  static String buildPreview(String message, {int maxLength = 50}) {
    if (message.length <= maxLength) return message;
    return '${message.substring(0, maxLength)}…';
  }

  // ===== Region-specific templates (MUST match exactly) =====

  static String _indiaInitial(String name) => '''
Assalamu Alaikum $name,
This is Reach Muslim, a trusted Muslim matrimonial service.
We received your enquiry and wanted to connect at your convenience.
Please let us know a suitable time to speak.
JazakAllahu Khair.''';

  static String _indiaFollowUp(String name) => '''
Assalamu Alaikum $name,
This is Reach Muslim. We are just following up regarding your earlier enquiry.
Kindly let us know if you would like us to proceed further.
May Allah make it easy for you.''';

  static String _usaInitial(String name) => '''
Assalamu Alaikum $name,
This is Reach Muslim, a Muslim matrimonial service.
We received your enquiry and would be happy to assist you when convenient.
Please let us know a good time to connect.
JazakAllahu Khair.''';

  static String _usaFollowUp(String name) => '''
Assalamu Alaikum $name,
This is Reach Muslim, following up on your enquiry.
Please feel free to let us know if you would like to move forward.
May Allah grant you what is best.''';
}

enum WhatsAppMessageType {
  initial,
  followUp,
}


