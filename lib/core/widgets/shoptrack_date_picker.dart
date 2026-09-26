import 'package:flutter/material.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';
import 'package:intl/intl.dart';
import 'date_parts_field.dart';

class ShopTrackDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String helpText;
  final String confirmText;

  const ShopTrackDatePicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.helpText = 'Select Date',
    this.confirmText = 'OK',
  });

  @override
  State<ShopTrackDatePicker> createState() => _ShopTrackDatePickerState();

  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    String helpText = 'Select Date',
    String confirmText = 'OK',
  }) {
    return showDialog<DateTime>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ShopTrackDatePicker(
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
          helpText: helpText,
          confirmText: confirmText,
        ),
      ),
    );
  }
}

class _ShopTrackDatePickerState extends State<ShopTrackDatePicker> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  void _onDateSelected(DateTime date) {
    if (date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate)) {
      return;
    }
    setState(() {
      _selectedDate = date;
      _displayedMonth = DateTime(date.year, date.month);
      _errorText = null;
    });
  }

  void _onManualInput(DateTime? parsed) {
    if (parsed != null) {
      if (parsed.isBefore(widget.firstDate) ||
          parsed.isAfter(widget.lastDate)) {
        setState(() => _errorText = 'Date out of range');
        return;
      }
      setState(() {
        _selectedDate = parsed;
        _displayedMonth = DateTime(parsed.year, parsed.month);
        _errorText = null;
      });
    } else {
      setState(() => _errorText = 'Enter a valid day, month and year.');
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + offset,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ShopText(
                  widget.helpText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  DatePartsField(
                    date: _selectedDate,
                    onChanged: _onManualInput,
                  ),
                  if (_errorText != null)
                    ShopText(
                      _errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 16),
                  _buildCalendarHeader(),
                  const SizedBox(height: 8),
                  _buildCalendarGrid(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const ShopText('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _errorText == null
                    ? () => Navigator.pop(context, _selectedDate)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 0,
                ),
                child: ShopText(widget.confirmText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Text(
            DateFormat('MMMM yyyy').format(_displayedMonth),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        IconButton(
          onPressed: () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final lastDay = DateTime(
      _displayedMonth.year,
      _displayedMonth.month + 1,
      0,
    );
    final daysInMonth = lastDay.day;
    final weekdayOfFirstDay =
        firstDay.weekday % 7; // Sunday is 0 if we want it to be

    final List<Widget> dayWidgets = [];

    // Weekday headers
    final weekdays = shopIsBangla(context)
        ? ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহ', 'শুক্র', 'শনি']
        : ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    for (var day in weekdays) {
      dayWidgets.add(
        Center(
          child: Text(
            day,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Empty cells before first day
    for (int i = 0; i < weekdayOfFirstDay; i++) {
      dayWidgets.add(const SizedBox.shrink());
    }

    // Days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
      final isSelected =
          date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final isDisabled =
          date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate);

      dayWidgets.add(
        InkWell(
          onTap: isDisabled ? null : () => _onDateSelected(date),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                shopNumber(context, day),
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : (isDisabled
                            ? Theme.of(context).disabledColor
                            : Theme.of(context).colorScheme.onSurface),
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }
}
