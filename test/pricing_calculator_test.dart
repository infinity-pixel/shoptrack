import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/utils/pricing_calculator.dart';
import 'package:shoptrack/models/shopping_item.dart';

void main() {
  group('PricingCalculator Sprint 4.3 Tests', () {
    test('1. 2 L + Price per L ৳100 → Total ৳200', () {
      final result = PricingCalculator.calculate(
        quantity: 2,
        priceValue: 100,
        mode: PricingMode.unit,
        unit: ShoppingUnit.l,
        priceBasis: ShoppingUnit.l,
      );
      expect(result.totalPrice, 200.0);
      expect(result.unitPrice, 100.0);
      expect(result.priceBasisSymbol, 'L');
    });

    test('2. 30 pcs + Total Price ৳300 → Price per pc ৳10', () {
      final result = PricingCalculator.calculate(
        quantity: 30,
        priceValue: 300,
        mode: PricingMode.total,
        unit: ShoppingUnit.pcs,
        priceBasis: null,
      );
      expect(result.totalPrice, 300.0);
      expect(result.unitPrice, 10.0);
      expect(result.priceBasisSymbol, 'pc');
    });

    test('3. 250 g + Price per kg ৳100 → Total ৳25', () {
      final result = PricingCalculator.calculate(
        quantity: 250,
        priceValue: 100,
        mode: PricingMode.unit,
        unit: ShoppingUnit.g,
        priceBasis: ShoppingUnit.kg,
      );
      expect(result.totalPrice, 25.0);
      expect(result.unitPrice, 100.0);
      expect(result.priceBasisSymbol, 'kg');
    });

    test('4. 250 g + Price per g ৳1 → Total ৳250', () {
      final result = PricingCalculator.calculate(
        quantity: 250,
        priceValue: 1,
        mode: PricingMode.unit,
        unit: ShoppingUnit.g,
        priceBasis: ShoppingUnit.g,
      );
      expect(result.totalPrice, 250.0);
      expect(result.unitPrice, 1.0);
      expect(result.priceBasisSymbol, 'g');
    });

    test('5. 500 ml + Price per L ৳100 → Total ৳50', () {
      final result = PricingCalculator.calculate(
        quantity: 500,
        priceValue: 100,
        mode: PricingMode.unit,
        unit: ShoppingUnit.ml,
        priceBasis: ShoppingUnit.l,
      );
      expect(result.totalPrice, 50.0);
      expect(result.unitPrice, 100.0);
      expect(result.priceBasisSymbol, 'L');
    });

    test('6. 500 ml + Price per ml ৳0.10 → Total ৳50', () {
      final result = PricingCalculator.calculate(
        quantity: 500,
        priceValue: 0.10,
        mode: PricingMode.unit,
        unit: ShoppingUnit.ml,
        priceBasis: ShoppingUnit.ml,
      );
      expect(result.totalPrice, 50.0);
      expect(result.unitPrice, 0.10);
      expect(result.priceBasisSymbol, 'mL');
    });

    test('7. 2 kg + Price per kg ৳100 → Total ৳200', () {
      final result = PricingCalculator.calculate(
        quantity: 2,
        priceValue: 100,
        mode: PricingMode.unit,
        unit: ShoppingUnit.kg,
        priceBasis: ShoppingUnit.kg,
      );
      expect(result.totalPrice, 200.0);
      expect(result.unitPrice, 100.0);
      expect(result.priceBasisSymbol, 'kg');
    });

    test('Quantity empty with unit → behaves as 1 (Smart Default Case A)', () {
      final result = PricingCalculator.calculate(
        quantity: null,
        priceValue: 100,
        mode: PricingMode.unit,
        unit: ShoppingUnit.l,
        priceBasis: ShoppingUnit.l,
      );
      expect(result.totalPrice, 100.0);
      expect(result.unitPrice, 100.0);
    });

    test('Zero quantity returns zero', () {
      final result = PricingCalculator.calculate(
        quantity: 0,
        priceValue: 100,
        mode: PricingMode.unit,
        unit: ShoppingUnit.l,
        priceBasis: ShoppingUnit.l,
      );
      expect(result, PricingResult.zero);
    });

    test('Negative price returns zero', () {
      final result = PricingCalculator.calculate(
        quantity: 2,
        priceValue: -10,
        mode: PricingMode.unit,
        unit: ShoppingUnit.l,
        priceBasis: ShoppingUnit.l,
      );
      expect(result, PricingResult.zero);
    });

    test('Incompatible units return zero', () {
      final result = PricingCalculator.calculate(
        quantity: 2,
        priceValue: 100,
        mode: PricingMode.unit,
        unit: ShoppingUnit.kg,
        priceBasis: ShoppingUnit.l,
      );
      expect(result, PricingResult.zero);
    });

    test('Incompatible units mass vs pcs return zero', () {
      final result = PricingCalculator.calculate(
        quantity: 2,
        priceValue: 100,
        mode: PricingMode.unit,
        unit: ShoppingUnit.kg,
        priceBasis: ShoppingUnit.pcs,
      );
      expect(result, PricingResult.zero);
    });

    test('Total mode with compatibility check (kg/g normalization to standard basis for display)', () {
       final result = PricingCalculator.calculate(
        quantity: 250,
        priceValue: 25,
        mode: PricingMode.total,
        unit: ShoppingUnit.g,
        priceBasis: null,
      );
      expect(result.totalPrice, 25.0);
      expect(result.unitPrice, 100.0);
      expect(result.priceBasisSymbol, 'kg');
    });
  });
}
