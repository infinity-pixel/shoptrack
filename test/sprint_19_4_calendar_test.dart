import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shoptrack/core/calendar/shop_calendar.dart';
import 'package:shoptrack/core/widgets/date_parts_field.dart';
import 'package:shoptrack/core/widgets/shoptrack_date_picker.dart';
import 'package:shoptrack/features/history/presentation/widgets/smart_date_range_picker.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';

Widget calendarApp(
  Widget child, {
  String language = 'ar',
  int adjustment = 0,
  double scale = 1.3,
}) => MaterialApp(
  locale: Locale(language),
  supportedLocales: const [Locale('en'), Locale('bn'), Locale('ar')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  theme: ThemePresets.darkPresets.values.first.toThemeData(),
  builder: (context, child) => ShopCalendarScope(
    calendar: ShopCalendar(
      system: CalendarPreference.hijri,
      hijriAdjustment: adjustment,
    ),
    child: MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
  ),
  home: child,
);

void main() {
  const calendar = ShopCalendar(system: CalendarPreference.hijri);
  setUpAll(() async {
    await initializeDateFormatting('ar');
    await initializeDateFormatting('bn');
  });

  test('Umm al-Qura independently published reference dates', () {
    // hijri package README: https://pub.dev/packages/hijri/versions/3.0.1
    expect(calendar.fromParts(1440, 3, 4), DateTime(2018, 11, 12));
    // hijri_plus reference month boundaries: https://pub.dev/packages/hijri_plus
    expect(calendar.fromParts(1446, 5, 1), DateTime(2024, 11, 3));
    expect(calendar.fromParts(1446, 6, 1), DateTime(2024, 12, 2));
    expect(calendar.fromParts(1446, 7, 1), DateTime(2025, 1, 1));
  });

  for (var adjustment = -2; adjustment <= 2; adjustment++) {
    test('Every selectable day roundtrips with correction $adjustment', () {
      final adjusted = ShopCalendar(
        system: CalendarPreference.hijri,
        hijriAdjustment: adjustment,
      );
      for (
        var day = DateTime.utc(2000);
        !day.isAfter(DateTime.utc(2100, 12, 31));
        day = day.add(const Duration(days: 1))
      ) {
        final parts = adjusted.parts(day);
        final restored = adjusted.fromParts(parts.year, parts.month, parts.day);
        expect(restored, DateTime(day.year, day.month, day.day));
      }
    });
  }

  test('Corrections are instance-owned, inverse-consistent across months', () {
    const plus = ShopCalendar(
      system: CalendarPreference.hijri,
      hijriAdjustment: 1,
    );
    const minus = ShopCalendar(
      system: CalendarPreference.hijri,
      hijriAdjustment: -1,
    );
    final day = DateTime(2025, 1, 1);
    expect(plus.parts(day).day, 2);
    expect(minus.parts(day).month, 6);
    expect(minus.parts(day).day, 30);
    expect(calendar.parts(day).day, 1);
    expect(plus.fromParts(1446, 7, 2), day);
    expect(minus.fromParts(1446, 6, 30), day);
  });

  test('Strict day validation and valid leap days', () {
    expect(calendar.fromParts(1446, 5, 30), isNull);
    expect(calendar.fromParts(1446, 6, 30), isNotNull);
    expect(calendar.fromParts(1446, 6, 31), isNull);
    expect(calendar.fromParts(1446, 0, 1), isNull);
    expect(calendar.fromParts(1446, 13, 1), isNull);
    expect(calendar.fromParts(1446, 1, 0), isNull);
    expect(calendar.fromParts(1299, 1, 1), isNull);
    expect(calendar.fromParts(1601, 1, 1), isNull);
    const gregorian = ShopCalendar();
    expect(gregorian.fromParts(2024, 2, 29), DateTime(2024, 2, 29));
    expect(gregorian.fromParts(2025, 2, 29), isNull);
  });

  test('Localized names, digits, weekday and supported patterns', () {
    final day = DateTime(2025, 1, 1, 13, 25);
    expect(
      calendar.format(day, pattern: 'd MMMM yyyy', locale: 'en'),
      '1 Rajab 1446',
    );
    expect(
      calendar.format(day, pattern: 'd MMMM yyyy', locale: 'bn'),
      '১ রজব ১৪৪৬',
    );
    expect(
      calendar.format(day, pattern: 'd MMMM yyyy', locale: 'ar'),
      '١ رجب ١٤٤٦',
    );
    expect(
      calendar.format(day, pattern: 'EEEE, d MMMM yyyy', locale: 'en'),
      'Wednesday, 1 Rajab 1446',
    );
    expect(
      calendar.format(day, pattern: 'yMMMd', locale: 'en'),
      'Rajab 1, 1446',
    );
    expect(calendar.format(day, pattern: 'HH:mm', locale: 'ar'), '١٣:٢٥');
    expect(normalizeDateDigits('١٢/০৩/۱۴۴۶'), '12/03/1446');
    expect(calendar.monthOffset(day, -1, keepDay: true), DateTime(2024, 12, 2));
    expect(calendar.daysInMonth(DateTime(2024, 11, 3)), 29);
  });

  testWidgets(
    'Arabic numeric date input converts selected Hijri day without changing stored calendar',
    (tester) async {
      DateTime? changed;
      await tester.pumpWidget(
        calendarApp(
          Scaffold(
            body: DatePartsField(
              date: DateTime(2025, 1, 1),
              onChanged: (date) => changed = date,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('١٤٤٦'), findsOneWidget);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '٢');
      expect(changed, DateTime(2025, 1, 2));
      await tester.enterText(fields.at(0), '31');
      expect(changed, isNull);
      await tester.enterText(fields.at(0), '2');
      expect(changed, DateTime(2025, 1, 2));
    },
  );

  for (final language in ['en', 'bn', 'ar']) {
    for (final size in [const Size(320, 640), const Size(640, 360)]) {
      testWidgets(
        'Hijri pickers fit $language $size and month navigation works',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await tester.pumpWidget(
            calendarApp(
              Scaffold(
                body: SmartDateRangePicker(
                  initialRange: DateTimeRange(
                    start: DateTime(2025, 1, 1),
                    end: DateTime(2025, 1, 7),
                  ),
                ),
              ),
              language: language,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final picker = ShopTrackDatePicker(
            initialDate: DateTime(2025, 1, 1),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100, 12, 31),
          );
          await tester.pumpWidget(
            calendarApp(
              Scaffold(
                body: Center(child: Dialog(child: picker)),
              ),
              language: language,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  const font = String.fromEnvironment('SHOPTRACK_PREVIEW_FONT');
  testWidgets('Arabic Hijri calendar visual previews', (tester) async {
    for (final family in ['Roboto', 'Ahem']) {
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
    final date = DateTime(2024, 12, 2);
    for (final entry in <String, Widget>{
      'picker': Scaffold(
        body: Center(
          child: Dialog(
            child: ShopTrackDatePicker(
              initialDate: date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100, 12, 31),
            ),
          ),
        ),
      ),
      'range': Scaffold(
        body: SmartDateRangePicker(
          initialRange: DateTimeRange(start: date, end: DateTime(2024, 12, 10)),
        ),
      ),
    }.entries) {
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: key, child: calendarApp(entry.value, scale: 1)),
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
          'build/sprint_19_4_hijri_${entry.key}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  }, skip: font.isEmpty);
}
