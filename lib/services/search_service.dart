import 'package:flutter/material.dart';
import '../core/data/shopping_repository.dart';
import '../models/shopping_search_result.dart';

class SearchService {
  final ShoppingRepository _repository;

  SearchService(this._repository);

  Future<List<ShoppingSearchResult>> searchItems({
    required String query,
    SearchItemStatus? statusFilter,
    DateTimeRange? dateRange,
  }) async {
    if (query.trim().isEmpty && statusFilter == null && dateRange == null) return [];

    final normalizedQuery = query.trim().toLowerCase();
    final allSessions = await _repository.getAllSessions(includeEmpty: true);
    
    final results = <ShoppingSearchResult>[];

    for (final session in allSessions) {
      // 1. Date Range Filter
      if (dateRange != null) {
        final normalizedSessionDate = DateTime(session.date.year, session.date.month, session.date.day);
        final normalizedFrom = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
        final normalizedTo = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day);
        
        if (normalizedSessionDate.isBefore(normalizedFrom) || normalizedSessionDate.isAfter(normalizedTo)) {
          continue;
        }
      }

      for (final item in session.items) {
        final result = ShoppingSearchResult(item: item, session: session);
        
        // 2. Query Filter
        if (normalizedQuery.isNotEmpty && !item.name.toLowerCase().contains(normalizedQuery)) {
          continue;
        }

        // 3. Status Filter
        if (statusFilter != null && result.status != statusFilter) {
          continue;
        }

        results.add(result);
      }
    }

    // Sort results by date (newest first)
    results.sort((a, b) => b.session.date.compareTo(a.session.date));

    return results;
  }
}
