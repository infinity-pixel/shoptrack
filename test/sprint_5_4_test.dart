import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/utils/pricing_calculator.dart';
import 'package:shoptrack/models/shopping_item.dart';

void main() {
  group('Sprint 5.4: Resolved Quantity Display Fix', () {
    test('Quantity 6 + no unit + no price → displays "6 pc"', () {
      final result = PricingCalculator.calculate(
        quantity: 6,
        priceValue: null,
        mode: PricingMode.total,
        unit: null,
        priceBasis: null,
      );
      expect(result.resolvedQuantity, 6.0);
      expect(result.resolvedUnitSymbol, 'pc');
    });

    test('Unit kg + no quantity + no price → displays "1 kg"', () {
      final result = PricingCalculator.calculate(
        quantity: null,
        priceValue: null,
        mode: PricingMode.unit,
        unit: ShoppingUnit.kg,
        priceBasis: null,
      );
      expect(result.resolvedQuantity, 1.0);
      expect(result.resolvedUnitSymbol, 'kg');
    });

    test('Unit L + no quantity + no price → displays "1 L"', () {
      final result = PricingCalculator.calculate(
        quantity: null,
        priceValue: null,
        mode: PricingMode.unit,
        unit: ShoppingUnit.l,
        priceBasis: null,
      );
      expect(result.resolvedQuantity, 1.0);
      expect(result.resolvedUnitSymbol, 'L');
    });

    test('Unit pc + no quantity + no price → displays "1 pc"', () {
      final result = PricingCalculator.calculate(
        quantity: null,
        priceValue: null,
        mode: PricingMode.unit,
        unit: ShoppingUnit.pcs,
        priceBasis: null,
      );
      expect(result.resolvedQuantity, 1.0);
      expect(result.resolvedUnitSymbol, 'pc');
    });

    test('Price only + no quantity/unit → displays only the price (No invented 1 pc)', () {
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

    test('Name only → displays only the name (zero result)', () {
      final result = PricingCalculator.calculate(
        quantity: null,
        priceValue: null,
        mode: PricingMode.total,
        unit: null,
        priceBasis: null,
      );
      expect(result.resolvedQuantity, isNull);
      expect(result.resolvedUnitSymbol, isNull);
      expect(result.totalPrice, 0.0);
    });
  });
}
