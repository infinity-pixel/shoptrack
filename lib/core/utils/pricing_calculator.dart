import '../../../models/shopping_item.dart';

class PricingResult {
  final double totalPrice;
  final double unitPrice;
  final String priceBasisSymbol;

  const PricingResult({
    required this.totalPrice,
    required this.unitPrice,
    required this.priceBasisSymbol,
  });

  static const zero = PricingResult(
    totalPrice: 0,
    unitPrice: 0,
    priceBasisSymbol: '',
  );
}

class PricingCalculator {
  static PricingResult calculate({
    required double? quantity,
    required double? priceValue,
    required PricingMode mode,
    required ShoppingUnit? unit,
    required ShoppingUnit? priceBasis,
  }) {
    if (quantity == null || quantity <= 0 || priceValue == null || priceValue < 0) {
      return PricingResult.zero;
    }

    // Default priceBasis to unit if not provided
    final effectivePriceBasis = priceBasis ?? unit;

    if (effectivePriceBasis == null) {
      return PricingResult(
        totalPrice: mode == PricingMode.total ? priceValue : 0,
        unitPrice: 0,
        priceBasisSymbol: '',
      );
    }

    // Validate compatibility if mode is unit
    if (mode == PricingMode.unit && unit != null) {
      if (!unit.isCompatibleWith(effectivePriceBasis)) {
        return PricingResult.zero;
      }
    }

    if (mode == PricingMode.unit) {
      // priceValue is price per effectivePriceBasis
      double normalizedQuantity = quantity;

      if (unit != null && unit != effectivePriceBasis) {
        // Normalize quantity to effectivePriceBasis
        if (unit == ShoppingUnit.g && effectivePriceBasis == ShoppingUnit.kg) {
          normalizedQuantity = quantity / 1000.0;
        } else if (unit == ShoppingUnit.kg && effectivePriceBasis == ShoppingUnit.g) {
          normalizedQuantity = quantity * 1000.0;
        } else if (unit == ShoppingUnit.ml && effectivePriceBasis == ShoppingUnit.l) {
          normalizedQuantity = quantity / 1000.0;
        } else if (unit == ShoppingUnit.l && effectivePriceBasis == ShoppingUnit.ml) {
          normalizedQuantity = quantity * 1000.0;
        }
      }

      final total = normalizedQuantity * priceValue;
      return PricingResult(
        totalPrice: total,
        unitPrice: priceValue,
        priceBasisSymbol: effectivePriceBasis.symbol,
      );
    } else {
      // priceValue is total price
      // Price per unit is usually based on the quantity unit
      final unitPrice = quantity > 0 ? priceValue / quantity : 0.0;
      return PricingResult(
        totalPrice: priceValue,
        unitPrice: unitPrice,
        priceBasisSymbol: unit?.symbol ?? '',
      );
    }
  }
}
