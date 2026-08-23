import 'shopping_item.dart';
import 'shopping_session.dart';

enum SearchItemStatus {
  purchased,
  pending,
  planned,
}

class ShoppingSearchResult {
  final ShoppingItem item;
  final ShoppingSession session;

  const ShoppingSearchResult({
    required this.item,
    required this.session,
  });

  SearchItemStatus get status {
    if (item.isPurchased) {
      return SearchItemStatus.purchased;
    } else if (session.isFuture) {
      return SearchItemStatus.planned;
    } else {
      return SearchItemStatus.pending;
    }
  }

  String get statusLabel {
    switch (status) {
      case SearchItemStatus.purchased:
        return 'Purchased';
      case SearchItemStatus.pending:
        return 'Pending';
      case SearchItemStatus.planned:
        return 'Planned';
    }
  }
}
