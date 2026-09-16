import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../models/shopping_item.dart';
import '../../../models/shopping_session.dart';
import 'sync_store.dart';
import 'session_merge.dart';

abstract class ShoppingRepository {
  Future<ShoppingSession> getSessionByDate(DateTime date);
  Future<List<ShoppingSession>> getAllSessions({bool includeEmpty = false});
  Future<void> saveSession(ShoppingSession session);
  Future<void> deleteSession(String id);
  Future<void> replaceSessions(List<ShoppingSession> sessions);
  Future<void> clearAll();
}

class LocalShoppingRepository implements ShoppingRepository {
  LocalShoppingRepository({SyncStore? store})
    : _store = store ?? activeStore,
      _editGeneration = (store ?? activeStore)?.editGeneration;
  static SyncStore? activeStore;
  final SyncStore? _store;
  final int? _editGeneration;
  void _checkAccount() {
    if (_store?.editGeneration != _editGeneration) {
      throw StateError('This editor belongs to a previous account session.');
    }
  }

  final Map<String, Json?> _baselines = {};
  Listenable? get changes => _store;
  String get accountScope => _store?.scope ?? 'legacy';
  int get conflictCount => _store?.conflicts.length ?? 0;

  Future<void> saveSessions(List<ShoppingSession> sessions) async {
    _checkAccount();
    if (_store == null) {
      for (final session in sessions) {
        await saveSession(session);
      }
      return;
    }
    final edits = [
      for (final s in sessions)
        {
          'day': sessionDay(s.date),
          'base': _baselines[sessionDay(s.date)],
          'value': copyJson(s.toJson()),
        },
    ];
    await _store.saveBatch(edits);
    for (final edit in edits) {
      _baselines[edit['day'] as String] = edit['value'] as Json;
    }
  }

  static const String _sessionsKey = 'shopping_sessions';
  static const String _legacyItemsKey = 'shopping_items';

  @override
  Future<ShoppingSession> getSessionByDate(DateTime date) async {
    final all = await getAllSessions(includeEmpty: true);
    final day = sessionDay(date);
    final matches = all.where((s) => sessionDay(s.date) == day);
    _baselines[day] = matches.isEmpty ? null : copyJson(matches.first.toJson());

    // Find session with same calendar date
    try {
      return all.firstWhere(
        (s) =>
            s.date.year == date.year &&
            s.date.month == date.month &&
            s.date.day == date.day,
      );
    } catch (_) {
      // Return empty session for that date
      return ShoppingSession(
        id: const Uuid().v4(),
        date: DateTime(date.year, date.month, date.day),
        items: [],
      );
    }
  }

  @override
  Future<List<ShoppingSession>> getAllSessions({
    bool includeEmpty = false,
  }) async {
    if (_store != null) {
      final all = _store.sessions;
      for (final session in all) {
        _baselines.putIfAbsent(
          sessionDay(session.date),
          () => copyJson(session.toJson()),
        );
      }
      return includeEmpty ? all : all.where((s) => s.items.isNotEmpty).toList();
    }
    try {
      final prefs = await SharedPreferences.getInstance();

      // Perform Migration if needed
      await _migrateLegacyData(prefs);

      final String? sessionsJson = prefs.getString(_sessionsKey);
      if (sessionsJson == null) return [];

      final List<dynamic> decodedList = jsonDecode(sessionsJson);
      List<ShoppingSession> sessions = decodedList
          .map((json) => ShoppingSession.fromJson(json as Map<String, dynamic>))
          .toList();

      // Filter empty sessions unless requested otherwise (Rule 16)
      if (!includeEmpty) {
        sessions = sessions.where((s) => s.items.isNotEmpty).toList();
      }

      // Sort newest first as a baseline (UI will group and sort specifically)
      sessions.sort((a, b) => b.date.compareTo(a.date));
      return sessions;
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      return [];
    }
  }

