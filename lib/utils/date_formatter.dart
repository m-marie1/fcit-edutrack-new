import 'package:intl/intl.dart';

class DateFormatter {
  /// Format a date string from the API (assumed to be in UTC) to a readable local format
  /// Input example: "2025-4-18T23:59:00"
  /// Output example: "Apr 18, 2025 11:59 PM"
  static String formatDateString(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }

    try {
      // Parse the date string - assume it's already UTC
      DateTime utcDate;
      if (dateString.contains('T')) {
        // Parse directly as UTC without additional conversion
        utcDate = DateTime.parse('${dateString}Z');
      } else {
        // For dates without time component
        utcDate = DateTime.parse('${dateString}T00:00:00Z');
      }

      // Convert to local time
      final localDate = utcDate.toLocal();

      // Format with a nice date/time format
      return DateFormat('MMM d, yyyy h:mm a').format(localDate);
    } catch (e) {
      // print('Error formatting date: $e, input was: $dateString');
      return dateString; // Return original string if parsing fails
    }
  }

  /// Format a date string to show only the date part
  /// Output example: "Apr 18, 2025"
  static String formatDateOnly(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }

    try {
      // Parse the date string - assume it's already UTC
      DateTime utcDate;
      if (dateString.contains('T')) {
        // Parse directly as UTC without additional conversion
        utcDate = DateTime.parse('${dateString}Z');
      } else {
        // For dates without time component
        utcDate = DateTime.parse('${dateString}T00:00:00Z');
      }

      // Convert to local time
      final localDate = utcDate.toLocal();

      // Format with date only
      return DateFormat('MMM d, yyyy').format(localDate);
    } catch (e) {
      // print('Error formatting date: $e, input was: $dateString');
      return dateString; // Return original string if parsing fails
    }
  }

  /// Format a date string that was entered by a user and should not be interpreted as UTC
  /// This is specifically for assignment due dates that are stored as entered by professors
  static String formatNonUtcDateString(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }

    try {
      DateTime date;
      if (dateString.contains('T')) {
        date = DateTime.parse(dateString);
      } else {
        date = DateTime.parse('${dateString}T00:00:00');
      }

      // Format directly without timezone conversion
      return DateFormat('MMM d, yyyy h:mm a').format(date);
    } catch (e) {
      // print('Error formatting non-UTC date: $e, input was: $dateString');
      return dateString; // Return original string if parsing fails
    }
  }
}
