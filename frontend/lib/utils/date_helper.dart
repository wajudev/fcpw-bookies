import 'package:intl/intl.dart';

class DateHelper {
  /// Format datetime for display (e.g., "19. Aug 2026, 14:00")
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('d. MMM yyyy, HH:mm', 'de_DE').format(dateTime);
  }

  /// Format date only (e.g., "19. August 2026")
  static String formatDate(DateTime dateTime) {
    return DateFormat('d. MMMM yyyy', 'de_DE').format(dateTime);
  }

  /// Get time remaining in human-readable format
  static String getTimeRemaining(DateTime deadline, {bool showSeconds = false}) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Abgelaufen';
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    if (days > 0) {
      if (days == 1) {
        return '1 Tag, $hours Std.';
      }
      return '$days Tage, $hours Std.';
    } else if (hours > 0) {
      return '$hours Std., $minutes Min.';
    } else if (minutes > 0) {
      if (showSeconds) {
        return '$minutes Min., $seconds Sek.';
      }
      return '$minutes Min.';
    } else {
      if (showSeconds) {
        return '$seconds Sek.';
      }
      return 'Weniger als 1 Min.';
    }
  }

  /// Get countdown with indicator (returns time string only)
  static String getCountdownWithIndicator(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Abgelaufen';
    }

    final hours = difference.inHours;
    final showSeconds = hours < 1;
    return getTimeRemaining(deadline, showSeconds: showSeconds);
  }

  /// Get color for deadline urgency indicator
  static String getDeadlineColorHex(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return '#EF4444'; // Red for expired
    }

    final hours = difference.inHours;

    if (hours < 1) {
      return '#EF4444'; // Red - urgent (< 1 hour)
    } else if (hours <= 2) {
      return '#F59E0B'; // Amber - soon (1-2 hours)
    } else {
      return '#10B981'; // Green - plenty of time
    }
  }

  /// Check if deadline has passed
  static bool isDeadlinePassed(DateTime deadline) {
    return DateTime.now().isAfter(deadline);
  }

  /// Get match prediction deadline (2 hours before kickoff)
  static DateTime getMatchDeadline(DateTime kickoffTime) {
    return kickoffTime.subtract(const Duration(hours: 2));
  }
}
