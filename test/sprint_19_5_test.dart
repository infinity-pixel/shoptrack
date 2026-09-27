import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/app.dart';
import 'package:shoptrack/core/calendar/shop_calendar.dart';
import 'package:shoptrack/core/currency/currency_catalog.dart';
import 'package:shoptrack/core/data/settings_repository.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/core/widgets/currency_picker_dialog.dart';
import 'package:shoptrack/core/widgets/date_parts_field.dart';
import 'package:shoptrack/features/account/presentation/pages/appearance_page.dart';
import 'package:shoptrack/features/account/presentation/pages/backup_restore_page.dart';
import 'package:shoptrack/features/history/presentation/widgets/smart_date_range_picker.dart';
import 'package:shoptrack/features/account/presentation/pages/calendar_settings_page.dart';
import 'package:shoptrack/features/home/presentation/widgets/add_item_sheet.dart';
import 'package:shoptrack/models/app_settings.dart';
import 'package:shoptrack/services/settings_service.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';
import 'package:shoptrack/core/utils/shopping_list_text_formatter.dart';

class _Repository implements SettingsRepository {
  AppSettings value = const AppSettings();
  bool fail = false;
  @override
  Future<AppSettings> getSettings() async => value;
  @override
  Future<void> saveSettings(AppSettings settings) async {
    if (fail) throw StateError('save failed');
    value = AppSettings.fromJson(settings.toJson());
  }
}

