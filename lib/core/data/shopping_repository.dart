import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../models/shopping_item.dart';
import '../../../models/shopping_session.dart';

abstract class ShoppingRepository {
  Future<ShoppingSession> getSessionByDate(DateTime date);
  Future<List<ShoppingSession>> getAllSessions({bool includeEmpty = false});
  Future<void> saveSession(ShoppingSession session);
  Future<void> deleteSession(String id);
  Future<void> replaceSessions(List<ShoppingSession> sessions);
  Future<void> clearAll();
}

class LocalShoppingRepository implements ShoppingRepository {
  static const String _sessionsKey = 'shopping_sessions';
  static const String _legacyItemsKey = 'shopping_items';

  @override
  Future<ShoppingSession> getSessionByDate(DateTime date) async {
    final all = await getAllSessions(includeEmpty: true);
    
    // Find session with same calendar date
    try {
      return all.firstWhere((s) => 
        s.date.year == date.year && 
        s.date.month == date.month && 
        s.date.day == date.day
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
  Future<List<ShoppingSession>> getAllSessions({bool includeEmpty = false}) async {
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
    try {
      final prefs = await SharedPreferences.getInstance();
      // Use internal helper to get all sessions including empty ones
      final String? sessionsJson = prefs.getString(_sessionsKey);
      List<ShoppingSession> all = [];
      if (sessionsJson != null) {
        all = (jsonDecode(sessionsJson) as List)
            .map((json) => ShoppingSession.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      
      final index = all.indexWhere((s) => s.id == session.id);
      if (index != -1) {
        all[index] = session;
      } else {
        // Double check if a session for this date already exists
        final dateIndex = all.indexWhere((s) => 
          s.date.year == session.date.year && 
          s.date.month == session.date.month && 
          s.date.day == session.date.day
        );
        if (dateIndex != -1) {
          all[dateIndex] = session;
        } else {
          all.add(session);
        }
      }

      final String updatedJson = jsonEncode(all.map((s) => s.toJson()).toList());
      await prefs.setString(_sessionsKey, updatedJson);
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  @override
  Future<void> deleteSession(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? sessionsJson = prefs.getString(_sessionsKey);
      if (sessionsJson == null) return;

      List<ShoppingSession> all = (jsonDecode(sessionsJson) as List)
          .map((json) => ShoppingSession.fromJson(json as Map<String, dynamic>))
          .toList();
          
      all.removeWhere((s) => s.id == id);
      
      final String updatedJson = jsonEncode(all.map((s) => s.toJson()).toList());
      await prefs.setString(_sessionsKey, updatedJson);
    } catch (e) {
      debugPrint('Error deleting session: $e');
    }
  }

  @override
  Future<void> replaceSessions(List<ShoppingSession> sessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String updatedJson = jsonEncode(sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_sessionsKey, updatedJson);
    } catch (e) {
      debugPrint('Error replacing sessions: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearAll() async {
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
        await prefs.setString(_sessionsKey, jsonEncode(all.map((s) => s.toJson()).toList()));
      }
      
      await prefs.remove(_legacyItemsKey);
      debugPrint('Migration from Sprint 7 successful.');
    } catch (e) {
      debugPrint('Migration failed: $e');
    }
  }
}
