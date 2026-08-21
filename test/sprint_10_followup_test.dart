import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';

void main() {
  group('Sprint 10 Follow-Up: Date Editing & Collision Safety', () {
    test('Editing a session date preserves all session data', () {
      final item = const ShoppingItem(
        id: 'item-1',
        name: 'Milk',
        priceValue: 100,
        isPurchased: true,
      );
      final session = ShoppingSession(
        id: 'session-1',
        date: DateTime(2026, 8, 10),
        items: [item],
      );

      final newDate = DateTime(2026, 8, 15);
      final updatedSession = session.copyWith(date: newDate);

      expect(updatedSession.id, session.id);
      expect(updatedSession.date, newDate);
      expect(updatedSession.items.length, 1);
      expect(updatedSession.items[0].name, 'Milk');
      expect(updatedSession.items[0].isPurchased, true);
    });

    test('ShoppingSession.copyWith correctly updates date', () {
      final session = ShoppingSession(
        id: 's-1',
        date: DateTime(2026, 7, 1),
        items: [],
      );
      
      final updated = session.copyWith(date: DateTime(2026, 7, 2));
      expect(updated.date, DateTime(2026, 7, 2));
      expect(updated.id, 's-1');
    });
  });
}
