import 'dart:math' as math;
import 'package:shoptrack/core/localization/shoptrack_text.dart';
import 'package:flutter/material.dart';
import '../../../../core/calendar/shop_calendar.dart';
import '../../../../core/theme/theme_presets.dart';
import '../../../../core/widgets/date_parts_field.dart';

class DateRangeSelection {
  const DateRangeSelection(this.range);
  final DateTimeRange? range;
}

/// Calendar-day arithmetic also works across month/year and DST boundaries.
DateTimeRange previousCompleteDays(DateTime today, int days) => DateTimeRange(
  start: DateTime(today.year, today.month, today.day - days),
  end: DateTime(today.year, today.month, today.day - 1),
);

class SmartDateRangePicker extends StatefulWidget {
  const SmartDateRangePicker({super.key, this.initialRange});
  final DateTimeRange? initialRange;
  @override
  State<SmartDateRangePicker> createState() => _SmartDateRangePickerState();
}

class _SmartDateRangePickerState extends State<SmartDateRangePicker> {
  late DateTime _start, _end, _month;
  bool _editingEnd = false, _valid = true, _hasSelection = true;
  @override
  void initState() {
    super.initState();
    _start = widget.initialRange?.start ?? DateUtils.dateOnly(DateTime.now());
    _end = widget.initialRange?.end ?? _start;
    _month = _start;
  }

  void _select(DateTime? date, {bool calendar = false}) {
    setState(() {
      _valid = date != null;
      if (date == null) return;
      if (!_hasSelection) {
        _start = date;
        _end = date;
      }
      if (_editingEnd) {
        _end = date;
      } else {
        _start = date;
      }
      _hasSelection = true;
      _month = date;
      if (calendar && !_editingEnd) {
        if (_end.isBefore(_start)) _end = _start;
        _editingEnd = true;
      }
    });
    if (calendar) FocusScope.of(context).unfocus();
  }

  void _clear() {
    final today = DateUtils.dateOnly(DateTime.now());
    FocusScope.of(context).unfocus();
    setState(() {
      _start = today;
      _end = today;
      _month = today;
      _editingEnd = false;
      _valid = true;
      _hasSelection = false;
    });
  }

