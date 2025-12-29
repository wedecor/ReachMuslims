/// Utility for formatting phone numbers for display only
/// Does NOT modify stored values
class PhoneNumberFormatter {
  /// Formats a phone number string for display
  /// Handles common formats: +91, +1, etc.
  /// Returns formatted string or original if formatting fails
  static String formatPhoneNumber(String phone) {
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
      // Format: (555) 123-4567
      return '(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}';
    }
    
    // If no pattern matches, return original
    return phone;
  }
}

