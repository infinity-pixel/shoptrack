import 'package:intl/intl.dart';

import '../core/currency/currency_totals.dart';
import 'shopping_session.dart';

class MonthlySummary {
  final int month;
  final int year;
  final List<ShoppingSession> sessions;

  const MonthlySummary({
    required this.month,
    required this.year,
    required this.sessions,
  });

  String get monthName => DateFormat('MMMM').format(DateTime(year, month));
  String get displayTitle => '$monthName $year';

  int get purchasedCount =>
      sessions.fold(0, (sum, s) => sum + s.purchasedCount);
  int get pendingCount => sessions.fold(0, (sum, s) => sum + s.pendingCount);
  int get totalItems => sessions.fold(0, (sum, s) => sum + s.plannedCount);

  CurrencyTotals get purchasedTotalsByCurrency => CurrencyTotals.fromItems(
    sessions.expand((session) => session.items),
    where: (item) => item.isPurchased,
  );

  double get totalPurchasedAmount =>
      purchasedTotalsByCurrency.singleValueOrZero;

  bool get isEmpty =>
      sessions.isEmpty || sessions.every((s) => s.items.isEmpty);

  String get purchasedStatusText => purchasedCount == 1
      ? '1 Item Purchased'
      : '$purchasedCount Items Purchased';

  String get pendingStatusText =>
      pendingCount == 1 ? '1 Item Pending' : '$pendingCount Items Pending';
}
