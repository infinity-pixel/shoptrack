import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DatePartsField extends StatefulWidget {
  const DatePartsField({
    super.key,
    required this.date,
    required this.onChanged,
  });
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;
  @override
  State<DatePartsField> createState() => _DatePartsFieldState();
}

class _DatePartsFieldState extends State<DatePartsField> {
  late final List<TextEditingController> _fields;
  final _focusNodes = List.generate(3, (_) => FocusNode());
  @override
  void initState() {
    super.initState();
    _fields = List.generate(3, (_) => TextEditingController());
    _sync();
  }

  void _sync() {
    if (widget.date == null) {
      for (final field in _fields) {
        field.clear();
      }
      return;
    }
    final values = [widget.date!.day, widget.date!.month, widget.date!.year];
    for (var i = 0; i < 3; i++) {
      _fields[i].text = '${values[i]}';
    }
  }

  @override
  void didUpdateWidget(covariant DatePartsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) _sync();
  }

  void _changed(String _) {
    final d = int.tryParse(_fields[0].text),
        m = int.tryParse(_fields[1].text),
        y = int.tryParse(_fields[2].text);
    DateTime? date;
    if (d != null &&
        m != null &&
        y != null &&
        _fields[2].text.length == 4 &&
        y >= 2000 &&
        y <= 2100) {
      final candidate = DateTime(y, m, d);
      if (candidate.day == d && candidate.month == m && candidate.year == y) {
        date = candidate;
      }
    }
    widget.onChanged(date);
  }

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < 3; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _fields[i],
            focusNode: _focusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: i == 2
                ? TextInputAction.done
                : TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(i == 2 ? 4 : 2),
            ],
            decoration: InputDecoration(
              labelText: ['Day', 'Month', 'Year'][i],
              isDense: true,
              floatingLabelAlignment: FloatingLabelAlignment.center,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
            ),
            onChanged: _changed,
            // Flutter's default editing completion also advances focus for
            // Next. Own the transition here so it runs exactly once.
            onEditingComplete: () {},
            onSubmitted: (_) {
              if (i < 2) {
                _focusNodes[i + 1].requestFocus();
              } else {
                FocusScope.of(context).unfocus();
              }
            },
          ),
        ),
      ],
    ],
  );
}
