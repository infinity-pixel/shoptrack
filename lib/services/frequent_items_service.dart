import '../core/data/shopping_repository.dart';
import '../models/frequent_item_suggestion.dart';
import '../models/shopping_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FrequentItemsService {
  static const String _dismissedSuggestionsKey =
      'dismissed_frequent_item_suggestions';
  final ShoppingRepository _repository;

  FrequentItemsService(this._repository);

  /// Ranks item names by how often they appear, newest details first.
  ///
  /// [excludeNames] skips names already on the current list (case-insensitive).
  Future<List<FrequentItemSuggestion>> getSuggestions({
    Iterable<String> excludeNames = const [],
    int limit = 8,
  }) async {
    final sessions = await _repository.getAllSessions(includeEmpty: true);
    final dismissed = await _loadDismissedNames();
    final excluded = excludeNames
        .map((name) => name.trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet();

    final grouped = <String, _NameStats>{};

    for (final session in sessions) {
      for (final item in session.items) {
        final key = item.name.trim().toLowerCase();
        if (key.isEmpty || excluded.contains(key) || dismissed.contains(key)) {
          continue;
        }

        final existing = grouped[key];
        if (existing == null) {
          grouped[key] = _NameStats(
            count: 1,
            lastSeen: session.date,
            latestItem: item,
          );
        } else {
          existing.count += 1;
          if (!session.date.isBefore(existing.lastSeen)) {
            existing.lastSeen = session.date;
            existing.latestItem = item;
          }
        }
      }
    }

    final suggestions = grouped.entries.map((entry) {
      return FrequentItemSuggestion(
        name: entry.value.latestItem.name,
        occurrenceCount: entry.value.count,
        lastSeen: entry.value.lastSeen,
        latestItem: entry.value.latestItem,
      );
    }).toList();

    suggestions.sort((a, b) {
      final byCount = b.occurrenceCount.compareTo(a.occurrenceCount);
      if (byCount != 0) return byCount;
      return b.lastSeen.compareTo(a.lastSeen);
    });

    if (suggestions.length <= limit) return suggestions;
    return suggestions.sublist(0, limit);
  }

  Future<void> dismissSuggestion(String name) async {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final dismissed = await _loadDismissedNames();
    dismissed.add(normalized);
    await prefs.setStringList(_dismissedSuggestionsKey, dismissed.toList());
  }

  Future<Set<String>> _loadDismissedNames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_dismissedSuggestionsKey) ?? const <String>[])
          .map((name) => name.trim().toLowerCase())
          .where((name) => name.isNotEmpty)
          .toSet();
    } catch (_) {
      // Pure unit-test or non-platform contexts may not initialize plugins.
      // Suggestions still work there; persistence is available in the app.
      return <String>{};
    }
  }
}

class _NameStats {
  int count;
  DateTime lastSeen;
  ShoppingItem latestItem;

  _NameStats({
    required this.count,
    required this.lastSeen,
    required this.latestItem,
  });
}
