import 'package:flutter/material.dart';
import '../localization/shoptrack_text.dart';
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
  bool _bangla = false;

  String _digits(String text, {required bool bangla}) {
    const english = '0123456789', bengali = '০১২৩৪৫৬৭৮৯';
    final from = bangla ? english : bengali;
    final to = bangla ? bengali : english;
    return text.split('').map((char) {
      final index = from.indexOf(char);
      return index < 0 ? char : to[index];
    }).join();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bangla = shopIsBangla(context);
    if (_bangla != bangla) {
      _bangla = bangla;
      for (final field in _fields) {
        field.value = field.value.copyWith(
          text: _digits(field.text, bangla: bangla),
        );
      }
    }
  }

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
      _fields[i].text = _digits('${values[i]}', bangla: _bangla);
    }
  }

  @override
  void didUpdateWidget(covariant DatePartsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) _sync();
  }

  void _changed(String _) {
    final d = int.tryParse(_digits(_fields[0].text, bangla: false)),
        m = int.tryParse(_digits(_fields[1].text, bangla: false)),
        y = int.tryParse(_digits(_fields[2].text, bangla: false));
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
              FilteringTextInputFormatter.allow(RegExp('[0-9০-৯]')),
              TextInputFormatter.withFunction(
                (oldValue, newValue) => newValue.copyWith(
                  text: _digits(newValue.text, bangla: _bangla),
                ),
              ),
              LengthLimitingTextInputFormatter(i == 2 ? 4 : 2),
            ],
            decoration: InputDecoration(
              filled: Theme.of(context).brightness == Brightness.dark,
              fillColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: .05),
              labelText: shopTr(context, ['Day', 'Month', 'Year'][i]),
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
