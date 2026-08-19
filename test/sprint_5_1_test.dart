import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/app.dart';
import 'package:shoptrack/models/shopping_item.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  group('Sprint 5.1: Pricing Logic & Basis Defaults', () {
    test('350 g + Total Price ৳15 → Price per kg ৳42.86/kg', () {
      final item = const ShoppingItem(
        id: '1',
        name: 'Bitter Gourd',
        quantityValue: 350,
        priceValue: 15,
        pricingMode: PricingMode.total,
        shoppingUnit: ShoppingUnit.g,
      );
      final pricing = item.pricing;
      expect(pricing.totalPrice, 15.0);
      expect(pricing.unitPrice.toStringAsFixed(2), '42.86');
      expect(pricing.priceBasisSymbol, 'kg');
    });

    test('500 mL + Total Price ৳50 → Price per L ৳100/L', () {
      final item = const ShoppingItem(
        id: '2',
        name: 'Milk',
        quantityValue: 500,
        priceValue: 50,
        pricingMode: PricingMode.total,
        shoppingUnit: ShoppingUnit.ml,
      );
      final pricing = item.pricing;
      expect(pricing.totalPrice, 50.0);
      expect(pricing.unitPrice, 100.0);
      expect(pricing.priceBasisSymbol, 'L');
    });

    test('Unit Test: Active and Purchased Amounts', () {
      final milk = const ShoppingItem(
        id: '3',
        name: 'Milk',
        quantityValue: 3,
        priceValue: 100,
        pricingMode: PricingMode.unit,
        shoppingUnit: ShoppingUnit.kg,
        isPurchased: false,
      );
      final eggs = const ShoppingItem(
        id: '4',
        name: 'Eggs',
        quantityValue: 30,
        priceValue: 12.50,
        pricingMode: PricingMode.unit,
        shoppingUnit: ShoppingUnit.pcs,
        isPurchased: false,
      );

      final items = [milk, eggs];

      // Both active
      double totalAmount = items
          .where((i) => !i.isPurchased)
          .fold(0.0, (sum, i) => sum + i.pricing.totalPrice);
      double purchasedAmount = items
          .where((i) => i.isPurchased)
          .fold(0.0, (sum, i) => sum + i.pricing.totalPrice);
      
      expect(totalAmount, 675.0);
      expect(purchasedAmount, 0.0);

      // Check Milk
      final milkPurchased = milk.copyWith(isPurchased: true);
      final itemsAfterCheck = [milkPurchased, eggs];
      
      totalAmount = itemsAfterCheck
          .where((i) => !i.isPurchased)
          .fold(0.0, (sum, i) => sum + i.pricing.totalPrice);
      purchasedAmount = itemsAfterCheck
          .where((i) => i.isPurchased)
          .fold(0.0, (sum, i) => sum + i.pricing.totalPrice);
          
      expect(totalAmount, 375.0);
      expect(purchasedAmount, 300.0);

      // Check Eggs
      final eggsPurchased = eggs.copyWith(isPurchased: true);
      final itemsAllPurchased = [milkPurchased, eggsPurchased];
      
      totalAmount = itemsAllPurchased
          .where((i) => !i.isPurchased)
          .fold(0.0, (sum, i) => sum + i.pricing.totalPrice);
      purchasedAmount = itemsAllPurchased
          .where((i) => i.isPurchased)
          .fold(0.0, (sum, i) => sum + i.pricing.totalPrice);
          
      expect(totalAmount, 0.0);
      expect(purchasedAmount, 675.0);
    });
  });

  group('Sprint 5.1: UI States', () {
    testWidgets('Empty state appears when no items at all', (WidgetTester tester) async {
      await tester.pumpWidget(const ShopTrackApp());
      // Wait for loading to finish (LocalShoppingRepository is async)
      await tester.pump(); 
      await tester.pump(); // Second pump to catch the state update after the future completes
      expect(find.text('No items yet'), findsOneWidget);
    });
  });
}
