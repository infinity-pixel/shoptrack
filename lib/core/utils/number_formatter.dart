import 'package:intl/intl.dart';

import '../currency/currency_catalog.dart';

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

  /// Formats a price with its currency symbol and minor-unit precision.
  static String formatPrice(
    double price, {
    String currencyCode = CurrencyCatalog.defaultCode,
    bool includeCode = false,
  }) {
    final currency = CurrencyCatalog.resolve(currencyCode);
    final symbol = currency.symbol;
    final marker = symbol.isEmpty ? '${currency.code} ' : symbol;
    final prefix = includeCode && symbol.isNotEmpty
        ? '${currency.code} $symbol'
        : marker;
    if (price == 0) return '${prefix}0';

    if (price == price.roundToDouble()) {
      return '$prefix${NumberFormat("#,##0", "en_US").format(price)}';
    }

    // Preserve meaningful calculated unit prices even for zero-minor-unit
    // currencies while respecting currencies that use three decimal places.
    final decimalDigits = currency.decimalDigits < 2
        ? 2
        : currency.decimalDigits;
    final pattern = '#,##0.${'0' * decimalDigits}';
    return '$prefix${NumberFormat(pattern, "en_US").format(price)}';
  }
}
