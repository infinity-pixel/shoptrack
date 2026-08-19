import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/models/shopping_item.dart';

void main() {
  group('Sprint 6: Local Data Persistence - Serialization Tests', () {
    test('ShoppingItem toJson/fromJson preserves all fields', () {
      final item = const ShoppingItem(
        id: 'test-id-123',
        name: 'Milk',
        quantity: '2',
        unit: 'L',
        price: '200',
        quantityValue: 2.0,
        priceValue: 100.0,
        pricingMode: PricingMode.unit,
        shoppingUnit: ShoppingUnit.l,
        priceBasis: ShoppingUnit.l,
        notes: 'Buy full cream',
        isPurchased: true,
        position: 5,
      );

      final json = item.toJson();
      final reconstructed = ShoppingItem.fromJson(json);

      expect(reconstructed.id, item.id);
      expect(reconstructed.name, item.name);
      expect(reconstructed.quantity, item.quantity);
      expect(reconstructed.unit, item.unit);
      expect(reconstructed.price, item.price);
      expect(reconstructed.quantityValue, item.quantityValue);
      expect(reconstructed.priceValue, item.priceValue);
      expect(reconstructed.pricingMode, item.pricingMode);
      expect(reconstructed.shoppingUnit, item.shoppingUnit);
      expect(reconstructed.priceBasis, item.priceBasis);
      expect(reconstructed.notes, item.notes);
      expect(reconstructed.isPurchased, item.isPurchased);
      expect(reconstructed.position, item.position);
    });

    test('ShoppingItem fromJson handles null optional fields', () {
      final json = {
        'id': 'test-id-null',
        'name': 'Bread',
        'isPurchased': false,
        'pricingMode': 'total',
        'position': 0,
      };
      
      final item = ShoppingItem.fromJson(json);
      
      expect(item.id, 'test-id-null');
      expect(item.name, 'Bread');
      expect(item.quantity, isNull);
      expect(item.shoppingUnit, isNull);
      expect(item.priceValue, isNull);
    });

    test('Unpriced items survive serialization', () {
      final item = const ShoppingItem(
        id: 'orange-1',
        name: 'Orange',
        quantityValue: 6,
        shoppingUnit: ShoppingUnit.pcs,
        pricingMode: PricingMode.total,
        priceValue: null,
      );

      final json = item.toJson();
      final reconstructed = ShoppingItem.fromJson(json);

      expect(reconstructed.name, 'Orange');
      expect(reconstructed.quantityValue, 6.0);
      expect(reconstructed.shoppingUnit, ShoppingUnit.pcs);
      expect(reconstructed.priceValue, isNull);
      expect(reconstructed.pricing.resolvedUnitSymbol, 'pc');
    });
  });
}
