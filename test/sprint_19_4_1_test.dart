import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/app.dart';
import 'package:shoptrack/core/calendar/shop_calendar.dart';
import 'package:shoptrack/core/currency/currency_catalog.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/core/widgets/compact_amount_text.dart';
import 'package:shoptrack/core/widgets/confirm_app_exit.dart';
import 'package:shoptrack/core/widgets/scroll_aware_fab.dart';
import 'package:shoptrack/core/widgets/shoptrack_date_picker.dart';
import 'package:shoptrack/features/history/presentation/widgets/history_date_badge.dart';
import 'package:shoptrack/features/history/presentation/widgets/session_card.dart';
import 'package:shoptrack/features/home/presentation/widgets/add_item_sheet.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_search_result.dart';
import 'package:shoptrack/models/shopping_session.dart';
import 'package:shoptrack/services/search_service.dart';

import 'sprint_13_test.dart' show MockShoppingRepository;

Widget _app(Widget child, {String language = 'en', bool dark = false}) {
  var theme =
      (dark
              ? ThemePresets.darkPresets.values.first
              : ThemePresets.lightPresets.values.first)
          .toThemeData();
  if (const String.fromEnvironment('SHOPTRACK_PREVIEW_FONT').isNotEmpty) {
    theme = theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: 'Preview'),
    );
  }
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    locale: Locale(language),
    supportedLocales: const [Locale('en'), Locale('bn'), Locale('ar')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: const TextScaler.linear(1.3)),
      child: child!,
    ),
    home: child,
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('top boundary cannot expand a collapsed FAB', () {
    final intent = FabScrollIntent();
    expect(intent.update(-100, atStart: false), false);
    expect(intent.update(-10, atStart: true), isNull);
    expect(intent.update(30, atStart: true), isNull);
    expect(intent.update(40, atStart: false), isNull);
    expect(intent.update(56, atStart: false), true);
  });

  test(
    'No Price is independent and combines with name, status and date',
    () async {
      final day = DateTime(2020, 1, 2);
      final service = SearchService(
        MockShoppingRepository([
          ShoppingSession(
            id: 's',
            date: day,
            items: const [
              ShoppingItem(id: 'missing', name: 'Milk'),
              ShoppingItem(id: 'bought', name: 'Milk', isPurchased: true),
              ShoppingItem(id: 'zero', name: 'Milk', priceValue: 0),
              ShoppingItem(id: 'legacy', name: 'Milk', price: '0'),
              ShoppingItem(id: 'priced', name: 'Milk', priceValue: 20),
            ],
          ),
        ]),
      );
      expect(
        (await service.searchItems(
          query: '',
          noPriceOnly: true,
        )).map((r) => r.item.id),
        unorderedEquals(['missing', 'bought']),
      );
      expect(
        (await service.searchItems(
          query: 'milk',
          noPriceOnly: true,
          statusFilter: SearchItemStatus.purchased,
          dateRange: DateTimeRange(start: day, end: day),
        )).single.item.id,
        'bought',
      );
      expect(
        await service.searchItems(query: 'eggs', noPriceOnly: true),
        isEmpty,
      );
    },
  );

  test(
    'missing states and new actions have Bangla and Arabic translations',
    () {
      for (final language in ['bn', 'ar']) {
        for (final text in [
          'No Price',
          'Close ShopTrack?',
          'Do you want to close the app?',
          'No items yet',
          'Tap + to add your first item.',
          'Shopping Completed',
          'All items have been purchased.',
        ]) {
          expect(
            shopTrLanguage(language, text),
            isNot(text),
            reason: '$language: $text',
          );
        }
      }
      expect(shopTrLanguage('ar', 'Millilitre (mL)'), 'مليلتر (mL)');
    },
  );

  test('four current currency signs retain ISO ownership codes', () {
    for (final pair in {
      'SAR': 0x20C1,
      'MVR': 0x20C2,
      'AED': 0x20C3,
      'OMR': 0x20C4,
    }.entries) {
      expect(CurrencyCatalog.resolve(pair.key).symbol.runes.single, pair.value);
      expect(CurrencyCatalog.resolve(pair.key).code, pair.key);
    }
  });

  testWidgets(
    'root Back confirms on every tab, cancel preserves app, close exits',
    (tester) async {
      var exits = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.pop') exits++;
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(const ShopTrackApp());
      await tester.pumpAndSettle();
      for (final tab in ['Lists', 'History', 'Profile']) {
        await tester.tap(find.text(tab).last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Close ShopTrack?'), findsOneWidget, reason: tab);
        await tester.tap(find.text('Cancel').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(exits, 0);
        expect(find.text(tab), findsWidgets);
      }
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Close').last);
      await tester.pumpAndSettle();
      expect(exits, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('exit dialog is localized and duplicate calls do not stack', (
    tester,
  ) async {
    late BuildContext root;
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (context) {
              root = context;
              return const Text('root');
            },
          ),
        ),
        language: 'ar',
      ),
    );
    await tester.pumpAndSettle();
    confirmAppExit(root);
    await tester.pumpAndSettle();
    await confirmAppExit(root);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(shopTrLanguage('ar', 'Close ShopTrack?')), findsOneWidget);
    await tester.tap(find.text(shopTrLanguage('ar', 'Cancel')));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'Arabic calendar arrows point outward and previous means previous',
    (tester) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: ShopTrackDatePicker(
              initialDate: DateTime(2026, 9, 27),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            ),
          ),
          language: 'ar',
        ),
      );
      await tester.pumpAndSettle();
      final previous = find.byTooltip(shopTrLanguage('ar', 'Previous month'));
      final next = find.byTooltip(shopTrLanguage('ar', 'Next month'));
      expect(
        tester.getCenter(previous).dx,
        greaterThan(tester.getCenter(next).dx),
      );
      final icon = tester.widget<Icon>(
        find.descendant(of: previous, matching: find.byType(Icon)),
      );
      expect(icon.icon, Icons.chevron_right);
      expect(icon.textDirection, TextDirection.ltr);
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(
        find.text(
          const ShopCalendar().format(
            DateTime(2026, 8, 1),
            pattern: 'MMMM yyyy',
            locale: 'ar',
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'long Arabic badge month uses local month number and full-date tooltip',
    (tester) async {
      await tester.pumpWidget(
        _app(
          Scaffold(body: HistoryDateBadge(date: DateTime(2026, 9, 27))),
          language: 'ar',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('٩'), findsOneWidget);
      expect(
        tester.widget<Tooltip>(find.byType(Tooltip)).message,
        contains('سبتمبر'),
      );
    },
  );

  testWidgets('RTL History amounts align with the row start', (tester) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: SessionCard(
            session: ShoppingSession(
              id: 's',
              date: DateTime(2020),
              items: const [
                ShoppingItem(
                  id: 'i',
                  name: 'x',
                  priceValue: 123,
                  currencyCode: 'SAR',
                  isPurchased: true,
                ),
              ],
            ),
            onTap: () {},
            onDelete: () {},
          ),
        ),
        language: 'ar',
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CompactAmountText>(find.byType(CompactAmountText).first)
          .textAlign,
      TextAlign.start,
    );
    expect(tester.takeException(), isNull);
  });

  for (final language in ['en', 'bn', 'ar']) {
    for (final size in [const Size(320, 640), const Size(640, 360)]) {
      testWidgets('complete currency labels fit $language $size at 1.3x', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        for (final code in ['XAF', 'UZS', 'MAD', 'SAR', 'AED', 'OMR', 'MVR']) {
          await tester.pumpWidget(
            _app(
              Scaffold(
                body: AddItemSheet(
                  key: ValueKey(code),
                  nextPosition: 0,
                  initialItem: ShoppingItem(
                    id: 'i',
                    name: 'x',
                    priceValue: 10,
                    currencyCode: code,
                  ),
                ),
              ),
              language: language,
              dark: true,
            ),
          );
          await tester.pumpAndSettle();
          final button = find.byKey(const ValueKey('item_currency_button'));
          final label = tester.widget<Text>(
            find.descendant(of: button, matching: find.byType(Text)).first,
          );
          expect(label.data, '$code ${CurrencyCatalog.resolve(code).symbol}');
          expect(label.overflow, isNot(TextOverflow.ellipsis));
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: button, matching: find.byType(RichText)).first,
          );
          expect(
            paragraph.didExceedMaxLines,
            isFalse,
            reason: '$language $code',
          );
          expect(tester.takeException(), isNull, reason: code);
        }
      });
    }
  }

  const previewFont = String.fromEnvironment('SHOPTRACK_PREVIEW_FONT');
  testWidgets(
    'render updated currency signs and Arabic calendar for visual review',
    (tester) async {
      for (final entry in {
        'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
        'ShopTrackCurrency': 'assets/fonts/ShopTrackCurrency.ttf',
        'ShopTrackRufiyaa': 'assets/fonts/ShopTrackRufiyaa.otf',
      }.entries) {
        final loader = FontLoader(entry.key)
          ..addFont(rootBundle.load(entry.value));
        await loader.load();
      }
      final data = File(previewFont).readAsBytesSync();
      await (FontLoader(
        'Preview',
      )..addFont(Future.value(ByteData.sublistView(data)))).load();
      await (FontLoader(
        'Roboto',
      )..addFont(Future.value(ByteData.sublistView(data)))).load();
      await tester.binding.setSurfaceSize(const Size(390, 820));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final boundary = GlobalKey();
      await tester.pumpWidget(
        _app(
          RepaintBoundary(
            key: boundary,
            child: Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    for (final code in ['SAR', 'AED', 'OMR', 'MVR'])
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Text(code),
                            const SizedBox(width: 20),
                            Expanded(
                              child: CompactAmountText(
                                value: 8403303.25,
                                currencyCode: code,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ShopTrackDatePicker(
                        initialDate: DateTime(2026, 9, 27),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          language: 'ar',
          dark: true,
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/sprint_19_4_1').create(recursive: true);
        await File(
          'build/sprint_19_4_1/currency_calendar.png',
        ).writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
      final cardBoundary = GlobalKey();
      await tester.pumpWidget(
        _app(
          RepaintBoundary(
            key: cardBoundary,
            child: Scaffold(
              body: SafeArea(
                child: Column(
                  children: [
                    SessionCard(
                      session: ShoppingSession(
                        id: 'preview',
                        date: DateTime(2026, 9, 27),
                        items: const [
                          ShoppingItem(
                            id: 'one',
                            name: 'تفاح',
                            priceValue: 8403303,
                            currencyCode: 'SAR',
                            isPurchased: true,
                          ),
                          ShoppingItem(
                            id: 'two',
                            name: 'Rice',
                            priceValue: 100,
                            currencyCode: 'BDT',
                            isPurchased: true,
                          ),
                        ],
                      ),
                      onTap: () {},
                      onDelete: () {},
                    ),
                    const Expanded(
                      child: AddItemSheet(
                        nextPosition: 0,
                        initialItem: ShoppingItem(
                          id: 'preview',
                          name: 'تفاح',
                          priceValue: 10,
                          currencyCode: 'SAR',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          language: 'ar',
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image =
            await (cardBoundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/sprint_19_4_1/history_editor.png',
        ).writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    },
    skip: previewFont.isEmpty,
  );
}
