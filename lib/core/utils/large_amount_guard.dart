import '../../models/shopping_item.dart';

/// The persisted price and quantity fields are doubles. At very large values
/// adjacent decimal amounts cannot all be represented. Accept only inputs and
/// calculated totals whose two-decimal value survives that representation.
/// This permits large round amounts without silently changing a final digit.
class LargeAmountGuard {
  static const double maximum = 1000000000000000000; // one quintillion

  static bool canStore(String entered, double value, {int maxDecimals = 2}) {
    if (!value.isFinite || value < 0 || value > maximum) return false;
    if (value < 1000000000000) return true;
    final parts = entered.split('.');
    if (parts.length > 2 ||
        parts.first.contains(RegExp(r'\D')) ||
        (parts.length == 2 &&
            (parts.last.isEmpty ||
                parts.last.length > maxDecimals ||
                parts.last.contains(RegExp(r'\D'))))) {
      return false;
    }
    final places = parts.length == 2 ? parts.last.length : 0;
    final exact = _scaled(entered, places);
    final represented = _scaled(value.toStringAsFixed(places), places);
    return exact != null && exact == represented;
  }

  static bool canStoreCalculatedTotal({
    required String price,
    required String? quantity,
    required double calculatedTotal,
    required PricingMode mode,
    required ShoppingUnit? unit,
    required ShoppingUnit? priceBasis,
  }) {
    if (!calculatedTotal.isFinite ||
        calculatedTotal < 0 ||
        calculatedTotal > maximum) {
      return false;
    }
    if (calculatedTotal < 1000000000000 || mode == PricingMode.total) {
      return true;
    }
    final priceParts = price.split('.');
    final priceCents = _scaled(price, 2);
    final enteredQuantity = quantity?.isNotEmpty == true ? quantity! : '1';
    final quantityParts = enteredQuantity.split('.');
    final quantityPlaces = quantityParts.length == 2
        ? quantityParts.last.length
        : 0;
    final quantityScaled = _scaled(enteredQuantity, quantityPlaces);
    if (priceParts.length > 2 || priceCents == null || quantityScaled == null) {
      return false;
    }

    var numerator = priceCents * quantityScaled;
    var denominator = BigInt.from(10).pow(quantityPlaces);
    final basis = priceBasis ?? unit;
    if ((unit == ShoppingUnit.g && basis == ShoppingUnit.kg) ||
        (unit == ShoppingUnit.ml && basis == ShoppingUnit.l)) {
      denominator *= BigInt.from(1000);
    } else if ((unit == ShoppingUnit.kg && basis == ShoppingUnit.g) ||
        (unit == ShoppingUnit.l && basis == ShoppingUnit.ml)) {
      numerator *= BigInt.from(1000);
    }

    // Currency totals are rounded to two decimal places for entered prices.
    final roundedCents =
        (numerator * BigInt.two + denominator) ~/ (denominator * BigInt.two);
    final representedCents = _scaled(calculatedTotal.toStringAsFixed(2), 2);
    return representedCents == roundedCents;
  }

  static BigInt? _scaled(String text, int places) {
    final parts = text.split('.');
    if (parts.length > 2) return null;
    final whole = BigInt.tryParse(parts.first.isEmpty ? '0' : parts.first);
    if (whole == null) return null;
    final fraction = parts.length == 2 ? parts.last : '';
    if (fraction.length > places || fraction.contains(RegExp(r'\D'))) {
      return null;
    }
    final padded = fraction.padRight(places, '0');
    return whole * BigInt.from(10).pow(places) +
        (padded.isEmpty
            ? BigInt.zero
            : (BigInt.tryParse(padded) ?? BigInt.zero));
  }
}
