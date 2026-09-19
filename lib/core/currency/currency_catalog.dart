import 'dart:collection';

import 'package:money2/money2.dart';

/// Currency metadata used by ShopTrack.
///
/// The catalogue intentionally contains current, non-deprecated ISO 4217
/// currencies that a shopper can pay with. ISO accounting/fund units, precious
/// metals, test codes, "no currency", and non-ISO digital currencies are not
/// offered by the picker.
class ShopCurrency {
  const ShopCurrency._(this._source, {required this.isSupported});

  final Currency _source;
  final bool isSupported;

  String get code => _source.isoCode;
  String get symbol => _source.symbol.trim();
  String get name => _source.name.trim().isNotEmpty
      ? _source.name.trim()
      : _source.unit.trim().isNotEmpty
      ? _source.unit.trim()
      : code;
  String get country => _source.country.trim();
  int get decimalDigits => _source.decimalDigits;

  Currency get money2Currency => _source;

  String get displayName => name == code ? code : '$code — $name';

  @override
  bool operator ==(Object other) {
    return other is ShopCurrency && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}

class CurrencyCatalog {
  const CurrencyCatalog._();

  static const String defaultCode = 'BDT';
  static const int recentLimit = 6;

  // These ISO 4217 entries are not ordinary payment currencies. Regional
  // tender codes such as XAF, XCD, XCG, XOF and XPF remain available.
  static const Set<String> _nonShoppingCodes = {
    'BOV',
    'CHE',
    'CHW',
    'CLF',
    'COU',
    'MXV',
    'USN',
    'UYI',
    'UYW',
    'XAD',
    'XAG',
    'XAU',
    'XBA',
    'XBB',
    'XBC',
    'XBD',
    'XDR',
    'XPD',
    'XPT',
    'XSU',
    'XTS',
    'XUA',
    'XXX',
  };

  static final List<ShopCurrency> all = List.unmodifiable(
    CommonCurrencies()
        .asList()
        .where((currency) {
          return currency.isIso &&
              !currency.isDeprecated &&
              !_nonShoppingCodes.contains(currency.isoCode);
        })
        .map((currency) => ShopCurrency._(currency, isSupported: true))
        .toList()
      ..sort((a, b) => a.code.compareTo(b.code)),
  );

  static final Map<String, ShopCurrency> _byCode = UnmodifiableMapView({
    for (final currency in all) currency.code: currency,
  });

  static ShopCurrency? find(String? code) {
    return _byCode[code?.trim().toUpperCase()];
  }

  static bool isSupported(String? code) => find(code) != null;

  /// Returns known metadata, or a safe descriptor for a valid code written by
  /// a newer app version. Preserving the code is safer than relabelling old
  /// financial data as BDT.
  static ShopCurrency resolve(String? code) {
    final normalized = normalizeItemCode(code);
    return find(normalized) ??
        ShopCurrency._(
          Currency.create(normalized, 2, symbol: '', name: normalized),
          isSupported: false,
        );
  }

  /// Legacy items had no currency field and were always displayed as BDT.
  /// Valid unknown codes are retained for forward compatibility.
  static String normalizeItemCode(Object? value) {
    final code = value is String ? value.trim().toUpperCase() : '';
    return RegExp(r'^[A-Z]{3}$').hasMatch(code) ? code : defaultCode;
  }

  /// A user preference must point to a currency this build can offer.
  static String normalizeDefaultCode(Object? value) {
    final code = normalizeItemCode(value);
    return isSupported(code) ? code : defaultCode;
  }

  static List<String> sanitizeRecentCodes(
    Iterable<Object?> values, {
    required String defaultCurrencyCode,
  }) {
    final normalizedDefault = normalizeDefaultCode(defaultCurrencyCode);
    final result = <String>[];
    for (final value in values) {
      final code = normalizeItemCode(value);
      if (code == normalizedDefault || !isSupported(code)) continue;
      if (!result.contains(code)) result.add(code);
      if (result.length == recentLimit) break;
    }
    return List.unmodifiable(result);
  }

  /// Default first, recent choices next, and the remaining catalogue after
  /// that. This is the ordering contract for the future currency picker.
  static List<ShopCurrency> prioritized({
    required String defaultCurrencyCode,
    Iterable<String> recentCurrencyCodes = const [],
  }) {
    final defaultCode = normalizeDefaultCode(defaultCurrencyCode);
    final recent = sanitizeRecentCodes(
      recentCurrencyCodes,
      defaultCurrencyCode: defaultCode,
    );
    final codes = <String>{defaultCode, ...recent};
    return List.unmodifiable([
      _byCode[defaultCode]!,
      ...recent.map((code) => _byCode[code]!),
      ...all.where((currency) => !codes.contains(currency.code)),
    ]);
  }

  static List<ShopCurrency> search(String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return all;
    return List.unmodifiable(
      all.where((currency) {
        return currency.code.toLowerCase().contains(needle) ||
            currency.name.toLowerCase().contains(needle) ||
            currency.country.toLowerCase().contains(needle) ||
            currency.symbol.toLowerCase().contains(needle);
      }),
    );
  }
}
