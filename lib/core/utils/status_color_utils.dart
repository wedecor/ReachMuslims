import 'package:flutter/material.dart';
import '../../domain/models/lead.dart';

/// Centralized status color mapping for the Reach Muslim Lead Management app.
/// 
/// This is the single source of truth for all status colors.
/// STATUS → COLOR MAPPING (LOCKED):
/// - New → Blue
/// - Follow Up → Purple
/// - In Talk → Orange
/// - Not Interested → Red
/// - Converted → Green
class StatusColorUtils {
  StatusColorUtils._(); // Private constructor to prevent instantiation

  /// Get the primary color for a status (for text, icons, etc.)
  /// Returns the base color for the status.
  static Color getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return Colors.blue;
      case LeadStatus.followUp:
        return Colors.purple;
      case LeadStatus.inTalk:
        return Colors.orange;
      case LeadStatus.notInterested:
        return Colors.red;
      case LeadStatus.converted:
        return Colors.green;
    }
  }

  /// Get the background color for status badges/chips.
  /// Uses a light tint of the primary color for filled backgrounds.
  static Color getStatusBackgroundColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return Colors.blue.shade50;
      case LeadStatus.followUp:
        return Colors.purple.shade50;
      case LeadStatus.inTalk:
        return Colors.orange.shade50;
      case LeadStatus.notInterested:
        return Colors.red.shade50;
      case LeadStatus.converted:
        return Colors.green.shade50;
    }
  }

  /// Get the text color for status badges/chips.
  /// Ensures sufficient contrast against the background color.
  static Color getStatusTextColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return Colors.blue.shade700;
      case LeadStatus.followUp:
        return Colors.purple.shade700;
      case LeadStatus.inTalk:
        return Colors.orange.shade700;
      case LeadStatus.notInterested:
        return Colors.red.shade700;
      case LeadStatus.converted:
        return Colors.green.shade700;
    }
  }

  /// Get a darker shade for emphasis or hover states.
  static Color getStatusDarkColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return Colors.blue.shade700;
      case LeadStatus.followUp:
        return Colors.purple.shade700;
      case LeadStatus.inTalk:
        return Colors.orange.shade700;
      case LeadStatus.notInterested:
        return Colors.red.shade700;
      case LeadStatus.converted:
        return Colors.green.shade700;
    }
  }

  /// Fallback color for unknown/invalid status (neutral grey).
  static Color getFallbackColor() {
    return Colors.grey;
  }
}

