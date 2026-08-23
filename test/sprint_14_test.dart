import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/data/shopping_repository.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_session.dart';
import 'package:shoptrack/services/frequent_items_service.dart';

class MockShoppingRepository implements ShoppingRepository {
  final List<ShoppingSession> sessions;
  MockShoppingRepository(this.sessions);

  @override
  Future<List<ShoppingSession>> getAllSessions({bool includeEmpty = false}) async =>
      sessions;

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
  group('Sprint 14: Frequent item quick-add', () {
    final today = DateTime(2026, 8, 23);
    final lastWeek = DateTime(2026, 8, 16);
    final lastMonth = DateTime(2026, 7, 20);

    final sessions = [
      ShoppingSession(
        id: '1',
        date: today,
        items: [
          const ShoppingItem(id: 'i1', name: 'Milk', priceValue: 110),
          const ShoppingItem(id: 'i2', name: 'Eggs'),
        ],
      ),
      ShoppingSession(
        id: '2',
        date: lastWeek,
        items: [
          const ShoppingItem(id: 'i3', name: 'milk', priceValue: 100),
          const ShoppingItem(id: 'i4', name: 'Bread'),
        ],
      ),
      ShoppingSession(
        id: '3',
        date: lastMonth,
        items: [
          const ShoppingItem(id: 'i5', name: 'Bread'),
          const ShoppingItem(id: 'i6', name: 'Rice'),
        ],
      ),
    ];

    late FrequentItemsService service;

    setUp(() {
      service = FrequentItemsService(MockShoppingRepository(sessions));
    });

    test('ranks names by how often they appear', () async {
      final suggestions = await service.getSuggestions();
      expect(suggestions.map((s) => s.name.toLowerCase()).toList(),
          ['milk', 'bread', 'eggs', 'rice']);
      expect(suggestions.first.occurrenceCount, 2);
    });

    test('merges the same name with different casing', () async {
      final suggestions = await service.getSuggestions();
      final milk = suggestions.firstWhere((s) => s.name.toLowerCase() == 'milk');
      expect(milk.occurrenceCount, 2);
    });

    test('reuses the newest details for that name', () async {
      final suggestions = await service.getSuggestions();
      final milk = suggestions.firstWhere((s) => s.name.toLowerCase() == 'milk');
      expect(milk.latestItem.priceValue, 110);
      expect(milk.name, 'Milk');
    });

    test('skips names already on the current list', () async {
      final suggestions = await service.getSuggestions(excludeNames: ['Milk']);
      expect(suggestions.any((s) => s.name.toLowerCase() == 'milk'), isFalse);
      expect(suggestions.first.name, 'Bread');
    });

    test('respects the suggestion limit', () async {
      final suggestions = await service.getSuggestions(limit: 2);
      expect(suggestions.length, 2);
    });

    test('toNewItem copies details but uses a new id and pending status', () async {
      final suggestions = await service.getSuggestions();
      final milk = suggestions.first;
      final copy = milk.toNewItem(position: 3);

      expect(copy.id, isNot(milk.latestItem.id));
      expect(copy.name, milk.latestItem.name);
      expect(copy.priceValue, 110);
      expect(copy.isPurchased, isFalse);
      expect(copy.position, 3);
    });
  });
}
