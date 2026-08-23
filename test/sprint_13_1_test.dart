import 'package:flutter/material.dart';
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
  group('Sprint 13.1: Search Filters & Price History', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final past = today.subtract(const Duration(days: 5));
    final future = today.add(const Duration(days: 5));

    final sessions = [
      ShoppingSession(
        id: '1',
        date: today,
        items: [
          const ShoppingItem(id: 'i1', name: 'Milk', isPurchased: true, priceValue: 100, pricingMode: PricingMode.total),
          const ShoppingItem(id: 'i2', name: 'Rice', isPurchased: false, priceValue: 70, quantityValue: 1, shoppingUnit: ShoppingUnit.kg, pricingMode: PricingMode.unit, priceBasis: ShoppingUnit.kg),
        ],
      ),
      ShoppingSession(
        id: '2',
        date: past,
        items: [
          const ShoppingItem(id: 'i3', name: 'Rice', isPurchased: true, priceValue: 65, quantityValue: 1, shoppingUnit: ShoppingUnit.kg, pricingMode: PricingMode.unit, priceBasis: ShoppingUnit.kg),
          const ShoppingItem(id: 'i4', name: 'Milk', isPurchased: false, priceValue: 95, pricingMode: PricingMode.total),
        ],
      ),
      ShoppingSession(
        id: '3',
        date: future,
        items: [
          const ShoppingItem(id: 'i5', name: 'Apples', isPurchased: false, priceValue: 200, pricingMode: PricingMode.total),
        ],
      ),
    ];

    late SearchService searchService;

    setUp(() {
      searchService = SearchService(MockShoppingRepository(sessions));
    });

    test('Search filters by Status: Purchased', () async {
      final results = await searchService.searchItems(query: '', statusFilter: SearchItemStatus.purchased);
      expect(results.length, 2);
      expect(results.every((r) => r.status == SearchItemStatus.purchased), isTrue);
    });

    test('Search filters by Status: Pending', () async {
      final results = await searchService.searchItems(query: '', statusFilter: SearchItemStatus.pending);
      expect(results.length, 2); // Rice (Today, pending) and Milk (Past, pending)
      expect(results.every((r) => r.status == SearchItemStatus.pending), isTrue);
    });

    test('Search filters by Status: Planned', () async {
      final results = await searchService.searchItems(query: '', statusFilter: SearchItemStatus.planned);
      expect(results.length, 1);
      expect(results[0].item.name, 'Apples');
      expect(results[0].status, SearchItemStatus.planned);
    });

    test('Search filters by Date Range (inclusive)', () async {
      final range = DateTimeRange(start: past, end: today);
      final results = await searchService.searchItems(query: '', dateRange: range);
      expect(results.length, 4); // sessions 1 and 2
      expect(results.any((r) => r.session.id == '3'), isFalse);
    });

    test('Combined filters: Search + Status + Date Range', () async {
      final range = DateTimeRange(start: past, end: past);
      final results = await searchService.searchItems(
        query: 'Rice',
        statusFilter: SearchItemStatus.purchased,
        dateRange: range,
      );
      expect(results.length, 1);
      expect(results[0].item.id, 'i3');
    });

    test('Results remain newest-first', () async {
      final results = await searchService.searchItems(query: 'Rice');
      expect(results[0].session.date, today);
      expect(results[1].session.date, past);
    });
  });
}
