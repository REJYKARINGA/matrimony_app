import 'package:intl/intl.dart';

class DateFormatter {
  /// Format a DateTime object to a user-friendly string (e.g., "January 15, 1990")
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMMM dd, yyyy').format(date);
  }

  /// Format a DateTime object to a short string (e.g., "Jan 15, 1990")
  static String formatShortDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Parse a date string back to DateTime
  static DateTime? parseDate(String dateString) {
    try {
      return DateFormat('MMMM dd, yyyy').parse(dateString);
    } catch (e) {
      try {
        return DateFormat('MMM dd, yyyy').parse(dateString);
      } catch (e) {
        return DateTime.tryParse(dateString);
      }
    }
  }

  /// Convert a date string in YYYY-MM-DD format to a user-friendly format
  static String convertDateString(String dateString) {
    DateTime? date = DateTime.tryParse(dateString);
    if (date != null) {
      return formatDate(date);
    }
    return dateString;
  }
}