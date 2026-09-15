import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/shopping_session.dart';
import 'session_merge.dart';

String sessionDay(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// One persisted envelope holds visible records AND pending changes, avoiding
/// separate writes for the record and its corresponding upload queue.
class SyncStore extends ChangeNotifier {
  SyncStore(this.preferences, this.scope);

  final SharedPreferences preferences;
  final String scope;
  String get storageKey => 'shoptrack_sync_v1_$scope';
  Json _data = {
    'version': 1,
    'sessions': <String, dynamic>{},
    'pending': [],
    'conflicts': [],
  };
  Future<void> _tail = Future.value();
  bool _disposed = false;
  bool _closedForEdits = false;
  int editGeneration = 0;
  Object? storageError;

  Future<void> closeForEdits() async {
    _closedForEdits = true;
    editGeneration++;
    await _tail;
  }

  void reopenForEdits() => _closedForEdits = false;

  void _checkEditable() {
    if (_closedForEdits) {
      throw StateError('This editor belongs to the previous account.');
    }
  }

  List<Json> get pending =>
      (_data['pending'] as List).map((op) => copyJson(op as Json)).toList();
  List<Json> get conflicts =>
      (_data['conflicts'] as List).map((op) => copyJson(op as Json)).toList();
  List<ShoppingSession> get sessions =>
      (_data['sessions'] as Map).values
          .map((value) => ShoppingSession.fromJson(copyJson(value as Json)))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  Future<void> load({List<ShoppingSession> seed = const []}) async {
    final raw = preferences.getString(storageKey);
    if (raw != null) {
      final decoded = jsonDecode(raw) as Json;
      if (decoded['version'] != 1 ||
          decoded['sessions'] is! Map ||
          decoded['pending'] is! List ||
          decoded['conflicts'] is! List) {
        throw const FormatException('Unrecognized shopping storage format');
      }
      // Validate before allowing any write over the existing envelope.
      for (final value in (decoded['sessions'] as Map).values) {
        ShoppingSession.fromJson(Map<String, dynamic>.from(value as Map));
      }
      _data = decoded;
      return;
    }
    await _edit((next) {
      for (final session in seed) {
        final day = sessionDay(session.date);
        final prior = (next['sessions'] as Map)[day] as Json?;
        final merged = SessionMerge(null, session.toJson(), prior);
        // Legacy duplicate dates can exist. Preserve the source on disk and
        // stop if two records disagree, rather than guessing during migration.
        if (merged.conflicts.isNotEmpty) {
          throw const FormatException('Conflicting legacy dates need review');
        }
        (next['sessions'] as Map)[day] = merged.value;
      }
    });
  }

  Future<T> _edit<T>(T Function(Json next) change) {
    final result = Completer<T>();
    _tail = _tail.then((_) async {
      var notify = storageError != null;
      try {
        final next = copyJson(_data);
        final value = change(next);
        if (!sameJson(next, _data)) {
          notify = true;
          if (!await preferences.setString(storageKey, jsonEncode(next))) {
            throw StateError('Shopping data could not be saved on this device');
          }
          _data = next;
        }
        storageError = null;
        result.complete(value);
      } catch (error, stack) {
        notify = true;
        storageError = error;
        result.completeError(error, stack);
      }
      if (!_disposed && notify) notifyListeners();
    });
    return result.future;
  }

  Future<void> enableCloud() => _edit((next) {
    if (next['cloudEnabled'] == true) return;
    next['cloudEnabled'] = true;
    for (final entry in (next['sessions'] as Map).entries) {
      _enqueue(next, entry.key as String, null, entry.value as Json);
    }
  });

  void _enqueue(Json next, String day, Json? base, Json? value) {
    if (next['cloudEnabled'] != true || sameJson(base, value)) return;
    (next['pending'] as List).add({
      'id': const Uuid().v4(),
      'day': day,
      'base': base,
      'value': value,
    });
  }

  Future<void> save(String day, Json? base, Json? value) {
    _checkEditable();
    return _edit((next) {
      final all = next['sessions'] as Map;
      final current = all[day] as Json?;
      final merge = SessionMerge(base, value, current);
      if (merge.conflicts.isNotEmpty) {
        (next['conflicts'] as List).add({
          'id': const Uuid().v4(),
          'day': day,
          'base': base,
          'value': value,
          'remote': current,
          'fields': merge.conflicts,
        });
        return;
      }
      if (merge.value == null) {
        all.remove(day);
      } else {
        all[day] = merge.value;
      }
      _enqueue(next, day, current, merge.value);
    });
  }

  Future<void> saveBatch(List<Json> edits) {
    _checkEditable();
    return _edit((next) {
      final queue = next['pending'] as List;
      final start = queue.length;
      for (final edit in edits) {
        final day = edit['day'] as String;
        final current = (next['sessions'] as Map)[day] as Json?;
        final merge = SessionMerge(
          edit['base'] as Json?,
          edit['value'] as Json?,
          current,
        );
        if (merge.conflicts.isNotEmpty) {
          throw StateError(
            'This record changed while it was being moved. Please retry.',
          );
        }
        (next['sessions'] as Map)[day] = merge.value;
        _enqueue(next, day, current, merge.value);
      }
      final batchId = const Uuid().v4();
      for (final op in queue.skip(start)) {
        op['batchId'] = batchId;
      }
    });
  }

  /// Explicit backup restore is a single local commit, with changes queued for
  /// the same signed-in account. Keep a recovery copy before replacement.
  Future<void> replace(List<ShoppingSession> sessions) {
    _checkEditable();
    return _edit((next) {
      final all = next['sessions'] as Map;
      final replacements = {
        for (final s in sessions) sessionDay(s.date): s.toJson(),
      };
      if (replacements.length != sessions.length) {
        throw const FormatException('Backup contains duplicate shopping dates');
      }
      next['beforeRestore'] = Map<String, dynamic>.from(all);
      for (final day in {...all.keys.cast<String>(), ...replacements.keys}) {
        _enqueue(next, day, all[day] as Json?, replacements[day]);
      }
      next['sessions'] = replacements;
    });
  }

  /// Reapply unsent edits over server state so receiving a snapshot cannot
  /// remove changes made offline or while a request is in flight.
  void _rebase(Json next, String day, Json? remote) {
    Json? visible = remote;
    for (final raw in next['pending'] as List) {
      final op = raw as Json;
      if (op['day'] == day) {
        visible = SessionMerge(
          op['base'] as Json?,
          op['value'] as Json?,
          visible,
        ).value;
      }
    }
    final all = next['sessions'] as Map;
    if (visible == null) {
      all.remove(day);
    } else {
      all[day] = visible;
    }
  }

  Json? _rememberRemote(Json next, String day, Json? remote, int revision) {
    final heads = (next['remoteHeads'] ??= <String, dynamic>{}) as Map;
    final previous = heads[day] as Map?;
    if (previous == null || revision >= (previous['revision'] as int)) {
      heads[day] = {'revision': revision, 'value': remote};
      return remote;
    }
    return previous['value'] as Json?;
  }

  Future<void> receive(
    Map<String, Json?> changes, {
    Map<String, int> revisions = const {},
  }) => _edit((next) {
    for (final entry in changes.entries) {
      final latest = _rememberRemote(
        next,
        entry.key,
        entry.value,
        revisions[entry.key] ?? 0,
      );
      _rebase(next, entry.key, latest);
    }
  });

  Future<void> acknowledge(
    Json operation,
    Json? remote,
    List<String> fields, {
    int revision = 0,
  }) => acknowledgeBatch([
    {
      'operation': operation,
      'remote': remote,
      'fields': fields,
      'revision': revision,
    },
  ]);

  Future<void> acknowledgeBatch(List<Json> replies) => _edit((next) {
    for (final reply in replies) {
      final operation = reply['operation'] as Json;
      final remote = reply['remote'] as Json?;
      final fields = List<String>.from(reply['fields'] as List);
      final revision = reply['revision'] as int;
      final queue = next['pending'] as List;
      queue.removeWhere((op) => op['id'] == operation['id']);
      if (fields.isNotEmpty &&
          !(next['conflicts'] as List).any((c) => c['id'] == operation['id'])) {
        (next['conflicts'] as List).add({
          ...operation,
          'remote': remote,
          'fields': fields,
        });
      }
      final day = operation['day'] as String;
      final latest = _rememberRemote(next, day, remote, revision);
      _rebase(next, day, latest);
    }
    next['lastSaved'] = DateTime.now().toUtc().toIso8601String();
  });

  Future<void> resolve(String id, {required bool useLocal}) {
    _checkEditable();
    return _edit((next) {
      final entries = next['conflicts'] as List;
      final conflict = entries.firstWhere((c) => c['id'] == id) as Json;
      final related = entries
          .where(
            (c) =>
                c['id'] == id ||
                (conflict['batchId'] != null &&
                    c['batchId'] == conflict['batchId']),
          )
          .toList();
      final queue = next['pending'] as List;
      final start = queue.length;
      for (final conflict in related) {
        if (useLocal) {
          final day = conflict['day'] as String;
          final current = (next['sessions'] as Map)[day] as Json?;
          // Preserve unrelated new edits; force only fields changed in this edit.
          final chosen = SessionMerge(
            conflict['base'] as Json?,
            conflict['value'] as Json?,
            current,
          ).value;
          _enqueue(next, day, current, chosen);
          if (chosen == null) {
            (next['sessions'] as Map).remove(day);
          } else {
            (next['sessions'] as Map)[day] = chosen;
          }
        }
        // Retain a local recovery record even after the user chooses a version.
        next['resolved'] ??= <dynamic>[];
        (next['resolved'] as List).add({
          ...conflict,
          'choice': useLocal ? 'local' : 'cloud',
        });
      }
      if (related.length > 1) {
        final batchId = const Uuid().v4();
        for (final op in queue.skip(start)) {
          op['batchId'] = batchId;
        }
      }
      final resolvedIds = related.map((c) => c['id']).toSet();
      entries.removeWhere((c) => resolvedIds.contains(c['id']));
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
