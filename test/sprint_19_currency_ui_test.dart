import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/app.dart';
import 'package:shoptrack/core/currency/currency_catalog.dart';
import 'package:shoptrack/core/currency/currency_item_groups.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/core/utils/number_formatter.dart';
import 'package:shoptrack/core/widgets/currency_picker_dialog.dart';
import 'package:shoptrack/core/widgets/compact_amount_text.dart';
import 'package:shoptrack/features/history/presentation/widgets/session_card.dart';
import 'package:shoptrack/features/home/presentation/widgets/add_item_sheet.dart';
import 'package:shoptrack/features/home/presentation/widgets/shopping_item_tile.dart';
import 'package:shoptrack/features/home/presentation/pages/home_page.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';
import 'package:shoptrack/models/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('currency picker prioritizes default and recent currencies', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showCurrencyPickerDialog(
                context,
                selectedCurrencyCode: 'EUR',
                defaultCurrencyCode: 'BDT',
                recentCurrencyCodes: const ['EUR', 'USD'],
              ),
              child: const Text('Choose'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();

    expect(find.text('(default)'), findsOneWidget);
    expect(find.text('Recent'), findsNWidgets(2));
    final bdtTop = tester.getTopLeft(
      find.byKey(const ValueKey('currency_option_BDT')),
    );
    final eurTop = tester.getTopLeft(
      find.byKey(const ValueKey('currency_option_EUR')),
    );
    final usdTop = tester.getTopLeft(
      find.byKey(const ValueKey('currency_option_USD')),
    );
    expect(bdtTop.dy, lessThan(eurTop.dy));
    expect(eurTop.dy, lessThan(usdTop.dy));

    await tester.enterText(
      find.byKey(const ValueKey('currency_search_field')),
      'JPY',
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('currency_option_JPY')), findsOneWidget);
    expect(find.byKey(const ValueKey('currency_option_BDT')), findsNothing);
  });

  for (final scenario in <(String, Size)>[
    ('narrow portrait', const Size(320, 640)),
    ('short landscape', const Size(640, 360)),
  ]) {
    testWidgets('currency picker fits ${scenario.$1} at 1.3x text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(scenario.$2);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemePresets.darkPresets[DarkPreset.deepForest]!.toThemeData(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => FilledButton(
                onPressed: () => showCurrencyPickerDialog(
                  context,
                  selectedCurrencyCode: 'BDT',
                  defaultCurrencyCode: 'BDT',
                  recentCurrencyCodes: const ['USD', 'EUR'],
                ),
                child: const Text('Choose'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('currency_search_field')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Add Item starts with default and saves the chosen currency', (
    tester,
  ) async {
    ShoppingItem? saved;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.lightPresets[LightPreset.summer]!.toThemeData(),
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                saved = await showModalBottomSheet<ShoppingItem>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const AddItemSheet(
                    nextPosition: 0,
                    defaultCurrencyCode: 'USD',
                    recentCurrencyCodes: ['EUR'],
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Item Name'), 'Tea');
    await tester.tap(find.text('More Options'));
    await tester.pumpAndSettle();
    expect(find.textContaining('USD'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('item_currency_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('currency_search_field')),
      'EUR',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('currency_option_EUR')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('item_price_field')),
      '12.50',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.currencyCode, 'EUR');
    expect(saved!.priceValue, 12.5);
  });

  testWidgets('Profile Currency opens the searchable default picker', (
    tester,
  ) async {
    await tester.pumpWidget(const ShopTrackApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Currency'));
    await tester.pumpAndSettle();

    expect(find.text('Default Currency'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('currency_search_field')),
      'USD',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('currency_option_USD')));
    await tester.pumpAndSettle();

    expect(find.textContaining('USD ·'), findsOneWidget);
  });

  testWidgets('History displays mixed purchased totals separately', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    final session = ShoppingSession(
      id: 'mixed',
      date: DateTime(now.year, now.month, now.day),
      items: const [
        ShoppingItem(
          id: 'bdt',
          name: 'Rice',
          priceValue: 300,
          currencyCode: 'BDT',
          isPurchased: true,
          position: 0,
        ),
        ShoppingItem(
          id: 'usd',
          name: 'Coffee',
          priceValue: 5,
          currencyCode: 'USD',
          isPurchased: true,
          position: 1,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.lightPresets[LightPreset.summer]!.toThemeData(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 500,
            child: SessionCard(session: session, onTap: () {}, onEdit: () {}),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final bdtLabel = NumberFormatter.formatPrice(300, currencyCode: 'BDT');
    final usdLabel = NumberFormatter.formatPrice(5, currencyCode: 'USD');
    expect(find.text('BDT'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(find.text(bdtLabel), findsOneWidget);
    expect(find.text(usdLabel), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Total Purchased')).dy,
      lessThan(tester.getTopLeft(find.text(bdtLabel)).dy),
    );
    expect(
      tester.getTopLeft(find.text(usdLabel)).dx,
      lessThan(tester.getTopLeft(find.byIcon(Icons.more_vert)).dx),
    );
  });

  test('catalogue still offers a broad set of payment currencies', () {
    expect(CurrencyCatalog.all.length, greaterThan(140));
  });

  test(
    'currency groups keep the preferred currency first and do not mix items',
    () {
      const items = [
        ShoppingItem(id: 'eur-1', name: 'A', currencyCode: 'EUR', position: 0),
        ShoppingItem(id: 'bdt-1', name: 'B', currencyCode: 'BDT', position: 1),
        ShoppingItem(id: 'eur-2', name: 'C', currencyCode: 'EUR', position: 2),
      ];
      final groups = groupItemsByCurrency(items, preferredCurrencyCode: 'BDT');
      expect(groups.keys.toList(), ['BDT', 'EUR']);
      expect(groups['BDT']!.map((item) => item.id), ['bdt-1']);
      expect(groups['EUR']!.map((item) => item.id), ['eur-1', 'eur-2']);
    },
  );

  test('compact display never changes the full amount or persisted number', () {
    expect(
      NumberFormatter.formatDisplayPrice(1680289, currencyCode: 'USD'),
      '\$1.68M',
    );
    expect(
      NumberFormatter.formatPrice(1680289, currencyCode: 'USD'),
      '\$1,680,289',
    );
    expect(
      NumberFormatter.formatDisplayPrice(
        1680289,
        currencyCode: 'BDT',
        preference: NumberFormatPreference.southAsian,
      ),
      '৳16.8 Lakh',
    );
    expect(
      NumberFormatter.formatPrice(
        1680289,
        currencyCode: 'BDT',
        preference: NumberFormatPreference.southAsian,
      ),
      '৳16,80,289',
    );
    expect(
      NumberFormatter.formatDisplayPrice(
        1680289,
        currencyCode: 'ABC',
        includeCode: true,
      ),
      'ABC 1.68M',
    );
    expect(
      AppSettings.fromJson(
        const AppSettings(
          numberFormat: NumberFormatPreference.southAsian,
        ).toJson(),
      ).numberFormat,
      NumberFormatPreference.southAsian,
    );
  });

  testWidgets('tapping a compact value reveals its full amount in a popup', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 120,
              child: CompactAmountText(
                value: 1680289,
                currencyCode: 'USD',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('\$1.68M'), findsOneWidget);
    await tester.tap(find.text('\$1.68M'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('\$1,680,289'), findsOneWidget);
  });

  testWidgets('amounts use full digits when the row has room', (tester) async {
    Future<void> showAtWidth(double width) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: const CompactAmountText(
                  value: 1680289,
                  currencyCode: 'USD',
                  preference: NumberFormatPreference.international,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await showAtWidth(240);
    expect(find.text('\$1,680,289'), findsOneWidget);
    await showAtWidth(75);
    expect(find.text('\$1.68M'), findsOneWidget);
  });

  test('Automatic chooses number formatting for each currency', () {
    expect(
      NumberFormatter.formatPrice(1234567, currencyCode: 'BDT'),
      '৳12,34,567',
    );
    expect(
      NumberFormatter.formatPrice(1234567, currencyCode: 'USD'),
      '\$1,234,567',
    );
    expect(
      NumberFormatter.formatPrice(1234567, currencyCode: 'EUR'),
      contains('1.234.567'),
    );
    expect(
      NumberFormatter.formatDisplayPrice(1680289, currencyCode: 'JPY'),
      contains('万'),
    );
    expect(
      NumberFormatter.formatPrice(
        1234567,
        currencyCode: 'BDT',
        preference: NumberFormatPreference.international,
      ),
      '৳1,234,567',
    );
  });

  test('Automatic has a usable locale for every catalogue currency', () {
    for (final currency in CurrencyCatalog.all) {
      expect(
        () => NumberFormatter.formatPrice(
          1234567.89,
          currencyCode: currency.code,
        ),
        returnsNormally,
        reason: currency.code,
      );
      expect(
        () => NumberFormatter.formatDisplayPrice(
          1234567.89,
          currencyCode: currency.code,
        ),
        returnsNormally,
        reason: currency.code,
      );
    }
  });

  testWidgets('large item amounts stay inside a narrow tile at 1.3x text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const item = ShoppingItem(
      id: 'large',
      name: 'A long shopping item name that must not collide with the price',
      quantityValue: 999999,
      priceValue: 99999999.99,
      currencyCode: 'BDT',
      position: 0,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.darkPresets[DarkPreset.midnight]!.toThemeData(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(
          body: ReorderableListView(
            onReorderItem: (_, _) {},
            buildDefaultDragHandles: false,
            children: [
              ShoppingItemTile(
                key: const ValueKey('tile'),
                item: item,
                index: 0,
                onToggle: () {},
                onTap: () {},
                onDelete: () {},
              ),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('৳9.99 Crore'), findsOneWidget);
  });

  testWidgets('Lists gives each currency its own reorder boundary and totals', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final date = DateTime(2026, 9, 20);
    final session = ShoppingSession(
      id: 'currency-groups',
      date: date,
      items: const [
        ShoppingItem(
          id: 'bdt-1',
          name: 'Rice',
          currencyCode: 'BDT',
          priceValue: 90,
          position: 0,
        ),
        ShoppingItem(
          id: 'bdt-2',
          name: 'Eggs',
          currencyCode: 'BDT',
          priceValue: 20,
          position: 1,
        ),
        ShoppingItem(
          id: 'eur-1',
          name: 'Coffee',
          currencyCode: 'EUR',
          priceValue: 5,
          position: 2,
        ),
        ShoppingItem(
          id: 'bdt-3',
          name: 'Milk',
          currencyCode: 'BDT',
          priceValue: 30,
          position: 3,
          isPurchased: true,
        ),
        ShoppingItem(
          id: 'eur-2',
          name: 'Bread',
          currencyCode: 'EUR',
          priceValue: 2,
          position: 4,
          isPurchased: true,
        ),
      ],
    );
    SharedPreferences.setMockInitialValues({
      'shopping_sessions': jsonEncode([session.toJson()]),
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.darkPresets[DarkPreset.midnight]!.toThemeData(),
        home: HomePage(sessionDate: date),
      ),
    );
    await tester.pumpAndSettle();

    for (final code in ['BDT', 'EUR']) {
      for (final purchased in [false, true]) {
        expect(
          find.byKey(ValueKey('currency_group_${code}_$purchased')),
          findsOneWidget,
        );
      }
    }
    expect(find.text('BDT · Taka'), findsNWidgets(2));
    expect(find.text('EUR · Euro'), findsNWidgets(2));
    expect(find.text('Purchased Amount'), findsOneWidget);
    expect(find.text('৳110'), findsOneWidget);
    final receiptHeading = tester.getRect(find.text('Purchased Amount'));
    final receiptWallet = tester.getRect(find.byIcon(Icons.wallet_outlined));
    final receipt = tester.getRect(
      find.byKey(const ValueKey('purchased_amount_receipt')),
    );
    final groupCenter = (receiptWallet.left + receiptHeading.right) / 2;
    expect(groupCenter, closeTo(receipt.center.dx, 2));
    final totalHeading = tester.getRect(find.text('Total Amount'));
    expect(totalHeading.right, closeTo(receipt.right, 24));
    final bdtPending = tester.widget<ReorderableListView>(
      find.byKey(const ValueKey('currency_group_BDT_false')),
    );
    bdtPending.onReorderItem!(0, 1);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Eggs')).dy,
      lessThan(tester.getTopLeft(find.text('Rice')).dy),
    );
    expect(find.text('Coffee'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mixed-currency Lists totals fit narrow 1.3x layouts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final date = DateTime(2026, 9, 20);
    final session = ShoppingSession(
      id: 'narrow-totals',
      date: date,
      items: const [
        ShoppingItem(
          id: 'bdt-pending',
          name: 'Rice',
          currencyCode: 'BDT',
          priceValue: 6900000,
          position: 0,
        ),
        ShoppingItem(
          id: 'eur-pending',
          name: 'Coffee',
          currencyCode: 'EUR',
          priceValue: 1680289,
          position: 1,
        ),
        ShoppingItem(
          id: 'bdt-purchased',
          name: 'Bread',
          currencyCode: 'BDT',
          priceValue: 6900000,
          position: 2,
          isPurchased: true,
        ),
        ShoppingItem(
          id: 'eur-purchased',
          name: 'Milk',
          currencyCode: 'EUR',
          priceValue: 1680289,
          position: 3,
          isPurchased: true,
        ),
      ],
    );
    SharedPreferences.setMockInitialValues({
      'shopping_sessions': jsonEncode([session.toJson()]),
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.darkPresets[DarkPreset.midnight]!.toThemeData(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: HomePage(sessionDate: date),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Total Amount'), findsOneWidget);
    final scrollable = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    for (var i = 0; i < 8 && find.text('Purchased Amount').evaluate().isEmpty; i++) {
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();
    }
    expect(find.text('Purchased Amount'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