  void _preset(int index) {
    final today = DateUtils.dateOnly(DateTime.now());
    final calendar = ShopCalendarScope.of(context);
    final todayParts = calendar.parts(today);
    var start = today;
    var end = today;
    switch (index) {
      case 0:
        final range = previousCompleteDays(today, 7);
        start = range.start;
        end = range.end;
      case 1:
        final range = previousCompleteDays(today, 30);
        start = range.start;
        end = range.end;
      case 2:
        start = calendar.monthOffset(today, -3, keepDay: true);
      case 3:
        start = calendar.fromParts(todayParts.year, 1, 1)!;
      case 4:
        start = calendar.fromParts(todayParts.year - 1, 1, 1)!;
        final nextYear = calendar.fromParts(todayParts.year, 1, 1)!;
        end = DateTime(nextYear.year, nextYear.month, nextYear.day - 1);
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _start = start;
      _end = end;
      _month = start;
      _valid = true;
      _hasSelection = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final calendar = ShopCalendarScope.of(context);
    final previousMonth = calendar.monthOffset(_month, -1);
    final nextMonth = calendar.monthOffset(_month, 1);
    final calendarAccent =
        Theme.of(context).extension<ShopTrackThemeTokens>()?.calendarAccent ??
        colors.secondary;
    final media = MediaQuery.of(context);
    final error = !_valid
        ? 'Enter a valid day, month and year.'
        : _end.isBefore(_start)
        ? 'End date must be on or after start date.'
        : null;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: math.min(
            580,
            math.max(
              0,
              media.size.height -
                  media.viewInsets.bottom -
                  media.padding.top -
                  16,
            ),
          ),
          child: Material(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ShopText(
                                'Select Date Range',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              tooltip: shopTr(context, 'Close'),
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 40,
                                height: 40,
                              ),
                            ),
                          ],
                        ),
                        Divider(color: colors.outlineVariant),
                        SizedBox(height: 7),
                        Row(
                          children: [
                            for (final end in [false, true])
                              Expanded(
                                child: TextButton(
                                  onPressed: () => setState(() {
                                    _editingEnd = end;
                                    _valid = true;
                                    final date = end ? _end : _start;
                                    _month = date;
                                  }),
                                  style: TextButton.styleFrom(
                                    foregroundColor: _editingEnd == end
                                        ? colors.onSecondary
                                        : colors.onSurface,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 9,
                                    ),
                                    minimumSize: const Size(0, 40),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    backgroundColor: _editingEnd == end
                                        ? colors.secondary
                                        : null,
                                  ),
                                  child: ShopText(
                                    end ? 'End Date' : 'Start Date',
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        DatePartsField(
                          key: ValueKey(_editingEnd),
                          date: _hasSelection
                              ? (_editingEnd ? _end : _start)
                              : null,
                          onChanged: _select,
                        ),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: ShopText(
                              error,
                              style: TextStyle(color: colors.error),
                            ),
                          ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            IconButton(
                              tooltip: shopTr(context, 'Previous month'),
                              onPressed:
                                  !previousMonth.isBefore(
                                    calendar.monthStart(
                                      ShopCalendar.firstSelectableDate,
                                    ),
                                  )
                                  ? () => setState(() => _month = previousMonth)
                                  : null,
                              icon: Icon(
                                Directionality.of(context) == TextDirection.rtl
                                    ? Icons.chevron_right
                                    : Icons.chevron_left,
                                textDirection: TextDirection.ltr,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            Expanded(
                              child: Text(
                                shopDate(context, _month, 'yMMMM'),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              tooltip: shopTr(context, 'Next month'),
                              onPressed:
                                  !nextMonth.isAfter(
                                    calendar.monthStart(
                                      ShopCalendar.lastSelectableDate,
                                    ),
                                  )
                                  ? () => setState(() => _month = nextMonth)
                                  : null,
                              icon: Icon(
                                Directionality.of(context) == TextDirection.rtl
                                    ? Icons.chevron_left
                                    : Icons.chevron_right,
                                textDirection: TextDirection.ltr,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        _calendar(colors),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(
                            children: [
                              for (var i = 0; i < 5; i++)
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    end: 8,
                                  ),
                                  child: ActionChip(
                                    backgroundColor:
                                        colors.brightness == Brightness.dark
                                        ? colors.onSurface.withValues(
                                            alpha: .05,
                                          )
                                        : null,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    label: ShopText(
                                      [
                                        'Previous 7 Days',
                                        'Previous 30 Days',
                                        'Last 3 Months',
                                        'This Year',
                                        'Last Year',
                                      ][i],
                                    ),
                                    onPressed: () => _preset(i),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colors.secondary.withValues(alpha: .12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.date_range, color: calendarAccent),
                              Container(
                                width: 1.5,
                                height: 26,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                color: calendarAccent.withValues(alpha: .5),
                              ),
                              Flexible(
                                child: Text(
                                  _hasSelection
                                      ? '${shopDate(context, _start)} — ${shopDate(context, _end)}'
                                      : shopTr(
                                          context,
                                          'No Date Range Selected',
                                        ),
                                  style: TextStyle(color: colors.onSurface),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor:
                                colors.brightness == Brightness.dark
                                ? colors.onSurface.withValues(alpha: .05)
                                : null,
                            foregroundColor: colors.onSurface,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: _clear,
                          child: const ShopText('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.secondary,
                            foregroundColor: colors.onSecondary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: error == null
                              ? () => Navigator.pop(
                                  context,
                                  DateRangeSelection(
                                    _hasSelection
                                        ? DateTimeRange(
                                            start: _start,
                                            end: _end,
                                          )
                                        : null,
                                  ),
                                )
                              : null,
                          child: const ShopText('Apply Range'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _calendar(ColorScheme colors) {
    final calendar = ShopCalendarScope.of(context);
    final firstDay = calendar.monthStart(_month);
    final offset = firstDay.weekday % 7;
    final days = calendar.daysInMonth(_month);
    return Column(
      children: [
        Row(
          children: [
            for (final day in shopWeekdays(context))
              Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      color: colors.secondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: offset + days,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 38,
          ),
          itemBuilder: (context, index) {
            if (index < offset) return const SizedBox.shrink();
            final date = DateTime(
              firstDay.year,
              firstDay.month,
              firstDay.day + index - offset,
            );
            final disabled = !calendar.isSelectable(date);
            final endpoint =
                _hasSelection &&
                (DateUtils.isSameDay(date, _start) ||
                    DateUtils.isSameDay(date, _end));
            final inside =
                _hasSelection && !date.isBefore(_start) && !date.isAfter(_end);
            return Semantics(
              label: shopDate(context, date, 'yMMMMd'),
              enabled: !disabled,
              selected: endpoint,
              button: true,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (inside && !DateUtils.isSameDay(_start, _end))
                    Positioned.fill(
                      top: 2,
                      bottom: 2,
                      child: LayoutBuilder(
                        builder: (context, constraints) => Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: DateUtils.isSameDay(date, _start)
                                ? constraints.maxWidth / 2
                                : 0,
                            end: DateUtils.isSameDay(date, _end)
                                ? constraints.maxWidth / 2
                                : 0,
                          ),
                          child: ColoredBox(
                            color: colors.secondary.withValues(alpha: .20),
                          ),
                        ),
                      ),
                    ),
                  if (endpoint)
                    Center(
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: disabled
                          ? null
                          : () => _select(date, calendar: true),
                      child: Center(
                        child: Text(
                          shopNumber(context, index - offset + 1),
                          style: TextStyle(
                            color: disabled
                                ? Theme.of(context).disabledColor
                                : endpoint
                                ? colors.onSecondary
                                : colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
