import 'package:intl/intl.dart';

import '../currency/currency_catalog.dart';
import '../../models/app_settings.dart';

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
    NumberFormatPreference preference = NumberFormatPreference.international,
    String? deviceLocale,
  }) {
    final currency = CurrencyCatalog.resolve(currencyCode);
    final symbol = currency.symbol;
    final marker = symbol.isEmpty ? '${currency.code} ' : symbol;
    final prefix = includeCode && symbol.isNotEmpty
        ? '${currency.code} $symbol'
        : marker;
    if (price == 0) return '${prefix}0';

    final locale = _numberLocale(preference, deviceLocale);

    if (price == price.roundToDouble()) {
      return '$prefix${NumberFormat.decimalPattern(locale).format(price)}';
    }

    final formatted = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    ).format(price);
    return '$prefix${formatted.replaceFirst(RegExp(r'([.,])0+$'), '')}';
  }

  static String formatDisplayPrice(
    double price, {
    String currencyCode = CurrencyCatalog.defaultCode,
    bool includeCode = false,
    NumberFormatPreference preference = NumberFormatPreference.international,
    String? deviceLocale,
  }) {
    if (!price.isFinite || price.abs() < 100000) {
      return formatPrice(
        price,
        currencyCode: currencyCode,
        includeCode: includeCode,
        preference: preference,
        deviceLocale: deviceLocale,
      );
    }
    final currency = CurrencyCatalog.resolve(currencyCode);
    final prefix = includeCode && currency.symbol.isNotEmpty
        ? '${currency.code} '
        : '';
    final symbol = currency.symbol.isEmpty
        ? '${currency.code} '
        : currency.symbol;
    final southAsian = _numberLocale(preference, deviceLocale) == 'en_IN';
    final value = price.abs();
    final (divisor, suffix) = southAsian
        ? (
            value >= 10000000 ? 10000000.0 : 100000.0,
            value >= 10000000 ? ' Crore' : ' Lakh',
          )
        : value >= 1000000000000
        ? (1000000000000.0, 'T')
        : value >= 1000000000
        ? (1000000000.0, 'B')
        : value >= 1000000
        ? (1000000.0, 'M')
        : (1000.0, 'K');
    final scaled = (value / divisor * 100).truncateToDouble() / 100;
    final digits = scaled
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    return '$prefix$symbol${price < 0 ? '-' : ''}$digits$suffix';
  }

  static String _numberLocale(
    NumberFormatPreference preference,
    String? deviceLocale,
  ) {
    if (preference == NumberFormatPreference.southAsian) return 'en_IN';
    if (preference == NumberFormatPreference.international) return 'en_US';
    final normalized = deviceLocale?.replaceAll('-', '_').toLowerCase() ?? '';
    if (normalized.endsWith('_bd') ||
        normalized.endsWith('_in') ||
        normalized.endsWith('_pk') ||
        normalized.endsWith('_np')) {
      return 'en_IN';
    }
    return 'en_US';
  }
}
