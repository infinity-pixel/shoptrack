import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/date_parser.dart';
import '../utils/date_input_formatter.dart';

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
  late TextEditingController _inputController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _inputController = TextEditingController(text: DateParser.format(_selectedDate));
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _onDateSelected(DateTime date) {
    if (date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate)) return;
    setState(() {
      _selectedDate = date;
      _inputController.text = DateParser.format(date);
      _errorText = null;
    });
  }

  void _onManualInput(String value) {
    final parsed = DateParser.parse(value);
    if (parsed != null) {
      if (parsed.isBefore(widget.firstDate) || parsed.isAfter(widget.lastDate)) {
        setState(() => _errorText = 'Date out of range');
        return;
      }
      setState(() {
        _selectedDate = parsed;
        _displayedMonth = DateTime(parsed.year, parsed.month);
        _errorText = null;
      });
    } else {
      setState(() => _errorText = 'Invalid format (d/m/yyyy)');
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + offset);
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
              Text(
                widget.helpText,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildManualInput(),
          const SizedBox(height: 16),
          _buildCalendarHeader(),
          const SizedBox(height: 8),
          _buildCalendarGrid(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _errorText == null ? () => Navigator.pop(context, _selectedDate) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: Text(widget.confirmText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualInput() {
    return TextField(
      controller: _inputController,
      keyboardType: TextInputType.datetime,
      inputFormatters: [DateInputFormatter()],
      decoration: InputDecoration(
        labelText: 'Manual Entry',
        hintText: 'd/m/yyyy',
        errorText: _errorText,
        prefixIcon: const Icon(Icons.edit_calendar, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onChanged: _onManualInput,
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
        Text(
          DateFormat('MMMM yyyy').format(_displayedMonth),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
    final lastDay = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final weekdayOfFirstDay = firstDay.weekday % 7; // Sunday is 0 if we want it to be

    final List<Widget> dayWidgets = [];

    // Weekday headers
    const weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    for (var day in weekdays) {
      dayWidgets.add(
        Center(
          child: Text(
            day,
            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold),
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
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final isDisabled = date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate);

      dayWidgets.add(
        InkWell(
          onTap: isDisabled ? null : () => _onDateSelected(date),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : null,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDisabled ? Colors.grey[300] : Colors.black87),
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
