import 'package:intl/intl.dart';

class NumberFormatter {
  /// Formats a number with international thousands separators (commas).
  /// Preserves decimals but removes unnecessary trailing zeros.
  static String format(double value) {
    // Keep calculated values readable without exposing binary floating-point
    // tails such as 11.800000000000001.
    final formatter = NumberFormat("#,##0.######", "en_US");
    return formatter.format(value);
  }

  /// Displays the exact quantity the shopper entered whenever it is available.
  /// Calculated/default quantities fall back to the safe numeric formatter.
  static String formatQuantity(double value, {String? enteredText}) {
    final normalized = enteredText?.trim();
    if (normalized != null && normalized.isNotEmpty) return normalized;
    return format(value);
  }

  /// Formats a price with currency symbol and separators.
  /// If there are decimals, shows up to 2 decimal places.
  static String formatPrice(double price) {
    if (price == 0) return '৳0';

    if (price == price.roundToDouble()) {
      return '৳${NumberFormat("#,##0", "en_US").format(price)}';
    }

    // For prices with decimals, usually 2 decimal places is standard.
    // The requirement says: 500.50 -> 500.50
    return '৳${NumberFormat("#,##0.00", "en_US").format(price)}';
  }
}
