import 'package:flutter/material.dart';
import '../localization/shoptrack_text.dart';
import 'package:flutter/services.dart';
import '../calendar/shop_calendar.dart';

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
  String _language = 'en';
  ShopCalendar _calendar = const ShopCalendar();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    final calendar = ShopCalendarScope.of(context);
    if (_language != language ||
        _calendar.system != calendar.system ||
        _calendar.hijriAdjustment != calendar.hijriAdjustment) {
      _language = language;
      _calendar = calendar;
      _sync();
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
    final date = _calendar.parts(widget.date!);
    final values = [date.day, date.month, date.year];
    for (var i = 0; i < 3; i++) {
      _fields[i].text = localizeDateDigits('${values[i]}', _language);
    }
  }

  @override
  void didUpdateWidget(covariant DatePartsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) _sync();
  }

  void _changed(String _) {
    final d = int.tryParse(normalizeDateDigits(_fields[0].text)),
        m = int.tryParse(normalizeDateDigits(_fields[1].text)),
        y = int.tryParse(normalizeDateDigits(_fields[2].text));
    DateTime? date;
    if (d != null && m != null && y != null && _fields[2].text.length == 4) {
      final candidate = _calendar.fromParts(y, m, d);
      if (candidate != null && _calendar.isSelectable(candidate)) {
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
              FilteringTextInputFormatter.allow(RegExp('[0-9০-৯٠-٩۰-۹]')),
              TextInputFormatter.withFunction(
                (oldValue, newValue) => newValue.copyWith(
                  text: localizeDateDigits(newValue.text, _language),
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
