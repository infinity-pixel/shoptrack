import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/currency/currency_totals.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';
import 'package:shoptrack/core/utils/large_amount_guard.dart';
import 'package:shoptrack/core/utils/number_formatter.dart';
import 'package:shoptrack/core/widgets/scroll_aware_fab.dart';
import 'package:shoptrack/models/shopping_item.dart';

void main() {
  test('FAB waits for deliberate movement and uses reversed direction', () {
    final motion = FabScrollIntent();
    expect(motion.update(-20, atStart: false), isNull);
    expect(motion.update(-28, atStart: false), isNull);
    expect(motion.update(-48, atStart: false), isFalse);
    expect(motion.update(20, atStart: false), isNull);
    expect(motion.update(28, atStart: false), isNull);
    expect(motion.update(48, atStart: false), isTrue);
    expect(motion.update(-90, atStart: true), isTrue);
  });

  test('very large round prices and totals remain exact', () {
    const price = '25000000000000';
    const quantity = '10000';
    const total = 250000000000000000.0;
    expect(LargeAmountGuard.canStore(price, double.parse(price)), isTrue);
    expect(LargeAmountGuard.canStore(quantity, double.parse(quantity)), isTrue);
    expect(
      LargeAmountGuard.canStoreCalculatedTotal(
        price: price,
        quantity: quantity,
        calculatedTotal: total,
        mode: PricingMode.unit,
        unit: ShoppingUnit.pcs,
        priceBasis: ShoppingUnit.pcs,
      ),
      isTrue,
    );
    final item = ShoppingItem(
      id: 'large',
      name: 'Omelette',
      quantity: quantity,
      quantityValue: double.parse(quantity),
      priceValue: double.parse(price),
      currencyCode: 'JPY',
      pricingMode: PricingMode.unit,
      shoppingUnit: ShoppingUnit.pcs,
      priceBasis: ShoppingUnit.pcs,
    );
    expect(item.pricing.totalPrice, total);
    expect(
      CurrencyTotals.fromItems([item])['JPY']!.minorUnits,
      BigInt.parse('250000000000000000'),
    );
    expect(
      NumberFormatter.formatPrice(total, currencyCode: 'JPY'),
      '¥250,000,000,000,000,000',
    );
    expect(ShoppingItem.fromJson(item.toJson()).pricing.totalPrice, total);
  });

  test('unsafe final digits are refused instead of silently rounded', () {
    expect(
      LargeAmountGuard.canStore('250000000000000001', 250000000000000000.0),
      isFalse,
    );
    expect(
      LargeAmountGuard.canStoreCalculatedTotal(
        price: '25000000000000.01',
        quantity: '10000',
        calculatedTotal: 250000000000000096.0,
        mode: PricingMode.unit,
        unit: ShoppingUnit.pcs,
        priceBasis: ShoppingUnit.pcs,
      ),
      isFalse,
    );
  });

  testWidgets('split FAB animates its label without losing the share arrow', (
    tester,
  ) async {
    var expanded = true;
    var shared = false;
    Widget harness() => MaterialApp(
      home: Scaffold(
        floatingActionButton: ShoppingSplitFab(
          expanded: expanded,
          onAddPressed: () {},
          onSharePressed: () => shared = true,
        ),
      ),
    );
    await tester.pumpWidget(harness());
    final wide = tester.getSize(find.byKey(const ValueKey('split-main-fab')));
    expanded = false;
    await tester.pumpWidget(harness());
    await tester.pump(const Duration(milliseconds: 100));
    final during = tester.getSize(find.byKey(const ValueKey('split-main-fab')));
    expect(during.width, lessThan(wide.width));
    expect(during.width, greaterThan(103));
    await tester.pumpAndSettle();
    final compact = tester.getSize(
      find.byKey(const ValueKey('split-main-fab')),
    );
    expect(compact.width, 103);
    await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('share-fab-action')));
    await tester.pumpAndSettle();
    expect(shared, isTrue);
  });

  testWidgets('Bangla UI copy changes without translating a user item', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('bn', 'BD'),
        supportedLocales: [Locale('en', 'US'), Locale('bn', 'BD')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Column(children: [ShopText('Add Item'), Text('Save')]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('পণ্য যোগ করুন'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('only the canonical default list is displayed in Bangla', (
    tester,
  ) async {
    late BuildContext localizedContext;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bn', 'BD'),
        supportedLocales: const [Locale('en', 'US'), Locale('bn', 'BD')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            localizedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(
      shopListName(localizedContext, id: 'default-list', name: 'My List'),
      'আমার তালিকা',
    );
    expect(
      shopListName(localizedContext, id: 'custom', name: 'My List'),
      'My List',
    );
    expect(
      shopListName(localizedContext, id: 'default-list', name: 'Groceries'),
      'Groceries',
    );
  });
}
