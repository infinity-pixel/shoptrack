import 'dart:collection';

import 'package:money2/money2.dart';

import '../../models/shopping_item.dart';
import 'currency_catalog.dart';

class CurrencyTotal {
  const CurrencyTotal._({required this.currency, required this.money});

  final ShopCurrency currency;
  final Money money;

  String get currencyCode => currency.code;
  double get value => money.toDouble();
  BigInt get minorUnits => money.minorUnits;
}

/// Fixed-precision totals keyed by currency.
///
/// Values of different currencies are never added together. Item prices still
/// use the established backwards-compatible JSON fields; they are rounded to
/// each currency's minor-unit precision when totals are built.
class CurrencyTotals {
  CurrencyTotals._(Map<String, CurrencyTotal> values)
    : _values = UnmodifiableMapView(values);

  factory CurrencyTotals.fromItems(
    Iterable<ShoppingItem> items, {
    bool Function(ShoppingItem item)? where,
  }) {
    final totals = <String, CurrencyTotal>{};
    for (final item in items) {
      if (where != null && !where(item)) continue;
      if (item.priceValue == null) continue;

      final currency = CurrencyCatalog.resolve(item.currencyCode);
      final amount = Money.fromNumWithCurrency(
        item.pricing.totalPrice,
        currency.money2Currency,
      );
      final existing = totals[currency.code];
      totals[currency.code] = CurrencyTotal._(
        currency: currency,
        money: existing == null ? amount : existing.money + amount,
      );
    }
    return CurrencyTotals._(totals);
  }

  final Map<String, CurrencyTotal> _values;

  bool get isEmpty => _values.isEmpty;
  bool get isMultiCurrency => _values.length > 1;
  int get length => _values.length;
  Iterable<String> get currencyCodes => _values.keys;
  Iterable<CurrencyTotal> get values => _values.values;

  CurrencyTotal? operator [](String code) => _values[code.toUpperCase()];

  List<CurrencyTotal> ordered({String? preferredCurrencyCode}) {
    final preferred = preferredCurrencyCode?.trim().toUpperCase();
    final result = _values.values.toList()
      ..sort((a, b) {
        if (a.currencyCode == preferred) return -1;
        if (b.currencyCode == preferred) return 1;
        return a.currencyCode.compareTo(b.currencyCode);
      });
    return List.unmodifiable(result);
  }

  /// Compatibility bridge for screens that have not received the Sprint 19
  /// grouped-total UI yet. Throwing is deliberate: silently adding BDT and USD
  /// would create a believable but false financial result.
  double get singleValueOrZero {
    if (_values.isEmpty) return 0;
    if (_values.length == 1) return _values.values.single.value;
    throw StateError('Multiple currencies must be displayed separately.');
  }
}
