import 'package:intl/intl.dart';

/// Helper class for formatting "time ago" strings
/// Examples: "Just now", "2h ago", "Yesterday", "5 days ago"
class TimeAgoHelper {
  /// Formats a DateTime as a human-readable "time ago" string
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    // Just now (less than 1 minute)
    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    // Minutes ago (less than 1 hour)
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes${minutes == 1 ? ' minute' : ' minutes'} ago';
    }

    // Hours ago (less than 24 hours)
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours${hours == 1 ? ' hour' : ' hours'} ago';
    }

    // Yesterday (between 24-48 hours)
    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    // Days ago (less than 7 days)
    if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? ' day' : ' days'} ago';
    }

    // Weeks ago (less than 4 weeks)
    if (difference.inDays < 28) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? ' week' : ' weeks'} ago';
    }

    // Months ago (less than 12 months)
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? ' month' : ' months'} ago';
    }

    // Years ago
    final years = (difference.inDays / 365).floor();
    return '$years ${years == 1 ? ' year' : ' years'} ago';
  }

  /// Formats a DateTime for display in timeline (full date + time)
  static String formatTimelineDate(DateTime dateTime) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
    return dateFormat.format(dateTime);
  }
}