  @override
  Future<void> saveSession(ShoppingSession session) async {
    _checkAccount();
    if (_store != null) {
      final day = sessionDay(session.date);
      final value = copyJson(session.toJson());
      final base = _baselines[day];
      _baselines[day] = value;
      try {
        await _store.save(day, base, value);
      } catch (_) {
        _baselines[day] = base;
        rethrow;
      }
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      // Use internal helper to get all sessions including empty ones
      final String? sessionsJson = prefs.getString(_sessionsKey);
      List<ShoppingSession> all = [];
      if (sessionsJson != null) {
        all = (jsonDecode(sessionsJson) as List)
            .map(
              (json) => ShoppingSession.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }

      final index = all.indexWhere((s) => s.id == session.id);
      if (index != -1) {
        all[index] = session;
      } else {
        // Double check if a session for this date already exists
        final dateIndex = all.indexWhere(
          (s) =>
              s.date.year == session.date.year &&
              s.date.month == session.date.month &&
              s.date.day == session.date.day,
        );
        if (dateIndex != -1) {
          all[dateIndex] = session;
        } else {
          all.add(session);
        }
      }

      final String updatedJson = jsonEncode(
        all.map((s) => s.toJson()).toList(),
      );
      if (!await prefs.setString(_sessionsKey, updatedJson)) {
        throw StateError('Shopping data could not be saved on this device');
      }
    } catch (e) {
      debugPrint('Error saving session: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteSession(String id) async {
    _checkAccount();
    if (_store != null) {
      final matches = _store.sessions.where((s) => s.id == id);
      if (matches.isEmpty) return;
      final session = matches.first;
      final day = sessionDay(session.date);
      await _store.save(day, _baselines[day] ?? session.toJson(), null);
      _baselines[day] = null;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? sessionsJson = prefs.getString(_sessionsKey);
      if (sessionsJson == null) return;

      List<ShoppingSession> all = (jsonDecode(sessionsJson) as List)
          .map((json) => ShoppingSession.fromJson(json as Map<String, dynamic>))
          .toList();

      all.removeWhere((s) => s.id == id);

      final String updatedJson = jsonEncode(
        all.map((s) => s.toJson()).toList(),
      );
      await prefs.setString(_sessionsKey, updatedJson);
    } catch (e) {
      debugPrint('Error deleting session: $e');
    }
  }

  @override
  Future<void> replaceSessions(List<ShoppingSession> sessions) async {
    _checkAccount();
    if (_store != null) {
      await _store.replace(sessions);
      _baselines.clear();
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final String updatedJson = jsonEncode(
        sessions.map((s) => s.toJson()).toList(),
      );
      await prefs.setString(_sessionsKey, updatedJson);
    } catch (e) {
      debugPrint('Error replacing sessions: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearAll() async {
    _checkAccount();
    if (_store != null) {
      await _store.replace([]);
      _baselines.clear();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
    await prefs.remove(_legacyItemsKey);
  }

  Future<void> _migrateLegacyData(SharedPreferences prefs) async {
    final String? legacyJson = prefs.getString(_legacyItemsKey);
    if (legacyJson == null) return;

    try {
      final List<dynamic> decodedItems = jsonDecode(legacyJson);
      final items = decodedItems
          .map((j) => ShoppingItem.fromJson(j as Map<String, dynamic>))
          .toList();

      if (items.isNotEmpty) {
        final now = DateTime.now();
        final session = ShoppingSession(
          id: const Uuid().v4(),
          date: DateTime(now.year, now.month, now.day),
          items: items,
        );

        final String? existingSessionsJson = prefs.getString(_sessionsKey);
        List<ShoppingSession> all = [];
        if (existingSessionsJson != null) {
          all = (jsonDecode(existingSessionsJson) as List)
              .map((j) => ShoppingSession.fromJson(j as Map<String, dynamic>))
              .toList();
        }

        all.add(session);
        await prefs.setString(
          _sessionsKey,
          jsonEncode(all.map((s) => s.toJson()).toList()),
        );
      }

      await prefs.remove(_legacyItemsKey);
      debugPrint('Migration from Sprint 7 successful.');
    } catch (e) {
      debugPrint('Migration failed: $e');
    }
  }
}
