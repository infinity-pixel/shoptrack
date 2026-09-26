import 'dart:async';
import 'dart:convert';
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
import 'package:shoptrack/core/data/settings_repository.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/core/utils/shopping_list_text_formatter.dart';
import 'package:shoptrack/core/widgets/compact_amount_text.dart';
import 'package:shoptrack/features/account/presentation/pages/calendar_settings_page.dart';
import 'package:shoptrack/models/app_settings.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';
import 'package:shoptrack/services/settings_service.dart';

class _Repository implements SettingsRepository {
  AppSettings value = const AppSettings();
  bool fail = false;
  Completer<void>? pending;
  @override
  Future<AppSettings> getSettings() async => value;
  @override
  Future<void> saveSettings(AppSettings settings) async {
    await pending?.future;
    if (fail) throw StateError('storage unavailable');
    value = settings;
  }
}

Widget _app(
  Widget child,
  String language, {
  bool dark = false,
  double scale = 1.3,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  locale: Locale(language),
  supportedLocales: const [Locale('en'), Locale('bn'), Locale('ar')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  theme:
      (dark
              ? ThemePresets.darkPresets.values.first
              : ThemePresets.lightPresets.values.first)
          .toThemeData(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: child,
);

void main() {
  test(
    'legacy settings retain Gregorian; calendar is independent of language',
    () {
      final legacy = AppSettings.fromJson({'language': 'Arabic'});
      expect(legacy.calendar, CalendarPreference.gregorian);
      expect(legacy.hijriAdjustment, 0);
      final changed = legacy.copyWith(
        calendar: CalendarPreference.hijri,
        hijriAdjustment: -1,
      );
      final restored = AppSettings.fromJson(changed.toJson());
      expect(restored.calendar, CalendarPreference.hijri);
      expect(restored.hijriAdjustment, -1);
      expect(
        restored.copyWith(language: 'Bangla').calendar,
        CalendarPreference.hijri,
      );
      expect(
        AppSettings.fromJson({
          'calendar': 'unknown',
          'hijriAdjustment': 'bad',
        }).calendar,
        CalendarPreference.gregorian,
      );
      expect(AppSettings.fromJson({'hijriAdjustment': 10}).hijriAdjustment, 2);
    },
  );

  test(
    'calendar preference persists on restart and failure preserves old setting',
    () async {
      final repository = _Repository();
      final service = SettingsService(repository);
      await service.updateCalendar(CalendarPreference.hijri, -1);
      final restarted = SettingsService(repository);
      await restarted.loadSettings();
      expect(restarted.settings.hijriAdjustment, -1);
      expect(restarted.settings.calendar, CalendarPreference.hijri);
      repository.fail = true;
      await expectLater(
        service.updateCalendar(CalendarPreference.gregorian, 0),
        throwsStateError,
      );
      expect(service.settings.calendar, CalendarPreference.hijri);
      expect(service.settings.hijriAdjustment, -1);
      service.dispose();
      restarted.dispose();
    },
  );

  test(
    'language transaction waits for save and new frame; failure clears busy',
    () async {
      final repository = _Repository()..pending = Completer<void>();
      final service = SettingsService(repository);
      var frames = 0;
      final operation = service.updateLanguage(
        'Arabic',
        waitForFrame: () async {
          frames++;
        },
      );
      await Future<void>.delayed(Duration.zero);
      expect(service.isSwitchingLanguage, isTrue);
      expect(service.settings.language, 'English');
      expect(frames, 1);
      await service.updateLanguage('Bangla'); // repeated taps cannot race
      repository.pending!.complete();
      await operation;
      expect(service.settings.language, 'Arabic');
      expect(frames, 2);
      expect(service.isSwitchingLanguage, isFalse);
      repository.fail = true;
      await expectLater(service.updateLanguage('Bangla'), throwsStateError);
      expect(service.settings.language, 'Arabic');
      expect(service.isSwitchingLanguage, isFalse);
      service.dispose();
    },
  );

  for (final language in ['en', 'bn', 'ar']) {
    for (final size in [const Size(320, 640), const Size(640, 360)]) {
      testWidgets(
        'calendar settings preview and adjustment fit $language $size',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final service = SettingsService(_Repository());
          await service.updateCalendar(CalendarPreference.hijri, 0);
          await tester.pumpWidget(
            _app(CalendarSettingsPage(settingsService: service), language),
          );
          await tester.pumpAndSettle();
          final adjustment = find.byKey(const ValueKey('hijri-adjustment--1'));
          await tester.scrollUntilVisible(adjustment, 180);
          await tester.pumpAndSettle();
          await tester.tap(adjustment);
          await tester.pumpAndSettle();
          expect(tester.widget<ChoiceChip>(adjustment).selected, isTrue);
          expect(service.settings.hijriAdjustment, 0); // preview is not a save
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          service.dispose();
        },
      );
    }
  }

  testWidgets(
    'Arabic money uses Arabic digits without altering exact share data or names',
    (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (value) {
              context = value;
              return const Scaffold(
                body: SizedBox(
                  width: 300,
                  child: CompactAmountText(
                    value: 1234.56,
                    currencyCode: 'USD',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              );
            },
          ),
          'ar',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(r'$١,٢٣٤.٥٦'), findsOneWidget);
      final session = ShoppingSession(
        id: '2026-09-26',
        date: DateTime(2026, 9, 26),
        items: [
          ShoppingItem(
            id: 'x',
            name: 'Apples 123',
            priceValue: 1234.56,
            currencyCode: 'USD',
          ),
        ],
      );
      final before = jsonEncode(session.toJson());
      const calendar = ShopCalendar(
        system: CalendarPreference.hijri,
        hijriAdjustment: -1,
      );
      final text = ShoppingListTextFormatter.format(
        session,
        translate: (value) => shopTr(context, value),
        formatNumberText: (value) => shopDigits(context, value),
        dateLabel: calendar.format(session.date, locale: 'ar'),
      );
      expect(text, contains('Apples 123'));
      expect(text, contains('١,٢٣٤.٥٦'));
      expect(jsonEncode(session.toJson()), before);
    },
  );

  testWidgets(
    'app language transaction switches RTL and keeps Gregorian default',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const ShopTrackApp());
      await tester.pump();
      await tester.pump();
      final context = tester.element(find.text("Today's Shopping"));
      final service = ShopTrackApp.of(context);
      final switchLanguage = service.updateLanguage(
        'Arabic',
        waitForFrame: () => WidgetsBinding.instance.endOfFrame,
      );
      await tester.pump();
      expect(find.text('Changing language…'), findsOneWidget);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await switchLanguage;
      await tester.pump();
      expect(service.settings.calendar, CalendarPreference.gregorian);
      expect(find.text('تسوق اليوم'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text('تسوق اليوم'))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  final font = const String.fromEnvironment('SHOPTRACK_PREVIEW_FONT');
  testWidgets('calendar settings visual preview', (tester) async {
    for (final family in ['PreviewFont', 'Roboto', 'Ahem']) {
      await (FontLoader(family)..addFont(
            Future.value(ByteData.sublistView(File(font).readAsBytesSync())),
          ))
          .load();
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final language in ['en', 'bn', 'ar']) {
      final key = GlobalKey();
      final service = SettingsService(_Repository());
      await service.updateCalendar(CalendarPreference.hijri, -1);
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: _app(
            Theme(
              data: ThemePresets.darkPresets.values.first
                  .toThemeData()
                  .copyWith(
                    appBarTheme: ThemePresets.darkPresets.values.first
                        .toThemeData()
                        .appBarTheme
                        .copyWith(
                          titleTextStyle: ThemePresets
                              .darkPresets
                              .values
                              .first
                              .typography
                              .sectionTitle
                              .copyWith(fontFamily: 'PreviewFont'),
                        ),
                    textTheme: ThemePresets.darkPresets.values.first
                        .toThemeData()
                        .textTheme
                        .apply(fontFamily: 'PreviewFont'),
                  ),
              child: CalendarSettingsPage(settingsService: service),
            ),
            language,
            dark: true,
            scale: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/sprint_19_4_calendar_$language.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
      service.dispose();
    }
  }, skip: font.isEmpty);
}
