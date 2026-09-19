import 'dart:convert';
import '../../models/shopping_list_group.dart';

typedef Json = Map<String, dynamic>;

Json copyJson(Json value) => jsonDecode(jsonEncode(value)) as Json;

bool sameJson(dynamic a, dynamic b) {
  if (a is Map && b is Map) {
    return a.length == b.length &&
        a.keys.every((key) => b.containsKey(key) && sameJson(a[key], b[key]));
  }
  if (a is List && b is List) {
    return a.length == b.length &&
        List.generate(a.length, (i) => i).every((i) => sameJson(a[i], b[i]));
  }
  return a == b;
}

/// Three-way merge: change only what this editor changed from its baseline.
/// Pricing fields are one unit so independently edited quantities/prices cannot
/// produce a calculation that neither editor intended.
class SessionMerge {
  SessionMerge(Json? base, Json? local, Json? remote) {
    value = _session(base, local, remote);
  }

  late final Json? value;
  final List<String> conflicts = [];

  dynamic _field(dynamic base, dynamic local, dynamic remote, String path) {
    if (sameJson(local, base)) return remote;
    if (sameJson(remote, base) || sameJson(local, remote)) return local;
    conflicts.add(path);
    // Used for local preview only. Cloud commits reject the entire change if
    // conflicts exist and preserve both versions for explicit review.
    return local;
  }

  Json? _session(Json? base, Json? local, Json? remote) {
    if (sameJson(base, local)) return remote == null ? null : copyJson(remote);
    if (sameJson(base, remote) || sameJson(local, remote)) {
      return local == null ? null : copyJson(local);
    }
    if (local == null || remote == null) {
      return _field(base, local, remote, 'Date removed or edited') as Json?;
    }
    final result = <String, dynamic>{
      'id': remote['id'],
      'date': remote['date'],
      'items': _entities(base?['items'], local['items'], remote['items'], true),
      'lists': _entities(
        base?['lists'],
        local['lists'],
        remote['lists'],
        false,
      ),
    };
    final lists = result['lists'] as List<Json>;
    for (final item in result['items'] as List<Json>) {
      final listId = item['listId'] ?? ShoppingListGroup.defaultId;
      if (lists.any((list) => list['id'] == listId)) continue;
      // A concurrent list deletion must not make another device's item
      // invisible. Restore its list in the preview and require review.
      conflicts.add('${item['name']}: its list was removed');
      final originals = <dynamic>[
        ...?local['lists'] as List?,
        ...?remote['lists'] as List?,
        ...?base?['lists'] as List?,
        ShoppingListGroup.defaultList.toJson(),
      ];
      final original = originals.where((list) => list['id'] == listId);
      if (original.isNotEmpty) lists.add(copyJson(original.first as Json));
    }
    return result;
  }

  List<Json> _entities(
    dynamic base,
    dynamic local,
    dynamic remote,
    bool items,
  ) {
    Map<String, Json> keyed(dynamic list) => {
      for (final entry in (list as List? ?? []))
        entry['id'] as String: Map<String, dynamic>.from(entry as Map),
    };
    final b = keyed(base), l = keyed(local), r = keyed(remote);
    final result = <Json>[];
    for (final id in {...r.keys, ...l.keys, ...b.keys}) {
      final old = b[id], mine = l[id], theirs = r[id];
      final label = (mine ?? theirs ?? old)!['name'] ?? id;
      if (mine == null || theirs == null) {
        final value = _field(old, mine, theirs, '$label: removed or edited');
        if (value != null) result.add(copyJson(value as Json));
        continue;
      }
      const pricing = {
        'quantity',
        'unit',
        'price',
        'quantityValue',
        'priceValue',
        'currencyCode',
        'pricingMode',
        'shoppingUnit',
        'priceBasis',
      };
      const placement = {'listId', 'position'};
      Json group(Json? data, Set<String> fields) => {
        for (final key in fields) key: data?[key],
      };
      final merged = <String, dynamic>{'id': id};
      for (final key in {...mine.keys, ...theirs.keys}) {
        if (key == 'id' ||
            (items && (pricing.contains(key) || placement.contains(key)))) {
          continue;
        }
        merged[key] = _field(old?[key], mine[key], theirs[key], '$label: $key');
      }
      if (items) {
        merged.addAll(
          Map<String, dynamic>.from(
            _field(
                  group(old, pricing),
                  group(mine, pricing),
                  group(theirs, pricing),
                  '$label: quantity / price',
                )
                as Map,
          ),
        );
        // List membership and its order belong together. A source-list reorder
        // must never silently supply the position for a concurrent move.
        merged.addAll(
          Map<String, dynamic>.from(
            _field(
                  group(old, placement),
                  group(mine, placement),
                  group(theirs, placement),
                  '$label: list / position',
                )
                as Map,
          ),
        );
      }
      result.add(merged);
    }
    result.sort((a, b) {
      final byPosition = (a['position'] as int? ?? 0).compareTo(
        b['position'] as int? ?? 0,
      );
      return byPosition != 0
          ? byPosition
          : (a['id'] as String).compareTo(b['id'] as String);
    });
    return result;
  }
}
