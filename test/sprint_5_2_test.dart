import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/utils/pricing_calculator.dart';
import 'package:shoptrack/models/shopping_item.dart';

void main() {
  group('Sprint 5.2: Smart Defaults Tests', () {
    test('Case A: Unit selected, Quantity empty → Assume 1', () {
      final result = PricingCalculator.calculate(
        quantity: null,
        priceValue: 175,
        mode: PricingMode.unit,
        unit: ShoppingUnit.kg,
        priceBasis: null,
      );
      expect(result.totalPrice, 175.0);
      expect(result.unitPrice, 175.0);
      expect(result.priceBasisSymbol, 'kg');
    });

    test('Case B/C: Quantity entered, Unit empty → Assume pc', () {
      final result = PricingCalculator.calculate(
        quantity: 6,
        priceValue: 300,
        mode: PricingMode.total,
        unit: null,
        priceBasis: null,
      );
      expect(result.totalPrice, 300.0);
      expect(result.unitPrice, 50.0);
      expect(result.priceBasisSymbol, 'pc');
    });

    test('Case D: Total Price mode + price only → No invented unit/qty', () {
      final result = PricingCalculator.calculate(
        quantity: null,
        priceValue: 100,
        mode: PricingMode.total,
        unit: null,
        priceBasis: null,
      );
      expect(result.totalPrice, 100.0);
      expect(result.unitPrice, 0); // No unit, so unit price is not calculable
      expect(result.priceBasisSymbol, '');
    });

    test('Case E: Price per Unit mode + price only + no unit → Cannot calculate', () {
      // The calculator should return zero/invalid if unit is null in unit mode
      final result = PricingCalculator.calculate(
        quantity: null,
        priceValue: 100,
        mode: PricingMode.unit,
        unit: null,
        priceBasis: null,
      );
      expect(result, PricingResult.zero);
    });

    test('Case F: No quantity, no unit, no price → Valid (returns zero)', () {
      final result = PricingCalculator.calculate(
        quantity: null,
        priceValue: null,
        mode: PricingMode.total,
        unit: null,
        priceBasis: null,
      );
      expect(result, PricingResult.zero);
    });
  });

  group('Sprint 5.2: Ordering Logic', () {
    test('Item copyWith preserves or updates position', () {
      const item = ShoppingItem(id: '1', name: 'Milk', position: 5);
      expect(item.position, 5);
      
      final updated = item.copyWith(position: 10);
      expect(updated.position, 10);
      expect(updated.name, 'Milk');
    });
  });
}
