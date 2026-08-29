class DateParser {
  /// Parses a date string into a [DateTime] object.
  /// Supports formats like "d/m/yyyy", "d-m-yyyy", "dd/mm/yyyy", "ddmmyyyy".
  static DateTime? parse(String input) {
    String trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Handle ddmmyyyy (8 digits)
    if (RegExp(r'^\d{8}$').hasMatch(trimmed)) {
      final day = int.parse(trimmed.substring(0, 2));
      final month = int.parse(trimmed.substring(2, 4));
      final year = int.parse(trimmed.substring(4, 8));
      return _createValidDate(year, month, day);
    }

    // Handle dmyyyy (6 digits) - ambiguous, but maybe 1/1/2026 as 01012026 is better
    // If we want to support "natural" entry, we should probably stick to separators or 8-digits.

    // Replace common separators with a single one
    final normalized = trimmed.replaceAll('-', '/').replaceAll('.', '/');
    final parts = normalized.split('/');

    if (parts.length != 3) return null;

    try {
      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = int.parse(parts[2]);

      if (year < 100) {
        year += 2000;
      }

      return _createValidDate(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static DateTime? _createValidDate(int year, int month, int day) {
    if (month < 1 || month > 12) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  /// Normalizes a date into the standard "d/m/yyyy" format for input.
  static String format(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
