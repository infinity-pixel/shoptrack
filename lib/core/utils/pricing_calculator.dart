import '../../../models/shopping_item.dart';

class PricingResult {
  final double totalPrice;
  final double unitPrice;
  final String priceBasisSymbol;
  final double? resolvedQuantity;
  final String? resolvedUnitSymbol;

  const PricingResult({
    required this.totalPrice,
    required this.unitPrice,
    required this.priceBasisSymbol,
    this.resolvedQuantity,
    this.resolvedUnitSymbol,
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
    // Smart Defaults Logic
    double? effectiveQty = quantity;
    ShoppingUnit? effectiveUnit = unit;

    // Case A: Unit selected, Quantity empty -> Assume 1
    if (effectiveQty == null && effectiveUnit != null) {
      effectiveQty = 1.0;
    }

    // Case B/C: Quantity entered, Unit empty -> Assume pc
    if (effectiveQty != null && effectiveUnit == null) {
      effectiveUnit = ShoppingUnit.pcs;
    }

    // Capture resolved values for display
    final resQty = effectiveQty;
    final resUnit = effectiveUnit?.symbol;

    // Rule D: Total Price mode + price only -> Orange ৳100 (No invented qty/unit)
    if (mode == PricingMode.total && priceValue != null && priceValue >= 0 && quantity == null && unit == null) {
      return PricingResult(
        totalPrice: priceValue,
        unitPrice: 0,
        priceBasisSymbol: '',
        resolvedQuantity: null,
        resolvedUnitSymbol: null,
      );
    }

    // Handle missing or invalid inputs for calculation
    if (effectiveQty == null || effectiveQty <= 0 || priceValue == null || priceValue < 0) {
      // Return resolved info for display if valid for display but not for calculation
      if (effectiveQty != null && effectiveQty > 0 && resUnit != null && (priceValue == null || priceValue >= 0)) {
        return PricingResult(
          totalPrice: priceValue ?? 0.0,
          unitPrice: 0,
          priceBasisSymbol: '',
          resolvedQuantity: resQty,
          resolvedUnitSymbol: resUnit,
        );
      }
      return PricingResult.zero;
    }

    if (mode == PricingMode.unit) {
      // Rule E: Price only + Price per Unit mode + no unit -> cannot calculate
      if (effectiveUnit == null) {
        return PricingResult.zero;
      }

      // Default priceBasis to unit if not provided
      final effectivePriceBasis = priceBasis ?? effectiveUnit;

      // Validate compatibility
      if (!effectiveUnit.isCompatibleWith(effectivePriceBasis)) {
        return PricingResult.zero;
      }

      // priceValue is price per effectivePriceBasis
      double normalizedQuantity = effectiveQty;

      if (effectiveUnit != effectivePriceBasis) {
        // Normalize quantity to effectivePriceBasis
        if (effectiveUnit == ShoppingUnit.g && effectivePriceBasis == ShoppingUnit.kg) {
          normalizedQuantity = effectiveQty / 1000.0;
        } else if (effectiveUnit == ShoppingUnit.kg && effectivePriceBasis == ShoppingUnit.g) {
          normalizedQuantity = effectiveQty * 1000.0;
        } else if (effectiveUnit == ShoppingUnit.ml && effectivePriceBasis == ShoppingUnit.l) {
          normalizedQuantity = effectiveQty / 1000.0;
        } else if (effectiveUnit == ShoppingUnit.l && effectivePriceBasis == ShoppingUnit.ml) {
          normalizedQuantity = effectiveQty * 1000.0;
        }
      }

      final total = normalizedQuantity * priceValue;
      return PricingResult(
        totalPrice: total,
        unitPrice: priceValue,
        priceBasisSymbol: effectivePriceBasis.symbol,
        resolvedQuantity: resQty,
        resolvedUnitSymbol: resUnit,
      );
    } else {
      // priceValue is total price
      // Use standard basis for mass/volume for secondary display
      final displayBasis = effectiveUnit?.standardBasis ?? ShoppingUnit.pcs;
      double normalizedQuantity = effectiveQty;

      if (effectiveUnit != null && effectiveUnit != displayBasis) {
        if (effectiveUnit == ShoppingUnit.g && displayBasis == ShoppingUnit.kg) {
          normalizedQuantity = effectiveQty / 1000.0;
        } else if (effectiveUnit == ShoppingUnit.ml && displayBasis == ShoppingUnit.l) {
          normalizedQuantity = effectiveQty / 1000.0;
        }
      }

      final unitPrice = normalizedQuantity > 0 ? priceValue / normalizedQuantity : 0.0;
      return PricingResult(
        totalPrice: priceValue,
        unitPrice: unitPrice,
        priceBasisSymbol: displayBasis.symbol,
        resolvedQuantity: resQty,
        resolvedUnitSymbol: resUnit,
      );
    }
  }
}
