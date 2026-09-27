import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/calendar/shop_calendar.dart';
import 'package:shoptrack/core/currency/currency_catalog.dart';
import 'package:shoptrack/core/data/shopping_repository.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/core/widgets/compact_amount_text.dart';
import 'package:shoptrack/features/history/presentation/pages/history_page.dart';
import 'package:shoptrack/features/history/presentation/widgets/history_date_badge.dart';
import 'package:shoptrack/features/home/presentation/pages/home_page.dart';
import 'package:shoptrack/features/home/presentation/widgets/record_hero.dart';
import 'package:shoptrack/features/home/presentation/widgets/add_item_sheet.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';

const _preview = bool.fromEnvironment('SHOPTRACK_VISUAL_PREVIEW');
final _themes = [
  ...ThemePresets.lightPresets.values,
  ...ThemePresets.darkPresets.values,
];

Widget _app(
  Widget child, {
  String language = 'en',
  bool reduced = false,
  ThemeDefinition? preset,
  ShopCalendar calendar = const ShopCalendar(),
}) {
  var theme = (preset ?? _themes.first).toThemeData();
  if (_preview) {
    theme = theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: 'Preview-$language'),
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
          fontFamily: 'Preview-$language',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: theme.elevatedButtonTheme.style?.copyWith(
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontFamily: 'Preview-$language', fontSize: 16),
          ),
        ),
      ),
    );
  }
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    locale: Locale(language),
    supportedLocales: const [
      Locale('en'),
      Locale('bn'),
      Locale('ar'),
      Locale('zh'),
    ],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1.3),
        disableAnimations: reduced,
      ),
      child: ShopCalendarScope(calendar: calendar, child: child!),
    ),
    home: child,
  );
}

Future<void> _seed() async {
  final now = DateTime.now();
  await LocalShoppingRepository().saveSession(
    ShoppingSession(
      id: 'today',
      date: DateTime(now.year, now.month, now.day),
      items: const [
        ShoppingItem(
          id: 'usd',
          name: 'Apples',
          priceValue: 3,
          currencyCode: 'USD',
        ),
        ShoppingItem(
          id: 'bdt',
          name: 'Milk',
          priceValue: 780,
          currencyCode: 'BDT',
        ),
        ShoppingItem(
          id: 'sar',
          name: 'Rice',
          priceValue: 729,
          currencyCode: 'SAR',
          isPurchased: true,
        ),
      ],
    ),
  );
}

