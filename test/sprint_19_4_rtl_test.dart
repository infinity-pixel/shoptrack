import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/core/utils/numeric_input.dart';
import 'package:shoptrack/core/widgets/scroll_aware_fab.dart';
import 'package:shoptrack/features/history/presentation/widgets/session_card.dart';
import 'package:shoptrack/features/home/presentation/widgets/add_item_sheet.dart';
import 'package:shoptrack/features/home/presentation/widgets/record_hero.dart';
import 'package:shoptrack/features/home/presentation/widgets/shopping_item_tile.dart';
import 'package:shoptrack/features/home/presentation/widgets/shopping_list_switcher.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_list_group.dart';
import 'package:shoptrack/models/shopping_session.dart';

Widget _app(Widget child, {bool dark = false, double scale = 1.3}) {
  var theme =
      (dark
              ? ThemePresets.darkPresets.values.first
              : ThemePresets.lightPresets.values.first)
          .toThemeData();
  const font = String.fromEnvironment('SHOPTRACK_PREVIEW_FONT');
  if (font.isNotEmpty) {
    theme = theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: 'ArabicPreview'),
    );
  }
  return MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('en'), Locale('bn'), Locale('ar')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: theme,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: child,
  );
}

ShoppingItem _item() => ShoppingItem(
  id: 'rtl-item',
  name: 'تفاح',
  quantity: '3',
  quantityValue: 3,
  priceValue: 123.45,
  currencyCode: 'SAR',
  shoppingUnit: ShoppingUnit.kg,
);

void main() {
  test('keyboard normalization does not change stored numeral meaning', () {
    expect(normalizeNumericInput('١٢٣٫٤٥'), '123.45');
    expect(normalizeNumericInput('১১২.৫০'), '112.50');
    expect(normalizeNumericInput('۲۵٬۰۰۰'), '25000');
  });

  testWidgets(
    'Arabic item controls and split FAB mirror without losing actions',
    (tester) async {
      var expanded = true;
      var shared = false;
      Widget harness() => _app(
        Scaffold(
          body: Column(
            children: [
              ShoppingListSwitcher(
                lists: const [
                  ShoppingListGroup(
                    id: 'default-list',
                    name: 'My List',
                    position: 0,
                  ),
                ],
                activeListId: 'default-list',
                itemCountForList: (_) => 1,
                onSelected: (_) {},
                onCreate: () {},
                onManage: (_) {},
              ),
              ShoppingItemTile(
                item: _item(),
                onToggle: () {},
                onTap: () {},
                onDelete: () {},
                index: 0,
              ),
            ],
          ),
          floatingActionButton: ShoppingSplitFab(
            expanded: expanded,
            onAddPressed: () {},
            onSharePressed: () => shared = true,
          ),
        ),
      );
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      final drag = tester.getCenter(find.byIcon(Icons.drag_indicator));
      final name = tester.getCenter(find.text('تفاح'));
      expect(drag.dx, greaterThan(name.dx));
      expect(
        tester.getCenter(find.byIcon(Icons.playlist_add)).dx,
        lessThan(tester.getCenter(find.byType(ChoiceChip)).dx),
      );
      final button = find.byKey(const ValueKey('split-main-fab'));
      expect(tester.getCenter(button).dx, lessThan(400));
      expect(
        tester.getCenter(find.byIcon(Icons.keyboard_arrow_up_rounded)).dx,
        lessThan(tester.getCenter(find.byIcon(Icons.add)).dx),
      );
      expanded = false;
      await tester.pumpWidget(harness());
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getSize(button).width, greaterThan(103));
      await tester.pumpAndSettle();
      expect(tester.getSize(button).width, 103);
      await tester.tap(find.byIcon(Icons.keyboard_arrow_up_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('share-fab-action')));
      expect(shared, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Arabic numeric editing accepts local digits and saves invariant values',
    (tester) async {
      ShoppingItem? saved;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  saved = await showModalBottomSheet<ShoppingItem>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) =>
                        AddItemSheet(nextPosition: 0, initialItem: _item()),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final quantity = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == shopTrLanguage('ar', 'Quantity'),
      );
      await tester.enterText(quantity, '٢٥');
      await tester.enterText(
        find.byKey(const ValueKey('item_price_field')),
        '١٢٣٫٤٥',
      );
      expect(tester.widget<TextField>(quantity).controller!.text, '٢٥');
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('item_price_field')))
            .controller!
            .text,
        '١٢٣.٤٥',
      );
      final save = find.text(shopTrLanguage('ar', 'Save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      expect(saved!.quantity, '25');
      expect(saved!.quantityValue, 25);
      expect(saved!.priceValue, 123.45);
      expect(saved!.name, 'تفاح');
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(320, 640), const Size(640, 360)]) {
    for (final dark in [false, true]) {
      testWidgets('Arabic headers, cards and editor fit $size dark=$dark', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final session = ShoppingSession(
          id: 'rtl',
          date: DateTime(2026, 9, 26),
          items: [_item().copyWith(isPurchased: true)],
        );
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: ListView(
                children: [
                  RecordHero(date: session.date, onBack: () {}),
                  SessionCard(session: session, onTap: () {}, onDelete: () {}),
                  ShoppingItemTile(
                    item: _item(),
                    onToggle: () {},
                    onTap: () {},
                    onDelete: () {},
                    index: 0,
                  ),
                ],
              ),
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<Image>(find.byType(Image).first).matchTextDirection,
          isTrue,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          _app(
            Scaffold(body: AddItemSheet(nextPosition: 0, initialItem: _item())),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  const font = String.fromEnvironment('SHOPTRACK_PREVIEW_FONT');
  testWidgets('Arabic RTL visual preview', (tester) async {
    final loader = FontLoader('ArabicPreview')
      ..addFont(
        Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
      );
    await loader.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final session = ShoppingSession(
      id: 'rtl',
      date: DateTime(2026, 9, 26),
      items: [_item().copyWith(isPurchased: true)],
    );
    final boundary = GlobalKey();
    await tester.pumpWidget(
      _app(
        RepaintBoundary(
          key: boundary,
          child: Scaffold(
            body: ListView(
              children: [
                RecordHero(date: session.date, onBack: () {}),
                const SizedBox(height: 16),
                SessionCard(session: session, onTap: () {}, onDelete: () {}),
                ShoppingItemTile(
                  item: _item(),
                  onToggle: () {},
                  onTap: () {},
                  onDelete: () {},
                  index: 0,
                ),
              ],
            ),
            floatingActionButton: ShoppingSplitFab(
              expanded: true,
              onAddPressed: () {},
              onSharePressed: () {},
            ),
          ),
        ),
        dark: true,
        scale: 1,
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/theme_dark_silent_midnight.webp'),
        tester.element(find.byType(RecordHero)),
      );
    });
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/sprint_19_4').create(recursive: true);
      await File(
        'build/sprint_19_4/arabic_rtl.png',
      ).writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  }, skip: font.isEmpty);
}
