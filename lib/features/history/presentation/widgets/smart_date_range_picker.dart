import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/date_parts_field.dart';

class DateRangeSelection {
  const DateRangeSelection(this.range);
  final DateTimeRange? range;
}

class SmartDateRangePicker extends StatefulWidget {
  const SmartDateRangePicker({super.key, this.initialRange});
  final DateTimeRange? initialRange;
  @override
  State<SmartDateRangePicker> createState() => _SmartDateRangePickerState();
}

class _SmartDateRangePickerState extends State<SmartDateRangePicker> {
  late DateTime _start, _end, _month;
  bool _editingEnd = false, _valid = true;
  @override
  void initState() {
    super.initState();
    _start = widget.initialRange?.start ?? DateUtils.dateOnly(DateTime.now());
    _end = widget.initialRange?.end ?? _start;
    _month = DateTime(_start.year, _start.month);
  }

  void _select(DateTime? date, {bool calendar = false}) {
    setState(() {
      _valid = date != null;
      if (date == null) return;
      if (_editingEnd) {
        _end = date;
      } else {
        _start = date;
      }
      _month = DateTime(date.year, date.month);
      if (calendar && !_editingEnd) {
        if (_end.isBefore(_start)) _end = _start;
        _editingEnd = true;
      }
    });
    if (calendar) FocusScope.of(context).unfocus();
  }

  void _preset(int index) {
    final today = DateUtils.dateOnly(DateTime.now());
    var start = today;
    var end = today;
    switch (index) {
      case 0:
        start = today.subtract(const Duration(days: 7));
      case 1:
        start = today.subtract(const Duration(days: 30));
      case 2:
        final month = DateTime(today.year, today.month - 3);
        start = DateTime(
          month.year,
          month.month,
          math.min(today.day, DateTime(month.year, month.month + 1, 0).day),
        );
      case 3:
        start = DateTime(today.year, 1, 1);
      case 4:
        start = DateTime(today.year - 1, 1, 1);
        end = DateTime(today.year - 1, 12, 31);
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _start = start;
      _end = end;
      _month = DateTime(start.year, start.month);
      _valid = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final media = MediaQuery.of(context);
    final error = !_valid
        ? 'Enter a valid date (2000–2100).'
        : _end.isBefore(_start)
        ? 'End date must be on or after start date.'
        : null;
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: math.min(
            690,
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Select date range',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            for (final end in [false, true])
                              Expanded(
                                child: TextButton(
                                  onPressed: () => setState(() {
                                    _editingEnd = end;
                                    _valid = true;
                                    final date = end ? _end : _start;
                                    _month = DateTime(date.year, date.month);
                                  }),
                                  style: TextButton.styleFrom(
                                    backgroundColor: _editingEnd == end
                                        ? colors.primaryContainer
                                        : null,
                                  ),
                                  child: Text(end ? 'End date' : 'Start date'),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DatePartsField(
                          key: ValueKey(_editingEnd),
                          date: _editingEnd ? _end : _start,
                          onChanged: _select,
                        ),
                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              error,
                              style: TextStyle(color: colors.error),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Previous month',
                              onPressed: _month.isAfter(DateTime(2000))
                                  ? () => setState(
                                      () => _month = DateTime(
                                        _month.year,
                                        _month.month - 1,
                                      ),
                                    )
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Expanded(
                              child: Text(
                                DateFormat.yMMMM().format(_month),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Next month',
                              onPressed: _month.isBefore(DateTime(2100, 12))
                                  ? () => setState(
                                      () => _month = DateTime(
                                        _month.year,
                                        _month.month + 1,
                                      ),
                                    )
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        _calendar(colors),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (var i = 0; i < 5; i++)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ActionChip(
                                    label: Text(
                                      [
                                        'Last 7 Days',
                                        'Last 30 Days',
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
                        const SizedBox(height: 12),
                        Text(
                          '${DateFormat.yMMMd().format(_start)} — ${DateFormat.yMMMd().format(_end)}',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(
                            context,
                            const DateRangeSelection(null),
                          ),
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: error == null
                              ? () => Navigator.pop(
                                  context,
                                  DateRangeSelection(
                                    DateTimeRange(start: _start, end: _end),
                                  ),
                                )
                              : null,
                          child: const Text('Apply range'),
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
    final offset = _month.weekday % 7;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    return Column(
      children: [
        Row(
          children: [
            for (final day in ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
              Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(color: colors.onSurfaceVariant),
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
            mainAxisExtent: 44,
          ),
          itemBuilder: (context, index) {
            if (index < offset) return const SizedBox.shrink();
            final date = DateTime(
              _month.year,
              _month.month,
              index - offset + 1,
            );
            final endpoint =
                DateUtils.isSameDay(date, _start) ||
                DateUtils.isSameDay(date, _end);
            final inside = !date.isBefore(_start) && !date.isAfter(_end);
            return Semantics(
              label: DateFormat.yMMMMd().format(date),
              selected: endpoint,
              button: true,
              child: Material(
                color: endpoint
                    ? colors.primary
                    : inside
                    ? colors.primaryContainer
                    : colors.surface,
                borderRadius: endpoint
                    ? BorderRadius.circular(24)
                    : BorderRadius.zero,
                child: InkWell(
                  onTap: () => _select(date, calendar: true),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: endpoint ? colors.onPrimary : colors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
