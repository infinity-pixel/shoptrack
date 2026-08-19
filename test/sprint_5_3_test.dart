import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/utils/pricing_calculator.dart';
import 'package:shoptrack/models/shopping_item.dart';

void main() {
  group('Sprint 5.3: Resolved Quantity and Unit Display', () {
    test('Case A: Unit selected (kg), Quantity empty → resolvedQuantity = 1.0', () {
      final result = PricingCalculator.calculate(
        quantity: null,
        priceValue: 175,
        mode: PricingMode.unit,
        unit: ShoppingUnit.kg,
        priceBasis: null,
      );
      expect(result.resolvedQuantity, 1.0);
      expect(result.resolvedUnitSymbol, 'kg');
      expect(result.totalPrice, 175.0);
    });

    test('Case B: Unit selected (L), Quantity empty → resolvedQuantity = 1.0', () {
      final result = PricingCalculator.calculate(
        quantity: null,
        priceValue: 100,
        mode: PricingMode.unit,
        unit: ShoppingUnit.l,
        priceBasis: null,
      );
      expect(result.resolvedQuantity, 1.0);
      expect(result.resolvedUnitSymbol, 'L');
    });

    test('Case C/D: Quantity entered (6), Unit empty → resolvedUnitSymbol = pc', () {
      final result = PricingCalculator.calculate(
        quantity: 6,
        priceValue: 300,
        mode: PricingMode.total,
        unit: null,
        priceBasis: null,
      );
      expect(result.resolvedQuantity, 6.0);
      expect(result.resolvedUnitSymbol, 'pc');
    });

    test('Case E: Total Price mode + price only → resolvedQuantity and Unit are null', () {
      final result = PricingCalculator.calculate(
        quantity: null,
        priceValue: 100,
        mode: PricingMode.total,
        unit: null,
        priceBasis: null,
      );
      expect(result.resolvedQuantity, isNull);
      expect(result.resolvedUnitSymbol, isNull);
      expect(result.totalPrice, 100.0);
    });

    test('Case F: Simple item (no price) → returns zero/null values', () {
      final result = PricingCalculator.calculate(
        quantity: null,
        priceValue: null,
        mode: PricingMode.total,
        unit: null,
        priceBasis: null,
      );
      expect(result.resolvedQuantity, isNull);
      expect(result.resolvedUnitSymbol, isNull);
    });
  });

  group('Sprint 5.3: Quantity Display Format', () {
    // These would be tested via a helper method if exposed, 
    // or by checking the ShoppingItemTile if we did a widget test.
    // Let's test the calculator's numeric stability first.
    
    test('Decimal quantities preserved', () {
      final result = PricingCalculator.calculate(
        quantity: 0.25,
        priceValue: 100,
        mode: PricingMode.unit,
        unit: ShoppingUnit.kg,
        priceBasis: null,
      );
      expect(result.resolvedQuantity, 0.25);
    });
  });
}