void main() {
  setUpAll(() async {
    for (final language in ['en', 'bn', 'ar', 'zh']) {
      await initializeDateFormatting(language);
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocalShoppingRepository.activeStore = null;
  });

  testWidgets(
    'live direction changes replace hero gradient in both page types',
    (tester) async {
      for (final home in [false, true]) {
        for (final language in ['ar', 'zh', 'bn', 'en', 'ar']) {
          await tester.pumpWidget(
            _app(
              home
                  ? const HomePage()
                  : Scaffold(
                      body: RecordHero(
                        date: DateTime(2026, 9, 27),
                        onBack: () {},
                      ),
                    ),
              language: language,
            ),
          );
          await tester.pumpAndSettle();
          final gradient = tester
              .widgetList<DecoratedBox>(find.byType(DecoratedBox))
              .map((box) => box.decoration)
              .whereType<BoxDecoration>()
              .map((decoration) => decoration.gradient)
              .whereType<LinearGradient>()
              .firstWhere(
                (gradient) =>
                    gradient.begin == Alignment.centerLeft ||
                    gradient.begin == Alignment.centerRight,
              );
          expect(
            gradient.begin,
            language == 'ar' ? Alignment.centerRight : Alignment.centerLeft,
          );
          expect(
            gradient.end,
            language == 'ar' ? Alignment.centerLeft : Alignment.centerRight,
          );
          expect(gradient.colors.first.a, greaterThan(gradient.colors.last.a));
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'all localized Gregorian and Hijri month badges keep names and bare days',
    (tester) async {
      for (final language in ['en', 'bn', 'ar', 'zh']) {
        for (final system in CalendarPreference.values) {
          final calendar = ShopCalendar(system: system);
          for (var month = 1; month <= 12; month++) {
            final date = system == CalendarPreference.gregorian
                ? DateTime(2026, month, 27)
                : calendar.fromParts(1448, month, 27)!;
            await tester.pumpWidget(
              _app(
                Scaffold(
                  body: Align(
                    alignment: Alignment.topCenter,
                    child: HistoryDateBadge(date: date),
                  ),
                ),
                language: language,
                calendar: calendar,
              ),
            );
            await tester.pumpAndSettle();
            final day = shopNumberLanguage(language, calendar.parts(date).day);
            expect(find.text(day), findsOneWidget);
            expect(find.text('$day日'), findsNothing);
            if (language == 'bn' &&
                system == CalendarPreference.gregorian &&
                month == 9) {
              expect(find.text('সেপ'), findsOneWidget);
            }
            if (language == 'ar') {
              final caption = find.byKey(
                const ValueKey('calendar-month-above'),
              );
              expect(caption, findsOneWidget);
              final ringTop = tester
                  .getTopLeft(
                    find.byKey(const ValueKey('calendar-binding-left')),
                  )
                  .dy;
              expect(
                ringTop - tester.getBottomLeft(caption).dy,
                closeTo(2, .1),
              );
            }
            expect(
              tester.takeException(),
              isNull,
              reason: '$language $system $month',
            );
          }
        }
      }
    },
  );

  testWidgets(
    'every catalogue amount uses consistent font weight; receipts keep their font',
    (tester) async {
      for (final currency in CurrencyCatalog.all) {
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: CompactAmountText(
                value: 3,
                currencyCode: currency.code,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            language: 'zh',
          ),
        );
        await tester.pump();
        final text = tester.widget<Text>(
          find.descendant(
            of: find.byType(CompactAmountText),
            matching: find.byType(Text),
          ),
        );
        expect(
          text.style!.fontFamily,
          'ShopTrackAmounts',
          reason: currency.code,
        );
        expect(text.style!.fontWeight, FontWeight.bold);
        expect(text.style!.fontFamilyFallback, contains('ShopTrackTaka'));
      }
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: CompactAmountText(
              value: 780,
              currencyCode: 'BDT',
              style: TextStyle(
                fontFamily: 'LibreBaskerville',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(CompactAmountText),
          matching: find.byType(Text),
        ),
      );
      expect(text.style!.fontFamily, 'LibreBaskerville');
    },
  );

  for (final size in [const Size(320, 640), const Size(640, 360)]) {
    testWidgets('code-only currency labels stay compact $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final language in ['en', 'bn', 'ar', 'zh']) {
        for (final code in [
          'BDT',
          'USD',
          'XAF',
          'UZS',
          'SAR',
          'AED',
          'OMR',
          'MVR',
        ]) {
          await tester.pumpWidget(
            _app(
              Scaffold(
                body: AddItemSheet(
                  key: ValueKey('$language-$code'),
                  nextPosition: 0,
                  initialItem: ShoppingItem(
                    id: 'one',
                    name: 'Item',
                    currencyCode: code,
                    priceValue: 10,
                  ),
                ),
              ),
              language: language,
            ),
          );
          await tester.pumpAndSettle();
          final button = find.byKey(const ValueKey('item_currency_button'));
          final label = find.descendant(of: button, matching: find.text(code));
          expect(label, findsOneWidget);
          expect(
            find.descendant(
              of: button,
              matching: find.textContaining(
                CurrencyCatalog.resolve(code).symbol,
              ),
            ),
            findsNothing,
          );
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(of: label, matching: find.byType(RichText)),
          );
          expect(paragraph.didExceedMaxLines, isFalse);
          // Padding + arrow + small spacing only; no arbitrary fraction of row.
          expect(
            tester.getSize(button).width - paragraph.size.width,
            lessThanOrEqualTo(55),
          );
          expect(tester.takeException(), isNull, reason: '$language $code');
        }
      }
    });
  }

  testWidgets(
    'Today glow exists in every language and theme, and freezes with reduced motion',
    (tester) async {
      await _seed();
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final theme in _themes) {
        for (final language in ['en', 'bn', 'ar', 'zh']) {
          await tester.pumpWidget(
            _app(
              HistoryPage(onSessionSelected: (_) {}),
              language: language,
              preset: theme,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));
          Text today() =>
              tester.widget<Text>(find.text(shopTrLanguage(language, 'TODAY')));
          final before = today().style!.shadows!.single;
          await tester.pump(const Duration(milliseconds: 600));
          final middle = today().style!.shadows!.single;
          await tester.pump(const Duration(milliseconds: 137));
          // A reversing animation can have equal values around its peak.
          expect(
            {before, middle, today().style!.shadows!.single}.length,
            greaterThan(1),
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$language ${theme.name}',
          );
          await tester.pumpWidget(
            _app(
              HistoryPage(onSessionSelected: (_) {}),
              language: language,
              preset: theme,
              reduced: true,
            ),
          );
          final stopped = today().style!.shadows!.single;
          await tester.pump(const Duration(seconds: 1));
          expect(today().style!.shadows!.single, stopped);
        }
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'only Total Amount heading is underlined, preserving receipt totals',
    (tester) async {
      await _seed();
      await tester.pumpWidget(_app(const HomePage()));
      await tester.pumpAndSettle();
      final heading = tester.widget<Text>(find.text('Total Amount'));
      expect(heading.style!.decoration, TextDecoration.underline);
      for (final amount in tester.widgetList<CompactAmountText>(
        find.byType(CompactAmountText),
      )) {
        expect(amount.style.decoration, isNot(TextDecoration.underline));
      }
    },
  );

  testWidgets(
    'real font previews of multilingual badges, currency fields and totals',
    (tester) async {
      await tester.runAsync(() async {
        for (final family in ['ShopTrackAmounts', 'ShopTrackTaka']) {
          final loader = FontLoader(family);
          for (final weight in [400, 500, 700]) {
            loader.addFont(rootBundle.load('assets/fonts/$family-$weight.ttf'));
          }
          await loader.load();
        }
        for (final entry in {
          'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
          'LibreBaskerville': 'assets/fonts/LibreBaskerville[wght].ttf',
          'ShopTrackCurrency': 'assets/fonts/ShopTrackCurrency.ttf',
          'ShopTrackRufiyaa': 'assets/fonts/ShopTrackRufiyaa.otf',
        }.entries) {
          await (FontLoader(
            entry.key,
          )..addFont(rootBundle.load(entry.value))).load();
        }
        for (final entry in {
          'en': 'arial.ttf',
          'ar': 'arial.ttf',
          'bn': 'Nirmala.ttc',
          'zh': 'msyh.ttc',
        }.entries) {
          final data = await File(
            'C:/Windows/Fonts/${entry.value}',
          ).readAsBytes();
          await (FontLoader(
            'Preview-${entry.key}',
          )..addFont(Future.value(ByteData.sublistView(data)))).load();
        }
      });
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final key = GlobalKey();
      Future<void> capture(String name) async {
        await tester.runAsync(() async {
          for (final image in tester.widgetList<Image>(find.byType(Image))) {
            await precacheImage(image.image, key.currentContext!);
          }
        });
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final picture = await boundary.toImage(pixelRatio: 2);
          final bytes = await picture.toByteData(
            format: ui.ImageByteFormat.png,
          );
          await Directory('build/sprint_19_5_1').create(recursive: true);
          await File(
            'build/sprint_19_5_1/$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          picture.dispose();
        });
      }

      for (final language in ['ar', 'zh', 'bn', 'en']) {
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: RepaintBoundary(
                key: key,
                child: ColoredBox(
                  color: _themes.first.palette.background,
                  child: Column(
                    children: [
                      RecordHero(date: DateTime(2026, 9, 27), onBack: () {}),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (var m = 1; m <= 12; m++)
                            HistoryDateBadge(date: DateTime(2026, m, 27)),
                        ],
                      ),
                      const Divider(),
                      for (final code in [
                        'BDT',
                        'USD',
                        'EUR',
                        'JPY',
                        'SAR',
                        'MVR',
                        'AED',
                        'OMR',
                      ])
                        Row(
                          children: [
                            Text(code),
                            Expanded(
                              child: CompactAmountText(
                                value: 780.25,
                                currencyCode: code,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            language: language,
          ),
        );
        await capture('overview-$language');
      }
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: RepaintBoundary(
              key: key,
              child: const AddItemSheet(
                nextPosition: 0,
                initialItem: ShoppingItem(
                  id: 'i',
                  name: 'Milk',
                  currencyCode: 'BDT',
                  priceValue: 780,
                ),
              ),
            ),
          ),
          language: 'bn',
        ),
      );
      await capture('editor-bn');
      await _seed();
      await tester.pumpWidget(
        _app(
          RepaintBoundary(key: key, child: const HomePage()),
          language: 'zh',
        ),
      );
      await capture('lists-zh');
      final list = tester.widget<ListView>(
        find
            .byWidgetPredicate(
              (widget) =>
                  widget is ListView &&
                  widget.scrollDirection == Axis.vertical &&
                  widget.controller != null,
            )
            .first,
      );
      list.controller!.jumpTo(list.controller!.position.maxScrollExtent / 2);
      await capture('totals-zh');
      list.controller!.jumpTo(list.controller!.position.maxScrollExtent);
      await capture('receipt-zh');
      for (final offset in [-40, 5]) {
        final now = DateTime.now();
        await LocalShoppingRepository().saveSession(
          ShoppingSession(
            id: 'preview-$offset',
            date: DateTime(now.year, now.month, now.day + offset),
            items: const [
              ShoppingItem(
                id: 'a',
                name: 'Item',
                priceValue: 10,
                isPurchased: true,
              ),
            ],
          ),
        );
      }
      for (final language in ['ar', 'zh']) {
        await tester.pumpWidget(
          _app(
            RepaintBoundary(
              key: key,
              child: HistoryPage(onSessionSelected: (_) {}),
            ),
            language: language,
            reduced: true,
            preset: language == 'ar' ? _themes.last : _themes.first,
            calendar: const ShopCalendar(system: CalendarPreference.hijri),
          ),
        );
        await capture('history-$language');
      }
    },
    skip: !_preview,
  );
}
