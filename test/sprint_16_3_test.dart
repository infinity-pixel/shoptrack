import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/core/widgets/date_parts_field.dart';
import 'package:shoptrack/core/widgets/shoptrack_date_picker.dart';
import 'package:shoptrack/features/history/presentation/widgets/smart_date_range_picker.dart';
import 'package:shoptrack/features/history/presentation/widgets/search_result_card.dart';
import 'package:shoptrack/models/shopping_search_result.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';

void main() {
  testWidgets(
    'Range calendar selects endpoints and Clear differs from cancellation',
    (tester) async {
      DateRangeSelection? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selected = await showModalBottomSheet<DateRangeSelection>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => SmartDateRangePicker(
                      initialRange: DateTimeRange(
                        start: DateTime(2026, 9, 13),
                        end: DateTime(2026, 9, 20),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('18'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply Range'));
      await tester.pumpAndSettle();
      expect(selected?.range?.start, DateTime(2026, 9, 15));
      expect(selected?.range?.end, DateTime(2026, 9, 18));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(find.text('Select Date Range'), findsOneWidget);
      expect(find.text('No Date Range Selected'), findsOneWidget);
      for (final field in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(field.controller?.text, isEmpty);
      }
      await tester.tap(find.text('Apply Range'));
      await tester.pumpAndSettle();
      expect(selected, isNotNull);
      expect(selected?.range, isNull);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(selected, isNull);
    },
  );
  testWidgets('Numeric date parts reject invalid leap days', (tester) async {
    DateTime? value;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DatePartsField(
            date: DateTime(2024, 2, 28),
            onChanged: (date) => value = date,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).at(0), '29');
    expect(value, DateTime(2024, 2, 29));
    await tester.enterText(find.byType(TextField).at(2), '2025');
    expect(value, isNull);
    await tester.enterText(find.byType(TextField).at(0), '28');
    expect(value, DateTime(2025, 2, 28));
  });

  testWidgets(
    'Range sheet remains usable above keyboard and validates ordering',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      DateRangeSelection? selection;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selection = await showModalBottomSheet<DateRangeSelection>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => MediaQuery(
                      data: const MediaQueryData(
                        size: Size(320, 640),
                        viewInsets: EdgeInsets.only(bottom: 280),
                      ),
                      child: SmartDateRangePicker(
                        initialRange: DateTimeRange(
                          start: DateTime(2026, 9, 13),
                          end: DateTime(2026, 9, 20),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester
            .getBottomRight(find.widgetWithText(FilledButton, 'Apply Range'))
            .dy,
        lessThanOrEqualTo(360),
      );
      await tester.tap(find.text('End Date'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '12');
      await tester.pump();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Apply Range'),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(find.byType(TextField).first, '13');
      await tester.pump();
      await tester.tap(find.text('Apply Range'));
      await tester.pumpAndSettle();
      expect(selection?.range?.start, DateTime(2026, 9, 13));
      expect(selection?.range?.end, DateTime(2026, 9, 13));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Single date dialog scrolls above keyboard', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            viewInsets: EdgeInsets.only(bottom: 280),
          ),
          child: Dialog(
            child: ShopTrackDatePicker(
              initialDate: DateTime(2026, 9, 13),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search tile uses quantity only and no unpurchased total', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.lightPresets.values.first.toThemeData(),
        home: Scaffold(
          body: SearchResultCard(
            result: ShoppingSearchResult(
              item: const ShoppingItem(
                id: 'rice',
                name: 'Rice',
                quantity: '5',
                shoppingUnit: ShoppingUnit.kg,
                priceValue: 650,
              ),
              session: ShoppingSession(
                id: 'day',
                date: DateTime(2026, 9, 13),
                items: const [],
              ),
            ),
            onTap: () {},
          ),
        ),
      ),
    );
    expect(find.text('5 kg'), findsOneWidget);
    expect(find.text('13'), findsOneWidget);
    expect(find.text('13 Sep 2026'), findsNothing);
    expect(find.text('—'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
