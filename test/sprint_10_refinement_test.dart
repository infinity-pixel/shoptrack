import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/utils/session_grouper.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';

void main() {
  group('Sprint 10 Refinement: Monthly Date Creation & Sorting', () {
    final now = DateTime(2026, 8, 20);

    test('Sessions inside a month are sorted newest-first', () {
      final sessions = [
        ShoppingSession(id: 'july1', date: DateTime(2026, 7, 1), items: [const ShoppingItem(id: '1', name: 'A')]),
        ShoppingSession(id: 'july31', date: DateTime(2026, 7, 31), items: [const ShoppingItem(id: '2', name: 'B')]),
        ShoppingSession(id: 'july15', date: DateTime(2026, 7, 15), items: [const ShoppingItem(id: '3', name: 'C')]),
      ];

      final summaries = SessionGrouper.groupIntoMonths(sessions, now);
      
      expect(summaries.length, 1);
      final july = summaries[0];
      expect(july.sessions.length, 3);
      expect(july.sessions[0].date.day, 31);
      expect(july.sessions[1].date.day, 15);
      expect(july.sessions[2].date.day, 1);
    });

    test('Monthly history only includes completed months', () {
      final sessions = [
        ShoppingSession(id: 'aug', date: DateTime(2026, 8, 10), items: [const ShoppingItem(id: '1', name: 'A')]),
        ShoppingSession(id: 'july', date: DateTime(2026, 7, 10), items: [const ShoppingItem(id: '2', name: 'B')]),
        ShoppingSession(id: 'future', date: DateTime(2026, 9, 1), items: [const ShoppingItem(id: '3', name: 'C')]),
      ];

      final summaries = SessionGrouper.groupIntoMonths(sessions, now);
      
      expect(summaries.length, 1);
      expect(summaries[0].month, 7);
      expect(summaries[0].year, 2026);
    });

    test('Monthly aggregation handles cross-year correctly', () {
      final sessions = [
        ShoppingSession(id: 'dec2025', date: DateTime(2025, 12, 10), items: [const ShoppingItem(id: '1', name: 'A')]),
        ShoppingSession(id: 'jan2026', date: DateTime(2026, 1, 10), items: [const ShoppingItem(id: '2', name: 'B')]),
      ];

      final summaries = SessionGrouper.groupIntoMonths(sessions, now);
      
      expect(summaries.length, 2);
      expect(summaries[0].displayTitle, 'January 2026');
      expect(summaries[1].displayTitle, 'December 2025');
    });

    test('Empty months are not displayed in history', () {
      final sessions = [
        ShoppingSession(id: 'empty', date: DateTime(2026, 7, 10), items: []),
      ];

      final summaries = SessionGrouper.groupIntoMonths(sessions, now);
      expect(summaries.isEmpty, true);
    });
  });
}
