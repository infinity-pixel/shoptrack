import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../models/shopping_item.dart';
import '../../../models/shopping_session.dart';

abstract class ShoppingRepository {
  Future<ShoppingSession> getSessionByDate(DateTime date);
  Future<List<ShoppingSession>> getAllSessions();
  Future<void> saveSession(ShoppingSession session);
  Future<void> clearAll();
}

class LocalShoppingRepository implements ShoppingRepository {
  static const String _sessionsKey = 'shopping_sessions';
  static const String _legacyItemsKey = 'shopping_items';

  @override
  Future<ShoppingSession> getSessionByDate(DateTime date) async {
    final all = await getAllSessions();
    
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
        date: date,
        items: [],
      );
    }
  }

  @override
  Future<List<ShoppingSession>> getAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Perform Migration if needed
      await _migrateLegacyData(prefs);

      final String? sessionsJson = prefs.getString(_sessionsKey);
      if (sessionsJson == null) return [];

      final List<dynamic> decodedList = jsonDecode(sessionsJson);
      final sessions = decodedList
          .map((json) => ShoppingSession.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Sort newest first
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
      final all = await getAllSessions();
      
      final index = all.indexWhere((s) => s.id == session.id);
      if (index != -1) {
        all[index] = session;
      } else {
        all.add(session);
      }

      final String json = jsonEncode(all.map((s) => s.toJson()).toList());
      await prefs.setString(_sessionsKey, json);
    } catch (e) {
      debugPrint('Error saving session: $e');
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
          .map((j) => ShoppingItem.fromJson(jsonDecode(jsonEncode(j)))) // Safety cast
          .toList();

      if (items.isNotEmpty) {
        final session = ShoppingSession(
          id: const Uuid().v4(),
          date: DateTime.now(),
          items: items,
        );
        
        // Save using current logic (will avoid infinite recursion by not calling getAllSessions here)
        // But we need to check if a session for today already exists in the new key to avoid overwriting.
        // Actually, just append to new key if exists.
        final String? existingSessionsJson = prefs.getString(_sessionsKey);
        List<ShoppingSession> all = [];
        if (existingSessionsJson != null) {
          all = (jsonDecode(existingSessionsJson) as List)
              .map((j) => ShoppingSession.fromJson(j))
              .toList();
        }
        
        all.add(session);
        await prefs.setString(_sessionsKey, jsonEncode(all.map((s) => s.toJson()).toList()));
      }
      
      await prefs.remove(_legacyItemsKey);
      debugPrint('Migration from Sprint 7 successful.');
    } catch (e) {
      debugPrint('Migration failed: $e');
      // If migration fails, we don't remove the key yet to avoid data loss? 
      // But we should probably avoid multiple fail logs.
    }
  }
}
