import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/utils/date_parser.dart';

void main() {
  group('Sprint 13.3: DateParser Tests', () {
    test('Parses standard d/m/yyyy format', () {
      final date = DateParser.parse('2/8/2026');
      expect(date, isNotNull);
      expect(date!.day, 2);
      expect(date.month, 8);
      expect(date.year, 2026);
    });

    test('Parses dd/mm/yyyy format', () {
      final date = DateParser.parse('02/08/2026');
      expect(date, isNotNull);
      expect(date!.day, 2);
      expect(date.month, 8);
    });

    test('Parses with different separators: - and .', () {
      final date1 = DateParser.parse('2-8-2026');
      expect(date1, isNotNull);
      expect(date1!.day, 2);

      final date2 = DateParser.parse('2.8.2026');
      expect(date2, isNotNull);
      expect(date2!.day, 2);
    });

    test('Parses 8-digit string ddmmyyyy', () {
      final date = DateParser.parse('02082026');
      expect(date, isNotNull);
      expect(date!.day, 2);
      expect(date.month, 8);
      expect(date.year, 2026);
    });

    test('Handles single digit month and day with separators', () {
      final date = DateParser.parse('1/1/2026');
      expect(date, isNotNull);
      expect(date!.day, 1);
      expect(date.month, 1);
    });

    test('Rejects invalid dates (e.g. Feb 30)', () {
      final date = DateParser.parse('30/2/2026');
      expect(date, isNull);
    });

    test('Correctly handles leap years', () {
      final validLeap = DateParser.parse('29/2/2024');
      expect(validLeap, isNotNull);

      final invalidLeap = DateParser.parse('29/2/2023');
      expect(invalidLeap, isNull);
    });

    test('Rejects malformed strings', () {
      expect(DateParser.parse('abcd'), isNull);
      expect(DateParser.parse('1/1'), isNull);
      expect(DateParser.parse('1/1/202/6'), isNull);
    });
  });
}
