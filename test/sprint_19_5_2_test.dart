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
import 'package:shoptrack/core/localization/shoptrack_text.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/core/widgets/scroll_aware_fab.dart';
import 'package:shoptrack/core/widgets/shoptrack_hero_artwork.dart';
import 'package:shoptrack/core/widgets/shoptrack_motion.dart';
import 'package:shoptrack/features/account/presentation/pages/help_faq_page.dart';
import 'package:shoptrack/features/history/presentation/pages/history_search_page.dart';
import 'package:shoptrack/features/history/presentation/widgets/history_date_badge.dart';
import 'package:shoptrack/features/home/presentation/widgets/add_item_sheet.dart';

Widget _app(
  Widget child, {
  String language = 'en',
  bool reduced = false,
  double textScale = 1,
  ThemeDefinition? preset,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: (preset ?? ThemePresets.lightPresets.values.first).toThemeData(),
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
      disableAnimations: reduced,
      textScaler: TextScaler.linear(textScale),
    ),
    child: ShopCalendarScope(calendar: const ShopCalendar(), child: child!),
  ),
  home: child,
);

void main() {
  const preview = bool.fromEnvironment('SHOPTRACK_VISUAL_PREVIEW');
  const previewFont = String.fromEnvironment('SHOPTRACK_PREVIEW_FONT');
  setUpAll(() async {
    for (final language in ['en', 'bn', 'ar', 'zh']) {
      await initializeDateFormatting(language);
    }
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('add-item keyboard waits until the sheet has entered', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showShopBottomSheet<void>(
                context: context,
                requestFocus: false,
                isScrollControlled: true,
                builder: (_) => const AddItemSheet(nextPosition: 0),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    final name = find.byType(TextField).first;
    expect(name, findsOneWidget);
    expect(tester.widget<TextField>(name).focusNode!.hasFocus, isFalse);

    await tester.pump(ShopTrackMotion.sheet + const Duration(milliseconds: 20));
    expect(tester.widget<TextField>(name).focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion opens the editor without an animation wait', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showShopBottomSheet<void>(
                context: context,
                requestFocus: false,
                isScrollControlled: true,
                builder: (_) => const AddItemSheet(nextPosition: 0),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
        reduced: true,
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump();
    final name = find.byType(TextField).first;
    expect(tester.widget<TextField>(name).focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FAQ is localized and usable at a narrow width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final language in ['en', 'bn', 'ar', 'zh']) {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app(const HelpFaqPage(), language: language));
      await tester.pumpAndSettle();
      expect(find.text(shopTrLanguage(language, 'Help & FAQ')), findsOneWidget);
      expect(
        find.text(shopTrLanguage(language, 'Add and price an item')),
        findsOneWidget,
      );
      await tester.tap(
        find.text(shopTrLanguage(language, 'Add and price an item')),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          shopTrLanguage(language, 'Open a shopping date and tap Add Item.'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('FAQ remains scrollable in short RTL landscape at 1.3x text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(640, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _app(
        const HelpFaqPage(),
        language: 'ar',
        textScale: 1.3,
        preset: ThemePresets.darkPresets.values.first,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(shopTrLanguage('ar', 'Create dates and lists')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendar day is optically centered in its face', (tester) async {
    await tester.pumpWidget(
      _app(Scaffold(body: HistoryDateBadge(date: DateTime(2026, 9, 27)))),
    );
    await tester.pumpAndSettle();
    final face = tester.getCenter(
      find.byKey(const ValueKey('calendar-day-face')),
    );
    final day = tester.getCenter(find.text('27'));
    expect((face.dx - day.dx).abs(), lessThan(1));
    expect((face.dy - day.dy).abs(), lessThan(1));
  });

  testWidgets('History filters separate status from detail filters', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const HistorySearchPage()));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('history_filter_group_divider')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('both FAB labels use the distinguished bold face', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          floatingActionButton: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DelayedExtendedFab(
                expanded: true,
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: 'New Date',
              ),
              ShoppingSplitFab(
                expanded: true,
                onAddPressed: () {},
                onSharePressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final label in ['New Date', 'Add Item']) {
      final text = tester.widget<ShopText>(
        find.widgetWithText(ShopText, label),
      );
      expect(text.style?.fontFamily, 'LibreBaskerville');
      expect(text.style?.fontFamilyFallback, contains('serif'));
      expect(text.style?.fontWeight, FontWeight.w700);
    }
    expect(tester.takeException(), isNull);
  });

  test('custom theme colors interpolate instead of snapping', () {
    final themes = ThemePresets.lightPresets.values.toList();
    final first = themes[0].toThemeData().extension<ShopTrackThemeTokens>()!;
    final second = themes[1].toThemeData().extension<ShopTrackThemeTokens>()!;
    final middle = first.lerp(second, .5);
    expect(
      middle.palette.primary,
      Color.lerp(first.palette.primary, second.palette.primary, .5),
    );
    expect(middle.palette.primary, isNot(first.palette.primary));
    expect(middle.palette.primary, isNot(second.palette.primary));
  });

  testWidgets('hero scenery changes through a keyed crossfade', (tester) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: SizedBox(
            width: 320,
            height: 150,
            child: ShopTrackHeroArtwork(
              path: 'assets/images/theme_light_blooming_spring.webp',
              alignment: Alignment.center,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: SizedBox(
            width: 320,
            height: 150,
            child: ShopTrackHeroArtwork(
              path: 'assets/images/theme_light_golden_summer.webp',
              alignment: Alignment.center,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview FAQ layout', (tester) async {
    final fontData = ByteData.sublistView(File(previewFont).readAsBytesSync());
    for (final family in ['Roboto', 'Ahem']) {
      await (FontLoader(family)..addFont(Future.value(fontData))).load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('LibreBaskerville')
          ..addFont(rootBundle.load('assets/fonts/LibreBaskerville[wght].ttf')))
        .load();
    await tester.binding.setSurfaceSize(const Size(360, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: _app(const HelpFaqPage())),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add and price an item'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('build/sprint_19_5_2_faq.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }, skip: !preview || previewFont.isEmpty);
}