Widget _app(Widget child, {bool dark = false}) {
  var theme =
      (dark
              ? ThemePresets.darkPresets.values.first
              : ThemePresets.lightPresets.values.first)
          .toThemeData();
  if (const String.fromEnvironment('SHOPTRACK_PREVIEW_FONT').isNotEmpty) {
    theme = theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamily: 'Preview'),
      appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle: theme.appBarTheme.titleTextStyle?.copyWith(
          fontFamily: 'Preview',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: theme.elevatedButtonTheme.style?.copyWith(
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamily: 'Preview', fontSize: 16),
          ),
        ),
      ),
    );
  }
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('zh', 'CN'),
    supportedLocales: const [Locale('zh', 'CN')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: theme,
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
  test('Literal interface labels have Chinese translations', () {
    // Include adjacent Dart literals (some longer confirmations span lines).
    const literal = r'''(?:'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*")''';
    final labels = RegExp(
      '(?:ShopText\\(\\s*|shopTr\\(\\s*context,\\s*)($literal(?:\\s*$literal)*)',
      dotAll: true,
    );
    final pieces = RegExp(literal, dotAll: true);
    final missing = <String>{};
    for (final file
        in Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))) {
      for (final match in labels.allMatches(file.readAsStringSync())) {
        final label = pieces.allMatches(match[1]!).map((piece) {
          final value = piece[0]!;
          return value
              .substring(1, value.length - 1)
              .replaceAll(r'\n', '\n')
              .replaceAll(r"\'", "'")
              .replaceAll(r'\"', '"');
        }).join();
        if (label.contains(r'$') ||
            ['ShopTrack', '1.0.0+1'].contains(label) ||
            !RegExp('[a-zA-Z]').hasMatch(label)) {
          continue;
        }
        if (!shopTranslationKeys('zh').contains(label)) missing.add(label);
      }
    }
    expect(missing, isEmpty);
  });
  test(
    'Chinese covers every interface and currency key with intact placeholders',
    () {
      expect(shopTranslationKeys('zh'), shopTranslationKeys('bn'));
      final placeholders = RegExp(r'\{[^}]+\}');
      for (final key in shopTranslationKeys('zh')) {
        final translated = shopTrLanguage('zh', key);
        expect(translated, isNotEmpty, reason: key);
        expect(
          placeholders.allMatches(translated).map((m) => m[0]).toSet(),
          placeholders.allMatches(key).map((m) => m[0]).toSet(),
          reason: key,
        );
        if (!['1,234,567 · 1.23M', '12,34,567 · 12.34 Lakh'].contains(key)) {
          expect(translated, isNot(key), reason: key);
        }
      }
      for (final currency in CurrencyCatalog.all) {
        expect(shopTrLanguage('zh', currency.name), isNot(currency.name));
      }
      expect(
        shopTrLanguage('zh', 'Cloud backup failed: API_CODE'),
        '云端备份失败: API_CODE',
      );
    },
  );

  test(
    'Chinese setting survives restart, is independent of calendar, and rejects failed save',
    () async {
      final repository = _Repository();
      final service = SettingsService(repository);
      await service.updateCalendar(CalendarPreference.hijri, -1);
      await service.updateLanguage('Chinese');
      final restarted = SettingsService(repository);
      await restarted.loadSettings();
      expect(restarted.settings.language, 'Chinese');
      expect(restarted.settings.calendar, CalendarPreference.hijri);
      expect(restarted.settings.hijriAdjustment, -1);
      repository.fail = true;
      await expectLater(service.updateLanguage('Arabic'), throwsStateError);
      expect(service.settings.language, 'Chinese');
      expect(service.isSwitchingLanguage, isFalse);
      service.dispose();
      restarted.dispose();
    },
  );

  test(
    'Chinese dates use year month day without changing stored days',
    () async {
      await initializeDateFormatting('zh_CN');
      final date = DateTime(2026, 9, 27);
      const calendar = ShopCalendar();
      expect(
        calendar.format(date, pattern: 'd MMMM yyyy', locale: 'zh'),
        '2026年9月27日',
      );
      expect(
        calendar.format(date, pattern: 'MMMM yyyy', locale: 'zh'),
        '2026年9月',
      );
      expect(
        calendar.format(date, pattern: 'EEEE, d MMMM', locale: 'zh'),
        '9月27日 星期日',
      );
      const hijri = ShopCalendar(system: CalendarPreference.hijri);
      final parts = hijri.parts(date);
      expect(
        hijri.format(date, pattern: 'd MMMM yyyy', locale: 'zh'),
        '${parts.year}年${parts.month}月${parts.day}日',
      );
      expect(hijri.fromParts(parts.year, parts.month, parts.day), date);
      expect(hijri.format(date, pattern: 'G', locale: 'zh'), '伊斯兰历');
      expect(shopNumberLanguage('zh', 1234567), '1,234,567');
    },
  );

  testWidgets(
    'Switch Arabic to Chinese restores LTR and keeps authored names',
    (tester) async {
      await tester.pumpWidget(const ShopTrackApp());
      await tester.pumpAndSettle();
      final service = ShopTrackApp.of(
        tester.element(find.byType(Scaffold).first),
      );
      await service.updateLanguage('Arabic');
      await tester.pumpAndSettle();
      expect(
        Directionality.of(tester.element(find.byType(Scaffold).first)),
        TextDirection.rtl,
      );
      await service.updateLanguage('Chinese');
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).first);
      expect(Directionality.of(context), TextDirection.ltr);
      expect(find.text('今日购物'), findsOneWidget);
      expect(find.text('暂无商品'), findsOneWidget);
      expect(find.text('清单'), findsOneWidget);
      expect(shopListName(context, id: 'default', name: 'My List'), 'My List');
      expect(
        shopListName(context, id: 'default-list', name: 'My List'),
        '我的清单',
      );
      expect(
        shopListName(context, id: 'custom', name: 'Grandmother'),
        'Grandmother',
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'Chinese shared lists translate units and headings, not user content',
    () {
      final text = ShoppingListTextFormatter.format(
        ShoppingSession(
          id: 'example',
          date: DateTime(2026, 9, 27),
          items: const [
            ShoppingItem(
              id: 'one',
              name: 'Apples 苹果',
              quantityValue: 2,
              shoppingUnit: ShoppingUnit.kg,
              priceValue: 20,
              currencyCode: 'CNY',
              notes: 'Keep my note',
            ),
          ],
        ),
        translate: (text) => shopTrLanguage('zh', text),
        defaultListLabel: shopTrLanguage('zh', 'My List'),
        dateLabel: '2026年9月27日',
      );
      expect(text, contains('我的清单'));
      expect(text, contains('待购买'));
      expect(text, contains('2 千克'));
      expect(text, contains('Apples 苹果'));
      expect(text, contains('备注: Keep my note'));
      expect(text, isNot(contains('TO BUY')));
    },
  );

  testWidgets('Chinese Lists interface remains LTR across all eight themes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const ShopTrackApp());
    await tester.pumpAndSettle();
    final service = ShopTrackApp.of(
      tester.element(find.byType(Scaffold).first),
    );
    await service.updateLanguage('Chinese');
    for (final preset in LightPreset.values) {
      await service.updateTheme(AppTheme.light);
      await service.updateLightPreset(preset);
      await tester.pumpAndSettle();
      expect(find.text('今日购物'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text('今日购物'))),
        TextDirection.ltr,
      );
      expect(tester.takeException(), isNull, reason: '$preset');
    }
    for (final preset in DarkPreset.values) {
      await service.updateTheme(AppTheme.dark);
      await service.updateDarkPreset(preset);
      await tester.pumpAndSettle();
      expect(find.text('今日购物'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text('今日购物'))),
        TextDirection.ltr,
      );
      expect(tester.takeException(), isNull, reason: '$preset');
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'Chinese date entry is year month day with matching focus order',
    (tester) async {
      DateTime? changed;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: DatePartsField(
              date: DateTime(2026, 9, 27),
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.map((f) => f.decoration!.labelText), ['年', '月', '日']);
      expect(fields.map((f) => f.controller!.text), ['2026', '9', '27']);
      await tester.enterText(find.byType(TextField).at(0), '2027');
      expect(changed, DateTime(2027, 9, 27));
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(fields[1].focusNode!.hasFocus, isTrue);
    },
  );

  testWidgets('Chinese currency search matches translated names', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(
          body: CurrencyPickerDialog(
            selectedCurrencyCode: 'BDT',
            defaultCurrencyCode: 'BDT',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '人民币');
    await tester.pumpAndSettle();
    expect(find.text('CNY'), findsOneWidget);
    expect(find.text('人民币'), findsNWidgets(2));
    expect(find.text('BDT'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Profile language choice, appearance, backup tabs and exit dialog are Chinese',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const ShopTrackApp());
      await tester.pumpAndSettle();
      final service = ShopTrackApp.of(
        tester.element(find.byType(Scaffold).first),
      );
      await service.updateLanguage('Chinese');
      await tester.pumpAndSettle();
      await tester.tap(find.text('个人中心'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('语言').hitTestable(),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('语言'));
      await tester.pumpAndSettle();
      expect(find.text('简体中文'), findsWidgets);
      expect(find.text('语言设置'), findsOneWidget);
      Navigator.of(tester.element(find.text('语言设置'))).pop();
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Scaffold).first);
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const BackupRestorePage()),
      );
      await tester.pumpAndSettle();
      expect(find.text('本机备份'), findsOneWidget);
      expect(find.text('从本机恢复'), findsOneWidget);
      await tester.tap(find.text('云端'));
      await tester.pumpAndSettle();
      expect(find.text('需要登录'), findsOneWidget);
      expect(find.text('请登录 Google 账号以使用云端备份功能。'), findsOneWidget);
      Navigator.of(tester.element(find.text('备份与恢复'))).pop();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('退出 ShopTrack？'), findsOneWidget);
      expect(find.text('确定要退出应用吗？'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final size in [const Size(320, 640), const Size(640, 360)]) {
    for (final dark in [false, true]) {
      testWidgets('Chinese calendar and editor fit $size dark=$dark', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final service = SettingsService(_Repository());
        await service.updateCalendar(CalendarPreference.hijri, 1);
        await tester.pumpWidget(
          _app(CalendarSettingsPage(settingsService: service), dark: dark),
        );
        await tester.pumpAndSettle();
        expect(find.text('日历'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          _app(const Scaffold(body: SmartDateRangePicker()), dark: dark),
        );
        await tester.pumpAndSettle();
        expect(find.text('开始日期'), findsOneWidget);
        expect(find.text('结束日期'), findsOneWidget);
        expect(find.text('日'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          _app(AppearancePage(settingsService: service), dark: dark),
        );
        await tester.pumpAndSettle();
        expect(find.text('外观'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(
          _app(const Scaffold(body: AddItemSheet(nextPosition: 0)), dark: dark),
        );
        await tester.pumpAndSettle();
        expect(find.text('商品名称'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        service.dispose();
      });
    }
  }

  const previewFont = String.fromEnvironment('SHOPTRACK_PREVIEW_FONT');
  testWidgets('Chinese real-font calendar preview', (tester) async {
    await tester.runAsync(() async {
      final bytes = await File(previewFont).readAsBytes();
      for (final family in ['Preview', 'Roboto', 'Ahem']) {
        await (FontLoader(
          family,
        )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      }
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    final service = SettingsService(_Repository());
    await service.updateCalendar(CalendarPreference.hijri, -1);
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: _app(CalendarSettingsPage(settingsService: service)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/sprint_19_5').create(recursive: true);
      await File(
        'build/sprint_19_5/chinese_calendar.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox());
    for (final entry in <String, Widget>{
      'editor': const Scaffold(
        body: AddItemSheet(
          nextPosition: 0,
          initialItem: ShoppingItem(
            id: 'preview',
            name: '苹果',
            quantityValue: 3,
            shoppingUnit: ShoppingUnit.kg,
            priceValue: 123.45,
            currencyCode: 'CNY',
          ),
        ),
      ),
      'range': const Scaffold(body: SmartDateRangePicker()),
      'appearance': AppearancePage(settingsService: service),
    }.entries) {
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: boundaryKey, child: _app(entry.value, dark: true)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/sprint_19_5/chinese_${entry.key}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    }
    service.dispose();
  }, skip: previewFont.isEmpty);
}
