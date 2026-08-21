import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/utils/session_grouper.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';
import 'package:shoptrack/models/monthly_summary.dart';

void main() {
  group('MonthlySummary Aggregation', () {
    test('Calculates totals correctly across multiple sessions', () {
      final item1 = ShoppingItem(
        id: '1',
        name: 'Item 1',
        priceValue: 100,
        quantityValue: 1,
        isPurchased: true,
      );
      final item2 = ShoppingItem(
        id: '2',
        name: 'Item 2',
        priceValue: 50,
        quantityValue: 2,
        isPurchased: false,
      );
      final item3 = ShoppingItem(
        id: '3',
        name: 'Item 3',
        priceValue: 200,
        quantityValue: 1,
        isPurchased: true,
      );

      final session1 = ShoppingSession(
        id: 's1',
        date: DateTime(2026, 7, 10),
        items: [item1, item2],
      );
      final session2 = ShoppingSession(
        id: 's2',
        date: DateTime(2026, 7, 20),
        items: [item3],
      );

      final summary = MonthlySummary(
        month: 7,
        year: 2026,
        sessions: [session1, session2],
      );

      expect(summary.totalItems, 3);
      expect(summary.purchasedCount, 2);
      expect(summary.pendingCount, 1);
      expect(summary.totalPurchasedAmount, 300.0); // 100 + 200
      expect(summary.monthName, 'July');
    });

    test('Status text handles singular/plural correctly', () {
      final summary = MonthlySummary(
        month: 7,
        year: 2026,
        sessions: [
          ShoppingSession(
            id: 's1',
            date: DateTime(2026, 7, 10),
            items: [
              ShoppingItem(id: '1', name: 'A', isPurchased: true),
              ShoppingItem(id: '2', name: 'B', isPurchased: false),
            ],
          ),
        ],
      );

      expect(summary.purchasedStatusText, '1 Item Purchased');
      expect(summary.pendingStatusText, '1 Item Pending');

      final summary2 = MonthlySummary(
        month: 7,
        year: 2026,
        sessions: [
          ShoppingSession(
            id: 's1',
            date: DateTime(2026, 7, 10),
            items: [
              ShoppingItem(id: '1', name: 'A', isPurchased: true),
              ShoppingItem(id: '2', name: 'B', isPurchased: true),
            ],
          ),
        ],
      );
      expect(summary2.purchasedStatusText, '2 Items Purchased');
    });
  });

  group('SessionGrouper Logic', () {
    final now = DateTime(2026, 8, 20);

    test('Groups sessions into completed months only', () {
      final sessions = [
        ShoppingSession(id: 'aug', date: DateTime(2026, 8, 10), items: [ShoppingItem(id: '1', name: 'A')]),
        ShoppingSession(id: 'july1', date: DateTime(2026, 7, 31), items: [ShoppingItem(id: '2', name: 'B')]),
        ShoppingSession(id: 'july2', date: DateTime(2026, 7, 10), items: [ShoppingItem(id: '3', name: 'C')]),
        ShoppingSession(id: 'june', date: DateTime(2026, 6, 15), items: [ShoppingItem(id: '4', name: 'D')]),
        ShoppingSession(id: 'future', date: DateTime(2026, 9, 1), items: [ShoppingItem(id: '5', name: 'E')]),
      ];

      final summaries = SessionGrouper.groupIntoMonths(sessions, now);

      expect(summaries.length, 2); // July and June
      expect(summaries[0].displayTitle, 'July 2026');
      expect(summaries[0].sessions.length, 2);
      expect(summaries[1].displayTitle, 'June 2026');
      expect(summaries[1].sessions.length, 1);
    });

    test('Sorts months latest first', () {
      final sessions = [
        ShoppingSession(id: 'jan2026', date: DateTime(2026, 1, 1), items: [ShoppingItem(id: '1', name: 'A')]),
        ShoppingSession(id: 'dec2025', date: DateTime(2025, 12, 31), items: [ShoppingItem(id: '2', name: 'B')]),
      ];

      final summaries = SessionGrouper.groupIntoMonths(sessions, DateTime(2026, 2, 1));

      expect(summaries[0].displayTitle, 'January 2026');
      expect(summaries[1].displayTitle, 'December 2025');
    });

    test('Excludes empty months', () {
      final sessions = [
        ShoppingSession(id: 'empty', date: DateTime(2026, 7, 1), items: []),
      ];

      final summaries = SessionGrouper.groupIntoMonths(sessions, now);
      expect(summaries.isEmpty, true);
    });
  });
}
