import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../models/app_settings.dart';
import 'umm_al_qura_data.dart';

export '../../models/app_settings.dart' show CalendarPreference;

/// Presentation calendar only. Session IDs, stored dates and cloud paths always
/// retain their Gregorian civil day, irrespective of this preference.
class ShopCalendar {
  const ShopCalendar({
    this.system = CalendarPreference.gregorian,
    this.hijriAdjustment = 0,
  }) : assert(hijriAdjustment >= -2 && hijriAdjustment <= 2);

  final CalendarPreference system;
  final int hijriAdjustment;
  bool get isHijri => system == CalendarPreference.hijri;

  static final firstSelectableDate = DateTime(2000);
  static final lastSelectableDate = DateTime(2100, 12, 31);
  static final _epoch = DateTime.utc(1882, 11, 12);
  static final _monthStarts = _buildMonthStarts();

  static List<int> _buildMonthStarts() {
    final starts = <int>[0];
    for (final mask in ummAlQuraMonthMasks) {
      for (var month = 1; month <= 12; month++) {
        starts.add(starts.last + ((mask & (1 << (12 - month))) != 0 ? 30 : 29));
      }
    }
    return List.unmodifiable(starts);
  }

  ShopCalendarDate parts(DateTime date) {
    if (!isHijri) return ShopCalendarDate(date.year, date.month, date.day);
    final days = DateTime.utc(
      date.year,
      date.month,
      date.day + hijriAdjustment,
    ).difference(_epoch).inDays;
    if (days < 0 || days >= _monthStarts.last) {
      throw RangeError('Date is outside the supported Umm al-Qura table.');
    }
    var low = 0, high = _monthStarts.length - 1;
    while (low + 1 < high) {
      final middle = (low + high) ~/ 2;
      if (_monthStarts[middle] <= days) {
        low = middle;
      } else {
        high = middle;
      }
    }
    return ShopCalendarDate(
      ummAlQuraFirstYear + low ~/ 12,
      low % 12 + 1,
      days - _monthStarts[low] + 1,
    );
  }

  /// Strict parsing: rejects day 30 in a 29-day month rather than normalizing
  /// into next month. The correction is inverted before returning a stored day.
  DateTime? fromParts(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1) return null;
    if (!isHijri) {
      final value = DateTime(year, month, day);
      return value.year == year && value.month == month && value.day == day
          ? value
          : null;
    }
    final index = (year - ummAlQuraFirstYear) * 12 + month - 1;
    if (index < 0 ||
        index >= _monthStarts.length - 1 ||
        day > _monthStarts[index + 1] - _monthStarts[index]) {
      return null;
    }
    final utc = _epoch.add(
      Duration(days: _monthStarts[index] + day - 1 - hijriAdjustment),
    );
    return DateTime(utc.year, utc.month, utc.day);
  }

  bool isSelectable(DateTime date) =>
      !date.isBefore(firstSelectableDate) && !date.isAfter(lastSelectableDate);

  DateTime monthStart(DateTime date) {
    final value = parts(date);
    return fromParts(value.year, value.month, 1)!;
  }

  DateTime monthOffset(DateTime date, int offset, {bool keepDay = false}) {
    final value = parts(date);
    final monthIndex = value.year * 12 + value.month - 1 + offset;
    final year = monthIndex ~/ 12, month = monthIndex % 12 + 1;
    final start = fromParts(year, month, 1);
    if (start == null) {
      throw RangeError('Month is outside the supported calendar.');
    }
    if (!keepDay) return start;
    final count = daysInMonth(start);
    return fromParts(year, month, value.day > count ? count : value.day)!;
  }

  int daysInMonth(DateTime date) {
    final value = parts(date);
    if (!isHijri) return DateTime(value.year, value.month + 1, 0).day;
    final index = (value.year - ummAlQuraFirstYear) * 12 + value.month - 1;
    return _monthStarts[index + 1] - _monthStarts[index];
  }

  String format(
    DateTime date, {
    String pattern = 'yMMMd',
    String locale = 'en',
  }) {
    final language = locale.split(RegExp('[-_]')).first;
    // intl ships en_US data without initialization. Plain MaterialApp widget
    // tests intentionally omit global localization delegates; keep them valid.
    if (language == 'en') locale = 'en_US';
    if (!isHijri) {
      return localizeDateDigits(
        DateFormat(pattern, locale).format(date),
        language,
      );
    }
    final value = parts(date);
    final resolved = DateFormat(pattern, locale).pattern!;
    final output = StringBuffer();
    final tokens = RegExp("('[^']*(?:''[^']*)*'|[a-zA-Z]+|[^a-zA-Z']+)");
    for (final match in tokens.allMatches(resolved)) {
      final token = match[0]!;
      if (token.startsWith("'")) {
        output.write(
          token.substring(1, token.length - 1).replaceAll("''", "'"),
        );
        continue;
      }
      // Split adjoining date/time fields (for example the dd in dd/MM/yyyy).
      final fields = RegExp(r'([a-zA-Z])\1*|[^a-zA-Z]+').allMatches(token);
      for (final field in fields) {
        final part = field[0]!;
        switch (part[0]) {
          case 'y':
            output.write(
              part.length == 2
                  ? '${value.year % 100}'.padLeft(2, '0')
                  : value.year,
            );
          case 'M':
          case 'L':
            output.write(
              part.length >= 3
                  ? (_hijriMonths[language] ??
                        _hijriMonths['en']!)[value.month - 1]
                  : '${value.month}'.padLeft(part.length, '0'),
            );
          case 'd':
            output.write('${value.day}'.padLeft(part.length, '0'));
          case 'G':
            output.write(
              language == 'ar'
                  ? 'هـ'
                  : language == 'bn'
                  ? 'হিজরি'
                  : 'AH',
            );
          default:
            output.write(
              RegExp(r'^[a-zA-Z]').hasMatch(part)
                  ? DateFormat(part, locale).format(date)
                  : part,
            );
        }
      }
    }
    return localizeDateDigits(output.toString(), language);
  }
}

