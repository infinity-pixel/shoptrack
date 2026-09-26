import 'package:intl/intl.dart';
import 'package:intl/number_symbols_data.dart';

import '../currency/currency_catalog.dart';
import '../../models/app_settings.dart';

class NumberFormatter {
  static String _symbolMarker(ShopCurrency currency) =>
      const {'SAR', 'AED', 'OMR', 'MVR'}.contains(currency.code)
      ? '${currency.symbol} '
      : currency.symbol;

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

  /// Formats a price with its currency symbol and up to two decimal places.
  static String formatPrice(
    double price, {
    String currencyCode = CurrencyCatalog.defaultCode,
    bool includeCode = false,
    NumberFormatPreference preference = NumberFormatPreference.automatic,
    String? deviceLocale,
  }) {
    final currency = CurrencyCatalog.resolve(currencyCode);
    final symbol = currency.symbol;
    final marker = symbol.isEmpty
        ? '${currency.code} '
        : _symbolMarker(currency);
    final prefix = includeCode && symbol.isNotEmpty
        ? '${currency.code} $marker'
        : marker;
    final locale = _numberLocale(preference, currency.code, deviceLocale);

    if (price == price.roundToDouble()) {
      return '$prefix${NumberFormat.decimalPattern(locale).format(price)}';
    }

    final formatted = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    ).format(price);
    return '$prefix$formatted';
  }

  static String formatDisplayPrice(
    double price, {
    String currencyCode = CurrencyCatalog.defaultCode,
    bool includeCode = false,
    NumberFormatPreference preference = NumberFormatPreference.automatic,
    String? deviceLocale,
  }) {
    // Called only when the full amount does not fit its actual layout width.
    if (!price.isFinite || price.abs() < 1000) {
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
        : _symbolMarker(currency);
    final locale = _numberLocale(preference, currency.code, deviceLocale);
    final southAsian = _usesSouthAsianGrouping(locale);
    final value = price.abs();
    if (preference == NumberFormatPreference.automatic &&
        (locale.startsWith('zh') ||
            locale.startsWith('ja') ||
            locale.startsWith('ko'))) {
      final compact = NumberFormat.compact(locale: locale).format(value);
      return '$prefix$symbol${price < 0 ? '-' : ''}$compact';
    }
    final (divisor, suffix) = southAsian
        ? (
            value >= 10000000
                ? 10000000.0
                : value >= 100000
                ? 100000.0
                : 1000.0,
            value >= 10000000
                ? ' Crore'
                : value >= 100000
                ? ' Lakh'
                : 'K',
          )
        : value >= 1000000000000
        ? (1000000000000.0, 'T')
        : value >= 1000000000
        ? (1000000000.0, 'B')
        : value >= 1000000
        ? (1000000.0, 'M')
        : (1000.0, 'K');
    final scaled = (value / divisor * 100).truncateToDouble() / 100;
    final digits = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 2,
    ).format(scaled);
    final separator = numberFormatSymbols[locale]?.DECIMAL_SEP ?? '.';
    final zeroDigit = numberFormatSymbols[locale]?.ZERO_DIGIT ?? '0';
    var trimmedDigits = digits;
    while (trimmedDigits.endsWith(zeroDigit)) {
      trimmedDigits = trimmedDigits.substring(
        0,
        trimmedDigits.length - zeroDigit.length,
      );
    }
    if (trimmedDigits.endsWith(separator)) {
      trimmedDigits = trimmedDigits.substring(
        0,
        trimmedDigits.length - separator.length,
      );
    }
    return '$prefix$symbol${price < 0 ? '-' : ''}$trimmedDigits$suffix';
  }

  // CLDR supplies a default currency for each locale. National currencies use
  // a locale from their issuing region. Explicit choices resolve shared or
  // ambiguous currencies consistently; unknown codes retain the device locale.
  static const Map<String, String> _preferredCurrencyLocales = {
    'BDT': 'en_IN',
    'INR': 'en_IN',
    'NPR': 'en_IN',
    'PKR': 'en_IN',
    'LKR': 'en_IN',
    'BTN': 'en_IN',
    'USD': 'en_US',
    'EUR': 'de_DE',
    'GBP': 'en_GB',
    'SAR': 'ar_SA',
    'AED': 'ar_AE',
    'CNY': 'zh_CN',
    'JPY': 'ja_JP',
    'KRW': 'ko_KR',
    'TWD': 'zh_TW',
    'HKD': 'zh_HK',
    'XAF': 'fr_CM',
    'XCD': 'en_AG',
    'XOF': 'fr_SN',
    'XPF': 'fr_PF',
  };

  static final Map<String, String> _localeByCurrency = () {
    final candidates = <String, List<String>>{};
    for (final entry in numberFormatSymbols.entries) {
      final code = entry.value.DEF_CURRENCY_CODE;
      if (CurrencyCatalog.isSupported(code)) {
        candidates.putIfAbsent(code, () => []).add(entry.key);
      }
    }
    return {
      for (final currency in CurrencyCatalog.all)
        currency.code:
            _supportedPreferredLocale(currency.code) ??
            (_selectLocale(currency.code, candidates[currency.code]) ??
                'en_US'),
    };
  }();

  static String? _supportedPreferredLocale(String code) {
    final locale = _preferredCurrencyLocales[code];
    if (locale == null) return null;
    if (numberFormatSymbols.containsKey(locale)) return locale;
    final language = locale.split('_').first;
    return numberFormatSymbols.containsKey(language) ? language : null;
  }

  static String? _selectLocale(String code, List<String>? candidates) {
    if (candidates == null || candidates.isEmpty) return null;
    final region = code.substring(0, 2);
    candidates.sort((a, b) {
      int rank(String locale) {
        final parts = locale.split('_');
        var score = parts.length > 1 ? 10 : 0;
        if (parts.length > 1 && parts.last.toUpperCase() == region) {
          score += 100;
        }
        if (parts.first != 'en') score += 1;
        return score;
      }

      final difference = rank(b).compareTo(rank(a));
      return difference != 0 ? difference : a.compareTo(b);
    });
    return candidates.first;
  }

  static String _numberLocale(
    NumberFormatPreference preference,
    String currencyCode,
    String? deviceLocale,
  ) {
    if (preference == NumberFormatPreference.southAsian) return 'en_IN';
    if (preference == NumberFormatPreference.international) return 'en_US';
    return _localeByCurrency[currencyCode] ??
        (numberFormatSymbols.containsKey(deviceLocale)
            ? deviceLocale!
            : 'en_US');
  }

  static bool _usesSouthAsianGrouping(String locale) =>
      numberFormatSymbols[locale]?.DECIMAL_PATTERN.contains('##,##') ?? false;
}
