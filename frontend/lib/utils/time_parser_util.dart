class TimeParserUtil {
  static DateTime? parseEndTime(String timeSlot) {
    try {
      if (!timeSlot.contains('-')) return null;
      final parts = timeSlot.split('-');
      if (parts.length < 2) return null;
      final timeParts = parts[1].trim().split(':');
      if (timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0].trim());
        final min = int.tryParse(timeParts[1].trim());
        if (hour != null && min != null) {
          final now = DateTime.now();
          return DateTime(now.year, now.month, now.day, hour, min);
        }
      }
    } catch (_) {}
    return null;
  }
}
