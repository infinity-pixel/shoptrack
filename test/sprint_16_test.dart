import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoptrack/core/data/shopping_repository.dart';
import 'package:shoptrack/core/animation/rolling_digit.dart';
import 'package:shoptrack/core/theme/theme_presets.dart';
import 'package:shoptrack/core/utils/number_formatter.dart';
import 'package:shoptrack/core/widgets/scroll_aware_fab.dart';
import 'package:shoptrack/features/history/presentation/widgets/session_card.dart';
import 'package:shoptrack/features/home/presentation/pages/home_page.dart';
import 'package:shoptrack/models/shopping_item.dart';
import 'package:shoptrack/models/shopping_list_group.dart';
import 'package:shoptrack/models/shopping_session.dart';
import 'package:shoptrack/services/frequent_items_service.dart';

void main() {
  group('Sprint 16 quantities', () {
    test('preserves entered quantity text', () {
      expect(NumberFormatter.formatQuantity(11.8, enteredText: '11.8'), '11.8');
      expect(NumberFormatter.formatQuantity(4.3, enteredText: '4.3'), '4.3');
    });

    test('does not expose floating-point tails', () {
      expect(NumberFormatter.format(11.800000000000001), '11.8');
    });
  });

  group('Sprint 16 named shopping lists', () {
    const home = ShoppingListGroup(id: 'home', name: 'Our Home', position: 0);
    const grandmother = ShoppingListGroup(
      id: 'grandmother',
      name: 'Grandmother',
      position: 1,
    );

    test('keeps items and totals separated inside one date', () {
      final session = ShoppingSession(
        id: 'session',
        date: DateTime(2026, 9, 3),
        lists: const [home, grandmother],
        items: const [
          ShoppingItem(
            id: 'rice',
            name: 'Rice',
            listId: 'home',
            quantity: '4.3',
            quantityValue: 4.3,
            priceValue: 100,
            pricingMode: PricingMode.unit,
            shoppingUnit: ShoppingUnit.kg,
            priceBasis: ShoppingUnit.kg,
          ),
          ShoppingItem(
            id: 'oil',
            name: 'Oil',
            listId: 'grandmother',
            priceValue: 300,
            isPurchased: true,
          ),
        ],
      );

      expect(session.itemsForList('home').single.name, 'Rice');
      expect(session.itemsForList('grandmother').single.name, 'Oil');
      expect(session.totalPurchasedAmount, 300);
      expect(session.totalAmount, 730);
    });

    test('loads old sessions into My List without changing their items', () {
      final session = ShoppingSession.fromJson({
        'id': 'old-session',
        'date': '2026-09-03T00:00:00.000',
        'items': [
          {'id': 'old-item', 'name': 'Eggs', 'isPurchased': false},
        ],
      });

      expect(session.orderedLists.single.id, ShoppingListGroup.defaultId);
      expect(
        session.itemsForList(ShoppingListGroup.defaultId).single.name,
        'Eggs',
      );
    });

    test('serializes list identity and exact quantity text', () {
      const item = ShoppingItem(
        id: 'item',
        name: 'Potatoes',
        quantity: '11.8',
        quantityValue: 11.8,
        listId: 'grandmother',
      );
      final decoded = ShoppingItem.fromJson(item.toJson());

      expect(decoded.quantity, '11.8');
      expect(decoded.quantityValue, 11.8);
      expect(decoded.listId, 'grandmother');
    });
  });

  test('removing Often Bought suggestion does not delete history', () async {
    SharedPreferences.setMockInitialValues({});
    final session = ShoppingSession(
      id: 'history',
      date: DateTime(2026, 9, 1),
      items: const [ShoppingItem(id: 'item', name: 'Tomatoes')],
    );
    final repository = _MemoryRepository([session]);
    final service = FrequentItemsService(repository);

    expect((await service.getSuggestions()).single.name, 'Tomatoes');
    await service.dismissSuggestion('Tomatoes');

    expect(await service.getSuggestions(), isEmpty);
    expect(
      (await repository.getAllSessions()).single.items.single.name,
      'Tomatoes',
    );
  });

  testWidgets('History card displays purchased amount, not pending amount', (
    tester,
  ) async {
    final session = ShoppingSession(
      id: 'history-card',
      date: DateTime(2026, 9, 3),
      items: const [
        ShoppingItem(
          id: 'purchased',
          name: 'Purchased',
          priceValue: 50,
          isPurchased: true,
        ),
        ShoppingItem(
          id: 'pending',
          name: 'Pending',
          priceValue: 100,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.lightPresets.values.first.toThemeData(),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(320, 700)),
          child: Scaffold(
            body: SessionCard(session: session, onTap: () {}),
          ),
        ),
      ),
    );
    await tester.pump();

    final amount = tester.widget<RollingDigitText>(
      find.byType(RollingDigitText),
    );
    expect(amount.text, '৳50');
    expect(amount.text, isNot('৳150'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home switches between named lists without mixing their items', (
    tester,
  ) async {
    const grandmother = ShoppingListGroup(
      id: 'grandmother',
      name: 'Grandmother',
      position: 1,
    );
    final date = DateTime(2026, 9, 3);
    final session = ShoppingSession(
      id: 'named-lists-ui',
      date: date,
      lists: const [ShoppingListGroup.defaultList, grandmother],
      items: const [
        ShoppingItem(
          id: 'rice',
          name: 'Rice',
          listId: ShoppingListGroup.defaultId,
        ),
        ShoppingItem(
          id: 'oil',
          name: 'Oil',
          listId: 'grandmother',
        ),
      ],
    );
    SharedPreferences.setMockInitialValues({
      'shopping_sessions': jsonEncode([session.toJson()]),
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemePresets.lightPresets.values.first.toThemeData(),
        home: HomePage(sessionDate: date),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rice'), findsOneWidget);
    expect(find.text('Oil'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Grandmother  1'));
    await tester.pumpAndSettle();

    expect(find.text('Rice'), findsNothing);
    expect(find.text('Oil'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('FAB ignores programmatic scrolling and waits for user travel', (
    tester,
  ) async {
    late BuildContext notificationContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            notificationContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
    final controller = ScrollAwareFabController(
      travelThreshold: 20,
      settleDelay: const Duration(milliseconds: 50),
    );
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 500,
      pixels: 100,
      viewportDimension: 300,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );

    controller.handleNotification(
      ScrollStartNotification(
        metrics: metrics,
        context: notificationContext,
      ),
    );
    controller.handleNotification(
      ScrollUpdateNotification(
        metrics: metrics,
        context: notificationContext,
        scrollDelta: 40,
      ),
    );
    await tester.pump(const Duration(milliseconds: 70));
    expect(controller.isExpanded, isTrue);

    controller.handleNotification(
      ScrollStartNotification(
        metrics: metrics,
        context: notificationContext,
        dragDetails: DragStartDetails(),
      ),
    );
    controller.handleNotification(
      ScrollUpdateNotification(
        metrics: metrics,
        context: notificationContext,
        scrollDelta: 24,
        dragDetails: DragUpdateDetails(globalPosition: Offset.zero),
      ),
    );
    await tester.pump(const Duration(milliseconds: 70));
    expect(controller.isExpanded, isFalse);
    controller.dispose();
  });
}

class _MemoryRepository implements ShoppingRepository {
  _MemoryRepository(this.sessions);

  final List<ShoppingSession> sessions;

  @override
  Future<void> clearAll() async => sessions.clear();

  @override
  Future<void> deleteSession(String id) async {
    sessions.removeWhere((session) => session.id == id);
  }

  @override
  Future<List<ShoppingSession>> getAllSessions({
    bool includeEmpty = false,
  }) async {
    return sessions;
  }

  @override
  Future<ShoppingSession> getSessionByDate(DateTime date) async {
    return sessions.first;
  }

  @override
  Future<void> replaceSessions(List<ShoppingSession> replacement) async {
    sessions
      ..clear()
      ..addAll(replacement);
  }

  @override
  Future<void> saveSession(ShoppingSession session) async {}
}
