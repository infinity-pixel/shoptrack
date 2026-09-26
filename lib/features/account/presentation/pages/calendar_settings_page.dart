import 'package:flutter/material.dart';

import '../../../../core/calendar/shop_calendar.dart';
import '../../../../core/localization/shoptrack_text.dart';
import '../../../../services/settings_service.dart';

/// Calendar preferences change presentation and selection, never record IDs.
class CalendarSettingsPage extends StatefulWidget {
  const CalendarSettingsPage({super.key, required this.settingsService});

  final SettingsService settingsService;

  @override
  State<CalendarSettingsPage> createState() => _CalendarSettingsPageState();
}

class _CalendarSettingsPageState extends State<CalendarSettingsPage> {
  late CalendarPreference _calendar;
  late int _adjustment;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _calendar = widget.settingsService.settings.calendar;
    _adjustment = widget.settingsService.settings.hijriAdjustment;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.settingsService.updateCalendar(_calendar, _adjustment);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const ShopText('Calendar')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const ShopText('Calendar and language are independent.'),
                  const SizedBox(height: 12),
                  for (final option in CalendarPreference.values)
                    Card(
                      child: ListTile(
                        enabled: !_saving,
                        selected: _calendar == option,
                        leading: Icon(
                          _calendar == option
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                        ),
                        title: ShopText(
                          option == CalendarPreference.hijri
                              ? 'Hijri (Umm al-Qura)'
                              : 'Gregorian',
                        ),
                        onTap: () => setState(() => _calendar = option),
                      ),
                    ),
                  if (_calendar == CalendarPreference.hijri) ...[
                    const SizedBox(height: 16),
                    ShopText(
                      'Hijri date adjustment',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const ShopText(
                      'Adjust the Hijri date to match your local moon-sighting announcement.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (var days = -2; days <= 2; days++)
                          ChoiceChip(
                            key: ValueKey('hijri-adjustment-$days'),
                            selected: _adjustment == days,
                            showCheckmark: false,
                            tooltip: days == 0
                                ? shopTr(context, 'No adjustment')
                                : shopTr(context, '{count} days').replaceAll(
                                    '{count}',
                                    shopNumber(context, days),
                                  ),
                            label: Text(
                              '${days == 0
                                  ? ''
                                  : days > 0
                                  ? '+'
                                  : '−'}${shopNumber(context, days.abs())}',
                              textDirection: TextDirection.ltr,
                            ),
                            onSelected: _saving
                                ? null
                                : (_) => setState(() => _adjustment = days),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ShopText(
                      'Uses the Umm al-Qura calendar. Dates may differ from local moon-sighting announcements.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShopText(
                            'Today’s preview',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ShopCalendarScope(
                            calendar: ShopCalendar(
                              system: _calendar,
                              hijriAdjustment: _adjustment,
                            ),
                            child: Builder(
                              builder: (context) => Text(
                                shopDate(
                                  context,
                                  DateTime.now(),
                                  'EEEE, d MMMM yyyy',
                                ),
                                style: theme.textTheme.titleLarge,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const ShopText(
                    'This changes calendar labels, not your saved shopping dates.',
                  ),
                  if (_failed) ...[
                    const SizedBox(height: 12),
                    ShopText(
                      'Could not save the calendar preference.',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const ShopText('Save'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
