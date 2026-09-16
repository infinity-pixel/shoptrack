import '../../models/shopping_item.dart';
import '../../models/shopping_session.dart';

/// Same-date changes preserve item identity and use one repository save.
class ShoppingSessionActions {
  static List<ShoppingItem> _selection(
    ShoppingSession session,
    String sourceListId,
    Set<String> ids,
  ) {
    final selected = session
        .itemsForList(sourceListId)
        .where((item) => ids.contains(item.id))
        .toList();
    if (ids.isEmpty || selected.length != ids.length) {
      throw StateError('The selected items changed. Please select them again.');
    }
    selected.sort((a, b) {
      final position = a.position.compareTo(b.position);
      return position != 0 ? position : a.id.compareTo(b.id);
    });
    return selected;
  }

  static ShoppingSession move(
    ShoppingSession session, {
    required String sourceListId,
    required String destinationListId,
    required Set<String> ids,
  }) {
    if (sourceListId == destinationListId ||
        !session.orderedLists.any((list) => list.id == destinationListId)) {
      throw StateError('Choose another existing list.');
    }
    final selected = _selection(session, sourceListId, ids);
    var next =
        session
            .itemsForList(destinationListId)
            .fold<int>(
              -1,
              (max, item) => item.position > max ? item.position : max,
            ) +
        1;
    final moved = {
      for (final item in selected)
        item.id: item.copyWith(listId: destinationListId, position: next++),
    };
    return session.copyWith(
      items: [for (final item in session.items) moved[item.id] ?? item],
    );
  }

  static ShoppingSession delete(
    ShoppingSession session, {
    required String sourceListId,
    required Set<String> ids,
  }) {
    _selection(session, sourceListId, ids);
    return session.copyWith(
      items: [
        for (final item in session.items)
          if (!ids.contains(item.id)) item,
      ],
    );
  }
}
