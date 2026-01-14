import '../../domain/models/user.dart';

/// Utility for formatting phone numbers for display based on region
/// Does NOT modify stored values
class PhoneNumberFormatter {
  /// Formats a phone number string for display based on region
  /// - USA: (XXX) XXX-XXXX or +1 (XXX) XXX-XXXX if country code present
  /// - India: XXXX-XXXXXX or +91 XXXX-XXXXXX if country code present
  static String formatPhoneNumber(String phone, {UserRegion? region}) {
    if (phone.isEmpty) return phone;

    // Check if phone has country code prefix
    final hasPlus = phone.trim().startsWith('+');
    String countryCode = '';
    String phoneWithoutCode = phone;
    
    if (hasPlus) {
      // Extract country code
      if (phone.trim().startsWith('+1') && phone.trim().length >= 12) {
        // US/Canada: +1
        countryCode = '+1';
        phoneWithoutCode = phone.trim().substring(2).trim();
      } else if (phone.trim().startsWith('+91') && phone.trim().length >= 13) {
        // India: +91
        countryCode = '+91';
        phoneWithoutCode = phone.trim().substring(3).trim();
      } else {
        // Other country codes - try to extract
        final match = RegExp(r'^\+(\d{1,3})').firstMatch(phone.trim());
        if (match != null) {
          countryCode = '+${match.group(1)}';
          phoneWithoutCode = phone.trim().substring(countryCode.length).trim();
        }
      }
    }

    // Remove all non-digit characters from the number part
    final digitsOnly = phoneWithoutCode.replaceAll(RegExp(r'[^\d]'), '');
    
    // Handle different digit lengths
    if (digitsOnly.length == 10) {
      // Standard 10-digit number
      String formatted;
      if (region == UserRegion.usa) {
        // USA format: (XXX) XXX-XXXX
        formatted = '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
      } else {
        // India format: XXXX-XXXXXX
        formatted = '${digitsOnly.substring(0, 4)}-${digitsOnly.substring(4)}';
      }
      
      // Add country code prefix if present
      if (countryCode.isNotEmpty) {
        return '$countryCode $formatted';
      }
      return formatted;
    } else if (digitsOnly.length == 11 && digitsOnly.startsWith('1') && region == UserRegion.usa) {
      // US number with leading 1: 1XXXXXXXXXX -> (XXX) XXX-XXXX
      final withoutLeadingOne = digitsOnly.substring(1);
      final formatted = '(${withoutLeadingOne.substring(0, 3)}) ${withoutLeadingOne.substring(3, 6)}-${withoutLeadingOne.substring(6)}';
      return countryCode.isNotEmpty ? '$countryCode $formatted' : '+1 $formatted';
    } else if (digitsOnly.length == 12 && digitsOnly.startsWith('91') && (region == null || region == UserRegion.india)) {
      // India number with leading 91: 91XXXXXXXXXX -> XXXX-XXXXXX
      final withoutCountryCode = digitsOnly.substring(2);
      final formatted = '${withoutCountryCode.substring(0, 4)}-${withoutCountryCode.substring(4)}';
      return countryCode.isNotEmpty ? '$countryCode $formatted' : '+91 $formatted';
    } else if (digitsOnly.length > 10) {
      // Number with country code but not standard format - try to format last 10 digits
      if (digitsOnly.length >= 10) {
        final last10Digits = digitsOnly.substring(digitsOnly.length - 10);
        String formatted;
        if (region == UserRegion.usa) {
          formatted = '(${last10Digits.substring(0, 3)}) ${last10Digits.substring(3, 6)}-${last10Digits.substring(6)}';
        } else {
          formatted = '${last10Digits.substring(0, 4)}-${last10Digits.substring(4)}';
        }
        if (countryCode.isNotEmpty) {
          return '$countryCode $formatted';
        }
        return formatted;
      }
    }
    
    // If we can't format it properly, return original (might be international format)
    return phone;
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