class ShopCalendarDate {
  const ShopCalendarDate(this.year, this.month, this.day);
  final int year, month, day;
}

class ShopCalendarScope extends InheritedWidget {
  const ShopCalendarScope({
    super.key,
    required this.calendar,
    required super.child,
  });
  final ShopCalendar calendar;
  static ShopCalendar of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ShopCalendarScope>()
          ?.calendar ??
      const ShopCalendar();
  @override
  bool updateShouldNotify(ShopCalendarScope oldWidget) =>
      calendar.system != oldWidget.calendar.system ||
      calendar.hijriAdjustment != oldWidget.calendar.hijriAdjustment;
}

String shopDate(
  BuildContext context,
  DateTime date, [
  String pattern = 'yMMMd',
]) => ShopCalendarScope.of(context).format(
  date,
  pattern: pattern,
  locale: Localizations.localeOf(context).languageCode,
);

String normalizeDateDigits(String input) {
  const digits = ['০১২৩৪৫৬৭৮৯', '٠١٢٣٤٥٦٧٨٩', '۰۱۲۳۴۵۶۷۸۹'];
  for (final alphabet in digits) {
    for (var i = 0; i < 10; i++) {
      input = input.replaceAll(alphabet[i], '$i');
    }
  }
  return input;
}

String localizeDateDigits(String input, String language) {
  input = normalizeDateDigits(input);
  final alphabet = language == 'bn'
      ? '০১২৩৪৫৬৭৮৯'
      : language == 'ar'
      ? '٠١٢٣٤٥٦٧٨٩'
      : '0123456789';
  return input.replaceAllMapped(
    RegExp('[0-9]'),
    (m) => alphabet[int.parse(m[0]!)],
  );
}

List<String> shopWeekdays(BuildContext context) =>
    switch (Localizations.localeOf(context).languageCode) {
      'bn' => const ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহ', 'শুক্র', 'শনি'],
      'ar' => const ['أحد', 'إثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت'],
      _ => const ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
    };

const _hijriMonths = {
  'en': [
    'Muharram',
    'Safar',
    'Rabi I',
    'Rabi II',
    'Jumada I',
    'Jumada II',
    'Rajab',
    'Shaʻban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qiʻdah',
    'Dhu al-Hijjah',
  ],
  'bn': [
    'মুহাররম',
    'সফর',
    'রবিউল আউয়াল',
    'রবিউস সানি',
    'জমাদিউল আউয়াল',
    'জমাদিউস সানি',
    'রজব',
    'শাবান',
    'রমজান',
    'শাওয়াল',
    'জিলকদ',
    'জিলহজ',
  ],
  'ar': [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ],
};
