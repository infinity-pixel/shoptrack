import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/core/widgets/date_parts_field.dart';
import 'package:shoptrack/features/history/presentation/widgets/history_date_badge.dart';
import 'package:shoptrack/features/history/presentation/widgets/session_card.dart';
import 'package:shoptrack/features/history/presentation/widgets/smart_date_range_picker.dart';
import 'package:shoptrack/features/home/presentation/widgets/record_hero.dart';
import 'package:shoptrack/features/home/presentation/widgets/shopping_list_switcher.dart';
import 'package:shoptrack/features/home/presentation/pages/home_page.dart';
import 'package:shoptrack/models/shopping_list_group.dart';
import 'package:shoptrack/models/shopping_session.dart';

void main() {
  // Optional real-widget preview, written only to ignored build output.
  // Supply a local Roboto font path with SHOPTRACK_PREVIEW_FONT to enable it.
  const previewFont = String.fromEnvironment('SHOPTRACK_PREVIEW_FONT');
  testWidgets('Render calendar visual preview', (tester) async {
    final loader = FontLoader('Roboto')
      ..addFont(
        Future.value(ByteData.sublistView(File(previewFont).readAsBytesSync())),
      );
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    await tester.binding.setSurfaceSize(const Size(390, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final key = GlobalKey();
    final theme = ThemePresets.lightPresets.values
        .firstWhere((t) => t.name == 'Golden Summer')
        .toThemeData();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: RepaintBoundary(
          key: key,
          child: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(size: Size(390, 780)),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SmartDateRangePicker(
                  initialRange: DateTimeRange(
                    start: DateTime(2026, 9, 7),
                    end: DateTime(2026, 9, 13),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    Future<void> capture(GlobalKey boundaryKey, String name) =>
        tester.runAsync(() async {
          final boundary =
              boundaryKey.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final output = File('build/$name.png');
          await output.parent.create(recursive: true);
          await output.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
    await capture(key, 'sprint_16_4_1_calendar');
    await tester.ensureVisible(find.byIcon(Icons.date_range));
    await tester.pumpAndSettle();
    await capture(key, 'sprint_16_4_1_calendar_summary');

    SharedPreferences.setMockInitialValues({});
    final homeKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: RepaintBoundary(
          key: homeKey,
          child: const MediaQuery(
            data: MediaQueryData(
              size: Size(390, 780),
              padding: EdgeInsets.only(top: 24),
            ),
            child: HomePage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await capture(homeKey, 'sprint_16_4_1_today');
  }, skip: previewFont.isEmpty);
  test('Previous completed days exclude today across calendar boundaries', () {
    final week = previousCompleteDays(DateTime(2026, 9, 14), 7);
    expect(week.start, DateTime(2026, 9, 7));
    expect(week.end, DateTime(2026, 9, 13));
    final year = previousCompleteDays(DateTime(2026, 1, 1), 7);
    expect(year.start, DateTime(2025, 12, 25));
    expect(year.end, DateTime(2025, 12, 31));
    final leap = previousCompleteDays(DateTime(2024, 3, 1), 1);
    expect(leap.start, DateTime(2024, 2, 29));
    expect(leap.end, leap.start);
  });

  testWidgets('Keyboard Next visits Month then Year without skipping', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DatePartsField(date: DateTime(2026, 9, 14), onChanged: (_) {}),
        ),
      ),
    );
    final fields = find.byType(TextField);
    await tester.tap(fields.at(0));
    await tester.showKeyboard(fields.at(0));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(tester.widget<TextField>(fields.at(1)).focusNode!.hasFocus, isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();
    expect(tester.widget<TextField>(fields.at(2)).focusNode!.hasFocus, isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tester.widget<TextField>(fields.at(2)).focusNode!.hasFocus, isFalse);
  });

  for (final size in [
    const Size(320, 640),
    const Size(640, 360),
    const Size(800, 1000),
  ]) {
    testWidgets('Range picker fits $size with enlarged text and keyboard', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.3),
              viewInsets: EdgeInsets.only(bottom: size.height * .4),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SmartDateRangePicker(
                initialRange: DateTimeRange(
                  start: DateTime(2026, 9, 7),
                  end: DateTime(2026, 9, 13),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .getBottomRight(find.widgetWithText(FilledButton, 'Apply Range'))
            .dy,
        lessThanOrEqualTo(size.height * .6),
      );
    });
  }

  testWidgets(
    'Record hero paints at top while back button clears system inset',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemePresets.lightPresets.values.first.toThemeData(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 600),
              padding: EdgeInsets.only(top: 28),
            ),
            child: Scaffold(
              body: RecordHero(date: DateTime(2026, 9, 5), onBack: () {}),
            ),
          ),
        ),
      );
      expect(tester.getTopLeft(find.byType(RecordHero)).dy, 0);
      expect(
        tester.getTopLeft(find.byTooltip('Back to History')).dy,
        greaterThanOrEqualTo(28),
      );
      expect(tester.getSize(find.byType(RecordHero)).height, 140);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('New List is icon-only and shadow follows horizontal overflow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Widget app(List<ShoppingListGroup> lists) => MaterialApp(
      theme: ThemePresets.lightPresets.values.first.toThemeData(),
      home: Scaffold(
        body: ShoppingListSwitcher(
          lists: lists,
          activeListId: 'default-list',
          itemCountForList: (_) => 0,
          onSelected: (_) {},
          onCreate: () {},
          onManage: (_) {},
        ),
      ),
    );
    await tester.pumpWidget(app([ShoppingListGroup.defaultList]));
    await tester.pumpAndSettle();
    expect(find.text('New List'), findsNothing);
    expect(find.byTooltip('New shopping list'), findsOneWidget);
    expect(find.byKey(const ValueKey('new-list-divider')), findsOneWidget);
    expect(find.byKey(const ValueKey('list-section-divider')), findsOneWidget);
    expect(find.byKey(const ValueKey('list-overflow-shadow')), findsNothing);
    await tester.pumpWidget(
      app([
        ShoppingListGroup.defaultList,
        const ShoppingListGroup(
          id: 'grandmother',
          name: 'Grandmother',
          position: 1,
        ),
        const ShoppingListGroup(
          id: 'family',
          name: 'Family shopping',
          position: 2,
        ),
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('list-overflow-shadow')), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(-900, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('list-overflow-shadow')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('History badges have two bindings and month cards omit month', (
    tester,
  ) async {
    final past = DateTime.now().subtract(const Duration(days: 7));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.lightPresets.values.first.toThemeData(),
        home: Scaffold(
          body: Column(
            children: [
              HistoryDateBadge(date: past),
              SessionCard(
                session: ShoppingSession(
                  id: 'past',
                  date: past,
                  items: const [],
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('calendar-binding-left')),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const ValueKey('calendar-binding-right')),
      findsNWidgets(2),
    );
    expect(find.text(DateFormat('EEEE').format(past)), findsOneWidget);
    expect(find.text(DateFormat('EEEE, MMMM').format(past)), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today hero fills the top and includes the system inset', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.lightPresets.values.first.toThemeData(),
        home: const MediaQuery(
          data: MediaQueryData(
            size: Size(320, 640),
            padding: EdgeInsets.only(top: 24),
          ),
          child: HomePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final hero = find.byKey(const ValueKey('today-shopping-hero-surface'));
    expect(tester.getTopLeft(hero), Offset.zero);
    expect(tester.getSize(hero), const Size(320, 140));
    expect(tester.takeException(), isNull);
  });
}
