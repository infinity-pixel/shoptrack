import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_search_result.dart';
import 'package:shoptrack/models/shopping_session.dart';
import 'package:shoptrack/services/search_service.dart';
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
  group('Sprint 13: Search & Smart Item Discovery', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final past = today.subtract(const Duration(days: 5));
    final future = today.add(const Duration(days: 5));

    final sessions = [
      ShoppingSession(
        id: '1',
        date: today,
        items: [
          const ShoppingItem(id: 'i1', name: 'Milk', isPurchased: true),
          const ShoppingItem(id: 'i2', name: 'Eggs', isPurchased: false),
        ],
      ),
      ShoppingSession(
        id: '2',
        date: past,
        items: [
          const ShoppingItem(id: 'i3', name: 'Bread', isPurchased: true),
          const ShoppingItem(id: 'i4', name: 'Milk', isPurchased: false),
        ],
      ),
      ShoppingSession(
        id: '3',
        date: future,
        items: [
          const ShoppingItem(id: 'i5', name: 'Apples', isPurchased: false),
        ],
      ),
    ];

    late SearchService searchService;

    setUp(() {
      searchService = SearchService(MockShoppingRepository(sessions));
    });

    test('Search find items by name case-insensitively', () async {
      final results = await searchService.searchItems(query: 'milk');
      expect(results.length, 2);
      expect(results.any((r) => r.item.id == 'i1'), isTrue);
      expect(results.any((r) => r.item.id == 'i4'), isTrue);
    });

    test('Search partial matching works', () async {
      final results = await searchService.searchItems(query: 'app');
      expect(results.length, 1);
      expect(results[0].item.name, 'Apples');
    });

    test('Search results have correct status: Purchased', () async {
      final results = await searchService.searchItems(query: 'Milk');
      final purchasedMilk = results.firstWhere((r) => r.item.id == 'i1');
      expect(purchasedMilk.status, SearchItemStatus.purchased);
      expect(purchasedMilk.statusLabel, 'Purchased');
    });

    test('Search results have correct status: Pending (Today)', () async {
      final results = await searchService.searchItems(query: 'Eggs');
      expect(results[0].status, SearchItemStatus.pending);
      expect(results[0].statusLabel, 'Pending');
    });

    test('Search results have correct status: Pending (Past)', () async {
      final results = await searchService.searchItems(query: 'Milk');
      final pastMilk = results.firstWhere((r) => r.item.id == 'i4');
      expect(pastMilk.status, SearchItemStatus.pending);
    });

    test('Search results have correct status: Planned (Future)', () async {
      final results = await searchService.searchItems(query: 'Apples');
      expect(results[0].status, SearchItemStatus.planned);
      expect(results[0].statusLabel, 'Planned');
    });

    test('Empty search query returns empty results', () async {
      final results = await searchService.searchItems(query: '   ');
      expect(results, isEmpty);
    });

    test('Search results are sorted by date newest first', () async {
      final results = await searchService.searchItems(query: 'Milk');
      // Today is after Past
      expect(results[0].session.date, today);
      expect(results[1].session.date, past);
    });
  });
}
