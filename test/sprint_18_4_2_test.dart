import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/data/shopping_repository.dart';
import 'package:shoptrack/core/data/sync_store.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/core/utils/shopping_list_text_formatter.dart';
import 'package:shoptrack/features/history/presentation/pages/history_page.dart';
import 'package:shoptrack/features/home/presentation/pages/home_page.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_list_group.dart';
import 'package:shoptrack/models/shopping_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocalShoppingRepository.activeStore = null;
  });

  tearDown(() => LocalShoppingRepository.activeStore = null);

  test(
    'plain-text sharing preserves lists, states, quantities, notes and totals',
    () {
      final session = ShoppingSession(
        id: 'share',
        date: DateTime(2026, 9, 19),
        lists: const [
          ShoppingListGroup.defaultList,
          ShoppingListGroup(id: 'family', name: 'Family', position: 1),
        ],
        items: const [
          ShoppingItem(
            id: 'rice',
            name: 'Rice',
            quantity: '2.5',
            quantityValue: 2.5,
            shoppingUnit: ShoppingUnit.kg,
            priceBasis: ShoppingUnit.kg,
            priceValue: 80,
            pricingMode: PricingMode.unit,
            notes: 'Fine grain',
          ),
          ShoppingItem(
            id: 'soap',
            name: 'Soap',
            listId: 'family',
            priceValue: 45,
            isPurchased: true,
          ),
        ],
      );

      final text = ShoppingListTextFormatter.format(session);
      expect(text, contains('ShopTrack — Saturday, 19 September 2026'));
      expect(text, contains('My List\nTo Buy'));
      expect(text, contains('☐ Rice — 2.5 kg — ৳200'));
      expect(text, contains('Note: Fine grain'));
      expect(text, contains('Family\nPurchased'));
      expect(text, contains('☑ Soap — ৳45'));
      expect(text, contains('Pending total: ৳200'));
      expect(text, contains('Purchased total: ৳45'));
    },
  );

  test('all themes provide consistent modal surfaces', () {
    for (final definition in [
      ...ThemePresets.lightPresets.values,
      ...ThemePresets.darkPresets.values,
    ]) {
      final theme = definition.toThemeData();
      expect(theme.dialogTheme.backgroundColor, definition.palette.surface);
      expect(
        theme.bottomSheetTheme.backgroundColor,
        definition.palette.surface,
      );
      expect(theme.popupMenuTheme.color, definition.palette.surface);
    }
  });

  testWidgets('History places Upcoming before Today', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessions = [
      ShoppingSession(
        id: 'today',
        date: today,
        items: const [ShoppingItem(id: 'today-item', name: 'Milk')],
      ),
      ShoppingSession(
        id: 'future',
        date: today.add(const Duration(days: 1)),
        items: const [ShoppingItem(id: 'future-item', name: 'Rice')],
      ),
    ];
    final store = SyncStore(await SharedPreferences.getInstance(), 'history');
    await store.load(seed: sessions);
    LocalShoppingRepository.activeStore = store;
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.lightPresets.values.first.toThemeData(),
        home: HistoryPage(onSessionSelected: (_) {}),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      tester.getTopLeft(find.text('UPCOMING')).dy,
      lessThan(tester.getTopLeft(find.text('TODAY')).dy),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    store.dispose();
  });

  for (final size in [const Size(320, 640), const Size(640, 360)]) {
    testWidgets('share sheet fits $size at 1.3 text scale', (tester) async {
      final date = DateTime(2026, 9, 19);
      final session = ShoppingSession(
        id: 'share-sheet',
        date: date,
        items: const [ShoppingItem(id: 'milk', name: 'Milk')],
      );
      final store = SyncStore(await SharedPreferences.getInstance(), 'share');
      await store.load(seed: [session]);
      LocalShoppingRepository.activeStore = store;
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemePresets.darkPresets.values.first.toThemeData(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.3)),
            child: child!,
          ),
          home: HomePage(sessionDate: date),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Copy or share shopping list'));
      await tester.pumpAndSettle();

      expect(find.text('Share Shopping List'), findsOneWidget);
      expect(find.text('Copy as Text'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      store.dispose();
    });
  }
}
