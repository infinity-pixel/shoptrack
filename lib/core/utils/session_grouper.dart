import '../../models/monthly_summary.dart';
import '../../models/shopping_session.dart';

class SessionGrouper {
  /// Groups sessions into monthly summaries for completed months.
  /// A month is considered completed if the current date [now] is beyond that month.
  static List<MonthlySummary> groupIntoMonths(List<ShoppingSession> sessions, DateTime now) {
    // We only care about sessions in months BEFORE the current month.
    final completedSessions = sessions.where((s) {
      if (s.date.year < now.year) return true;
      if (s.date.year == now.year && s.date.month < now.month) return true;
      return false;
    }).toList();

    if (completedSessions.isEmpty) return [];

    // Group by month and year
    final groups = <String, List<ShoppingSession>>{};
    for (final s in completedSessions) {
      final key = '${s.date.year}-${s.date.month}';
      groups.putIfAbsent(key, () => []).add(s);
    }

    // Create MonthlySummary objects and filter empty ones
    final summaries = groups.entries.map((e) {
      final parts = e.key.split('-');
      return MonthlySummary(
        year: int.parse(parts[0]),
        month: int.parse(parts[1]),
        sessions: e.value..sort((a, b) => b.date.compareTo(a.date)), // Sort sessions newest first
      );
    }).where((s) => !s.isEmpty).toList();

    // Sort summaries: Latest completed month first
    summaries.sort((a, b) {
      if (a.year != b.year) return b.year.compareTo(a.year);
      return b.month.compareTo(a.month);
    });

    return summaries;
  }
}
