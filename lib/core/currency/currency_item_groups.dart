import '../../models/shopping_item.dart';

/// Keeps the shopper's order inside each currency while placing the preferred
/// currency first. Each returned list is an independent reorder boundary.
Map<String, List<ShoppingItem>> groupItemsByCurrency(
  Iterable<ShoppingItem> items, {
  String? preferredCurrencyCode,
}) {
  final groups = <String, List<ShoppingItem>>{};
  for (final item in items) {
    groups.putIfAbsent(item.currencyCode, () => []).add(item);
  }
  final preferred = preferredCurrencyCode;
  if (preferred == null || !groups.containsKey(preferred)) return groups;
  return {preferred: groups.remove(preferred)!, ...groups};
}
