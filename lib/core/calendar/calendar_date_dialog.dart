import 'package:flutter/material.dart';

import '../localization/shoptrack_text.dart';
import '../widgets/shoptrack_date_picker.dart';
import '../widgets/shoptrack_motion.dart';
import 'shop_calendar.dart';

/// Both pickers return a Gregorian civil day; only the presentation differs.
Future<DateTime?> showPreferredDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String helpText = 'Select Date',
}) {
  if (ShopCalendarScope.of(context).isHijri) {
    return ShopTrackDatePicker.show(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: helpText,
    );
  }
  return showShopDialog<DateTime>(
    context: context,
    builder: (_) => DatePickerDialog(
      initialDate: DateUtils.dateOnly(initialDate),
      firstDate: DateUtils.dateOnly(firstDate),
      lastDate: DateUtils.dateOnly(lastDate),
      helpText: shopTr(context, helpText),
    ),
  );
}
