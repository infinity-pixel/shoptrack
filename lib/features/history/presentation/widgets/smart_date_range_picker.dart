import 'package:flutter/material.dart';
import '../../../../core/widgets/shoptrack_date_picker.dart';

class SmartDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialRange;

  const SmartDateRangePicker({super.key, this.initialRange});

  @override
  State<SmartDateRangePicker> createState() => _SmartDateRangePickerState();
}

class _SmartDateRangePickerState extends State<SmartDateRangePicker> {
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialRange != null) {
      _startDate = widget.initialRange!.start;
    }
  }

  void _selectPreset(String label) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime start;
    DateTime end = today;

    switch (label) {
      case 'Last 7 Days':
        start = today.subtract(const Duration(days: 7));
        break;
      case 'Last 30 Days':
        start = today.subtract(const Duration(days: 30));
        break;
      case 'Last 3 Months':
        start = DateTime(today.year, today.month - 3, today.day);
        // Handle month subtraction edge cases (e.g. May 31 -> Feb 28)
        if (start.month == (today.month - 3 + 12) % 12 && start.day != today.day) {
           start = DateTime(today.year, today.month - 2, 0);
        }
        break;
      case 'This Year':
        start = DateTime(today.year, 1, 1);
        break;
      case 'Last Year':
        start = DateTime(today.year - 1, 1, 1);
        end = DateTime(today.year - 1, 12, 31);
        break;
      default:
        return;
    }

    Navigator.pop(context, DateTimeRange(start: start, end: end));
  }

  Future<void> _selectCustom() async {
    final start = await ShopTrackDatePicker.show(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Select start date',
      confirmText: 'Next',
    );

    if (start == null || !mounted) return;

    final end = await ShopTrackDatePicker.show(
      context: context,
      initialDate: start.isAfter(DateTime.now()) ? start : DateTime.now(),
      firstDate: start,
      lastDate: DateTime(2100),
      helpText: 'Select end date',
      confirmText: 'Done',
    );

    if (end == null || !mounted) return;

    Navigator.pop(context, DateTimeRange(start: start, end: end));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Select Date Range',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildPresetChip('Last 7 Days'),
              _buildPresetChip('Last 30 Days'),
              _buildPresetChip('Last 3 Months'),
              _buildPresetChip('This Year'),
              _buildPresetChip('Last Year'),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _selectCustom,
            icon: const Icon(Icons.calendar_month),
            label: const Text('Custom Range'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _selectPreset(label),
    );
  }
}
