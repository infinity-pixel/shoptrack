import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/core/widgets/scroll_aware_fab.dart';
import 'package:shoptrack/features/history/presentation/widgets/session_card.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';
import 'package:shoptrack/models/app_settings.dart';

Widget _app(
  Widget child, {
  String language = 'en',
  ThemeDefinition? theme,
  double textScale = 1,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: (theme ?? ThemePresets.lightPresets.values.first).toThemeData(),
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
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: child,
);

double _contrast(Color one, Color two) {
  final a = one.computeLuminance();
  final b = two.computeLuminance();
  final lighter = a > b ? a : b;
  final darker = a > b ? b : a;
  return (lighter + .05) / (darker + .05);
}

void main() {
  const preview = bool.fromEnvironment('SHOPTRACK_VISUAL_PREVIEW');
  const previewFont = String.fromEnvironment('SHOPTRACK_PREVIEW_FONT');
  test('History status counts use complete language-specific phrases', () {
    expect(
      shopHistoryStatusLanguage('bn', 4, ShopHistoryStatus.purchased),
      '৪টি কেনা হয়েছে',
    );
    expect(
      shopHistoryStatusLanguage('bn', 1, ShopHistoryStatus.pending),
      '১টি বাকি',
    );
    expect(
      shopHistoryStatusLanguage('bn', 2, ShopHistoryStatus.planned),
      '২টি কেনার পরিকল্পনা',
    );
    expect(
      shopHistoryStatusLanguage('zh', 4, ShopHistoryStatus.purchased),
      '已购买4件',
    );
    expect(
      shopHistoryStatusLanguage('zh', 1, ShopHistoryStatus.pending),
      '待购买1件',
    );
    expect(
      shopHistoryStatusLanguage('ar', 4, ShopHistoryStatus.purchased),
      'تم الشراء: ٤',
    );
    expect(
      shopHistoryStatusLanguage('ar', 1, ShopHistoryStatus.planned),
      'المخطط له: ١',
    );
    expect(
      shopHistoryStatusLanguage('en', 1, ShopHistoryStatus.planned),
      '1 Planned Item',
    );
  });

  testWidgets('History card uses the Bengali classifier on purchased counts', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Scaffold(
          body: SessionCard(
            session: ShoppingSession(
              id: 'bn-status',
              date: DateTime(2020, 9, 29),
              items: const [
                ShoppingItem(id: '1', name: 'Rice', isPurchased: true),
                ShoppingItem(id: '2', name: 'Tea', isPurchased: true),
              ],
            ),
            onTap: () {},
          ),
        ),
        language: 'bn',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('২টি কেনা হয়েছে'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('localized History counts fit a narrow card at 1.3x text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final language in ['en', 'bn', 'ar', 'zh']) {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SessionCard(
              session: ShoppingSession(
                id: 'localized-status',
                date: DateTime(2020, 9, 29),
                items: const [
                  ShoppingItem(id: '1', name: 'Rice', isPurchased: true),
                  ShoppingItem(id: '2', name: 'Tea', isPurchased: true),
                  ShoppingItem(id: '3', name: 'Milk'),
                ],
              ),
              onTap: () {},
            ),
          ),
          language: language,
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          shopHistoryStatusLanguage(language, 2, ShopHistoryStatus.purchased),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: language);
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SessionCard(
              session: ShoppingSession(
                id: 'future-status',
                date: DateTime(2099, 9, 29),
                items: const [ShoppingItem(id: 'future', name: 'Tea')],
              ),
              onTap: () {},
            ),
          ),
          language: language,
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          shopHistoryStatusLanguage(language, 1, ShopHistoryStatus.planned),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: '$language planned');
    }
  });

  testWidgets('both main FABs are compact and labels stay readable', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final theme in [
      ...ThemePresets.lightPresets.values,
      ...ThemePresets.darkPresets.values,
    ]) {
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
          theme: theme,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(DelayedExtendedFab)).height, 50);
      expect(
        tester.getSize(find.byKey(const ValueKey('split-main-fab'))).height,
        50,
      );
      final themeData = theme.toThemeData();
      final background =
          themeData.floatingActionButtonTheme.backgroundColor ??
          themeData.colorScheme.primaryContainer;
      final foreground =
          themeData.floatingActionButtonTheme.foregroundColor ??
          themeData.colorScheme.onPrimaryContainer;
      for (final label in ['New Date', 'Add Item']) {
        final ink = tester
            .widget<ShopText>(find.widgetWithText(ShopText, label))
            .style!
            .color!;
        expect(
          _contrast(ink, background),
          lessThanOrEqualTo(_contrast(foreground, background) + .01),
        );
        if (_contrast(foreground, background) >= 4.5) {
          expect(_contrast(ink, background), greaterThanOrEqualTo(4.5));
        }
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'preview compact FABs in light and dark themes',
    (tester) async {
      final fontData = ByteData.sublistView(
        File(previewFont).readAsBytesSync(),
      );
      await (FontLoader('Roboto')..addFont(Future.value(fontData))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await (FontLoader('LibreBaskerville')..addFont(
            rootBundle.load('assets/fonts/LibreBaskerville[wght].ttf'),
          ))
          .load();
      await tester.binding.setSurfaceSize(const Size(360, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final entry in {
        'light': ThemePresets.lightPresets[LightPreset.ocean]!,
        'dark': ThemePresets.darkPresets[DarkPreset.midnight]!,
      }.entries) {
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: _app(
              Scaffold(
                body: const Center(child: Text('ShopTrack')),
                floatingActionButton: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DelayedExtendedFab(
                      expanded: true,
                      onPressed: () {},
                      icon: const CalendarAddIcon(),
                      label: 'New Date',
                    ),
                    const SizedBox(height: 24),
                    ShoppingSplitFab(
                      expanded: true,
                      onAddPressed: () {},
                      onSharePressed: () {},
                    ),
                  ],
                ),
              ),
              theme: entry.value,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image =
              await (key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/sprint_19_5_5/fab-${entry.key}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    },
    skip: !preview || previewFont.isEmpty,
  );
}
