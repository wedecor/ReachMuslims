import 'package:flutter/services.dart';
import '../../domain/models/user.dart';

/// TextInputFormatter that formats phone numbers based on region
/// - USA: (XXX) XXX-XXXX
/// - India: XXXX-XXXXXX
class RegionBasedPhoneFormatter extends TextInputFormatter {
  final UserRegion region;

  RegionBasedPhoneFormatter(this.region);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Get only digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Limit to 10 digits for both regions
    final limitedDigits = digitsOnly.length > 10 
        ? digitsOnly.substring(0, 10) 
        : digitsOnly;

    String formatted = '';

    if (region == UserRegion.usa) {
      // USA format: (XXX) XXX-XXXX
      if (limitedDigits.isEmpty) {
        formatted = '';
      } else if (limitedDigits.length <= 3) {
        formatted = '($limitedDigits';
      } else if (limitedDigits.length <= 6) {
        formatted = '(${limitedDigits.substring(0, 3)}) ${limitedDigits.substring(3)}';
      } else {
        formatted = '(${limitedDigits.substring(0, 3)}) ${limitedDigits.substring(3, 6)}-${limitedDigits.substring(6)}';
      }
    } else {
      // India format: XXXX-XXXXXX
      if (limitedDigits.isEmpty) {
        formatted = '';
      } else if (limitedDigits.length <= 4) {
        formatted = limitedDigits;
      } else {
        formatted = '${limitedDigits.substring(0, 4)}-${limitedDigits.substring(4)}';
      }
    }

    // Calculate cursor position
    int cursorPosition = formatted.length;
    
    // If user is deleting, maintain cursor position appropriately
    if (newValue.text.length < oldValue.text.length) {
      // User is deleting, try to maintain cursor position
      final oldDigits = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');
      final newDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
      
      if (oldDigits.length > newDigits.length) {
        // Calculate where cursor should be based on digit position
        final deletedDigitIndex = oldValue.selection.baseOffset;
        int digitCount = 0;
        int newCursorPos = 0;
        
        for (int i = 0; i < formatted.length && digitCount < deletedDigitIndex; i++) {
          if (RegExp(r'\d').hasMatch(formatted[i])) {
            digitCount++;
          }
          newCursorPos = i + 1;
        }
        cursorPosition = newCursorPos;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}

/// Helper class for phone number validation based on region
class PhoneNumberValidator {
  static String? validate(String? value, UserRegion region) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone is required';
    }

    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (region == UserRegion.usa) {
      // USA: exactly 10 digits
      if (digitsOnly.length != 10) {
        return 'Please enter a valid US phone number (10 digits)';
      }
    } else {
      // India: exactly 10 digits
      if (digitsOnly.length != 10) {
        return 'Please enter a valid Indian phone number (10 digits)';
      }
    }

    return null;
  }

  /// Extract only digits from formatted phone number
  static String getDigitsOnly(String phone) {
    return phone.replaceAll(RegExp(r'[^\d]'), '');
  }
}

