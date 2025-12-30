import 'package:flutter/material.dart';
import '../utils/status_color_utils.dart';
import '../../domain/models/lead.dart';

class AppTheme {
  AppTheme._();

  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  // Dark theme - uses dark grey tones, not pure black
  static ThemeData get darkTheme {
    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: const Color(0xFF121212), // Dark grey, not black
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF1E1E1E), // Slightly lighter than background
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      // Ensure status colors maintain contrast in dark mode
      extensions: [
        StatusColorExtension(
          newColor: StatusColorUtils.getStatusColor(LeadStatus.newLead),
          inTalkColor: StatusColorUtils.getStatusColor(LeadStatus.inTalk),
          convertedColor: StatusColorUtils.getStatusColor(LeadStatus.converted),
          lostColor: StatusColorUtils.getStatusColor(LeadStatus.notInterested),
        ),
      ],
    );
  }
}

// Extension to preserve status colors in dark mode
class StatusColorExtension extends ThemeExtension<StatusColorExtension> {
  final Color newColor;
  final Color inTalkColor;
  final Color convertedColor;
  final Color lostColor;

  StatusColorExtension({
    required this.newColor,
    required this.inTalkColor,
    required this.convertedColor,
    required this.lostColor,
  });

  @override
  ThemeExtension<StatusColorExtension> copyWith({
    Color? newColor,
    Color? inTalkColor,
    Color? convertedColor,
    Color? lostColor,
  }) {
    return StatusColorExtension(
      newColor: newColor ?? this.newColor,
      inTalkColor: inTalkColor ?? this.inTalkColor,
      convertedColor: convertedColor ?? this.convertedColor,
      lostColor: lostColor ?? this.lostColor,
    );
  }

  @override
  ThemeExtension<StatusColorExtension> lerp(
    ThemeExtension<StatusColorExtension>? other,
    double t,
  ) {
    if (other is! StatusColorExtension) {
      return this;
    }
    return StatusColorExtension(
      newColor: Color.lerp(newColor, other.newColor, t)!,
      inTalkColor: Color.lerp(inTalkColor, other.inTalkColor, t)!,
      convertedColor: Color.lerp(convertedColor, other.convertedColor, t)!,
      lostColor: Color.lerp(lostColor, other.lostColor, t)!,
    );
  }
}

