import 'package:uuid/uuid.dart';

import 'shopping_item.dart';

/// A name that shows up often in past lists, plus the latest details to reuse.
class FrequentItemSuggestion {
  final String name;
  final int occurrenceCount;
  final DateTime lastSeen;
  final ShoppingItem latestItem;

  const FrequentItemSuggestion({
    required this.name,
    required this.occurrenceCount,
    required this.lastSeen,
    required this.latestItem,
  });

  /// New list row with a fresh id, copied qty/price/unit, not purchased.
  ShoppingItem toNewItem({required int position}) {
    return latestItem.copyWith(
      id: const Uuid().v4(),
      isPurchased: false,
      position: position,
    );
  }
}
