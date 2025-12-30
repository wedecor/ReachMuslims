import '../../domain/models/user.dart';

/// Utility for formatting phone numbers for display based on region
/// Does NOT modify stored values
class PhoneNumberFormatter {
  /// Formats a phone number string for display based on region
  /// - USA: (XXX) XXX-XXXX
  /// - India: XXXX-XXXXXX
  static String formatPhoneNumber(String phone, {UserRegion? region}) {
    if (phone.isEmpty) return phone;

    // Remove all non-digit characters
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length != 10) {
      // If not 10 digits, return original (might have country code)
      return phone;
    }

    // Format based on region
    if (region == UserRegion.usa) {
      // USA format: (XXX) XXX-XXXX
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    } else {
      // India format: XXXX-XXXXXX
      return '${digitsOnly.substring(0, 4)}-${digitsOnly.substring(4)}';
    }
  }

  /// Legacy method for backward compatibility
  /// Tries to auto-detect format from phone string
  static String formatPhoneNumberLegacy(String phone) {
    if (phone.isEmpty) return phone;

    // Remove all non-digit characters except +
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Handle Indian numbers (+91)
    if (cleaned.startsWith('+91') && cleaned.length >= 13) {
      final countryCode = cleaned.substring(0, 3); // +91
      final number = cleaned.substring(3);
      if (number.length == 10) {
        // Format: +91 98765 43210
        return '$countryCode ${number.substring(0, 5)} ${number.substring(5)}';
      }
    }
    
    // Handle US/Canada numbers (+1)
    if (cleaned.startsWith('+1') && cleaned.length == 12) {
      final countryCode = cleaned.substring(0, 2); // +1
      final areaCode = cleaned.substring(2, 5);
      final firstPart = cleaned.substring(5, 8);
      final secondPart = cleaned.substring(8);
      // Format: +1 (555) 123-4567
      return '$countryCode ($areaCode) $firstPart-$secondPart';
    }
    
    // Handle numbers starting with + but not matching above patterns
    if (cleaned.startsWith('+')) {
      // Try to format as: +XX XXX XXX XXXX (generic international)
      if (cleaned.length >= 10) {
        final countryCode = cleaned.substring(0, cleaned.length - 10);
        final number = cleaned.substring(countryCode.length);
        if (number.length == 10) {
          return '$countryCode ${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
        }
      }
    }
    
    // For numbers without country code, try to format as local number
    if (cleaned.length == 10 && !cleaned.startsWith('+')) {
      // Format: (555) 123-4567 (assume USA format)
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    
    // If no pattern matches, return original
    return phone;
  }
}

