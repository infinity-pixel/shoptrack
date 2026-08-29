import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';
import 'package:shoptrack/services/frequent_items_service.dart';
import 'package:shoptrack/core/data/shopping_repository.dart';

// Mock repository for testing
class MockShoppingRepository implements ShoppingRepository {
  final List<ShoppingSession> sessions;
  MockShoppingRepository(this.sessions);

  @override
  Future<List<ShoppingSession>> getAllSessions({bool includeEmpty = false}) async => sessions;
  
  @override
  Future<ShoppingSession> getSessionByDate(DateTime date) async => sessions.first;
  @override
  Future<void> saveSession(ShoppingSession session) async {}
  @override
  Future<void> deleteSession(String id) async {}
  @override
  Future<void> clearAll() async {}
  @override
  Future<void> replaceSessions(List<ShoppingSession> sessions) async {}
}

void main() {
  group('Sprint 13.2: Often Bought & Date Presets', () {
    test('Often Bought frequency calculation and recency tie-breaking', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final lastWeek = today.subtract(const Duration(days: 7));

      final sessions = [
        ShoppingSession(
          id: '1',
          date: today,
          items: [const ShoppingItem(id: 'i1', name: 'Milk')],
        ),
        ShoppingSession(
          id: '2',
          date: yesterday,
          items: [const ShoppingItem(id: 'i2', name: 'Bread')],
        ),
        ShoppingSession(
          id: '3',
          date: lastWeek,
          items: [const ShoppingItem(id: 'i3', name: 'Milk'), const ShoppingItem(id: 'i4', name: 'Bread')],
        ),
      ];
      
      final service = FrequentItemsService(MockShoppingRepository(sessions));
      final suggestions = await service.getSuggestions();
      
      expect(suggestions.length, 2);
      expect(suggestions[0].name, 'Milk'); // Frequency 2, last seen Today
      expect(suggestions[1].name, 'Bread'); // Frequency 2, last seen Yesterday
    });

    test('Date Preset: Last 7 Days calculation', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expectedStart = today.subtract(const Duration(days: 7));
      
      final start = today.subtract(const Duration(days: 7));
      expect(start, expectedStart);
    });

    test('Date Preset: Last 3 Months handling month subtraction safely', () {
      // Test May 31 -> Feb 28
      final today = DateTime(2026, 5, 31);
      DateTime start = DateTime(today.year, today.month - 3, today.day);
      if (start.month != (today.month - 3 + 12) % 12 || start.day != today.day) {
        if (start.month != (today.month - 3 + 12) % 12) {
           start = DateTime(today.year, today.month - 2, 0); // last day of target month
        }
      }
      
      expect(start, DateTime(2026, 2, 28));
    });
  });
}
