import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/data/shopping_repository.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/utils/session_grouper.dart';
import '../../../../core/utils/session_date_manager.dart';
import '../../../../models/monthly_summary.dart';
import '../../../../models/shopping_session.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../widgets/session_card.dart';
import 'monthly_history_page.dart';

class HistoryPage extends StatefulWidget {
  final Function(DateTime) onSessionSelected;

  const HistoryPage({super.key, required this.onSessionSelected});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final ShoppingRepository _repository = LocalShoppingRepository();
  List<ShoppingSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void didUpdateWidget(HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final sessions = await _repository.getAllSessions();
    if (mounted) {
      setState(() {
        _sessions = sessions;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final now = DateTime.now();

    final upcoming = _sessions.where((s) => s.isFuture).toList()
      ..sort((a, b) => a.date.compareTo(b.date)); // Nearest first
    
    final todaySessions = _sessions.where((s) => s.isToday).toList();
    
    // Past sessions for the CURRENT month only
    final pastCurrentMonth = _sessions.where((s) => 
      s.isPast && 
      s.date.year == now.year && 
      s.date.month == now.month
    ).toList()..sort((a, b) => b.date.compareTo(a.date));

    // Completed months aggregation
    final monthlyHistory = SessionGrouper.groupIntoMonths(_sessions, now);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: false,
      ),
      body: _sessions.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              children: [
                if (upcoming.isNotEmpty) ...[
                  _buildSectionHeader('UPCOMING', Colors.purple),
                  ...upcoming.map((s) => SessionCard(
                    session: s,
                    onTap: () => _openSession(s.date),
                    onEdit: () => _editSessionDate(s),
                    onDelete: () => _deleteSession(s),
                  )),
                  const SizedBox(height: 24),
                ],
                if (todaySessions.isNotEmpty) ...[
                  _buildSectionHeader('TODAY', Colors.blue),
                  ...todaySessions.map((s) => SessionCard(
                    session: s,
                    onTap: () => _openSession(s.date),
                    onEdit: () => _editSessionDate(s),
                    onDelete: () => _deleteSession(s),
                  )),
                  const SizedBox(height: 24),
                ],
                if (pastCurrentMonth.isNotEmpty) ...[
                  _buildSectionHeader('PAST', Colors.grey),
                  ...pastCurrentMonth.map((s) => SessionCard(
                    session: s,
                    onTap: () => _openSession(s.date),
                    onEdit: () => _editSessionDate(s),
                    onDelete: () => _deleteSession(s),
                  )),
                  const SizedBox(height: 24),
                ],
                if (monthlyHistory.isNotEmpty) ...[
                  _buildSectionHeader('MONTHLY HISTORY', Colors.indigo),
                  ...monthlyHistory.map((summary) => _buildMonthlySummaryCard(summary)),
                  const SizedBox(height: 24),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomDateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    final bool isTodaySection = title == 'TODAY';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Row(
        children: [
          Container(
            padding: isTodaySection ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2) : null,
            decoration: isTodaySection ? BoxDecoration(
              color: color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ) : null,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color.withValues(alpha: 0.7),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: color.withValues(alpha: 0.1),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard(MonthlySummary summary) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MonthlyHistoryPage(
                summary: summary,
                onSessionSelected: widget.onSessionSelected,
              ),
            ),
          );
          _loadSessions();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      summary.displayTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (summary.purchasedCount > 0)
                    _buildStatusPill(summary.purchasedStatusText, Colors.green),
                  if (summary.pendingCount > 0)
                    _buildStatusPill(summary.pendingStatusText, Colors.red),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Purchased',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    NumberFormatter.formatPrice(summary.totalPurchasedAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSession(DateTime date) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          sessionDate: date,
          onBackToHistory: () => Navigator.pop(context, true),
        ),
      ),
    );
    _loadSessions();
  }

  Future<void> _deleteSession(ShoppingSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this date?'),
        content: const Text(
          'This will permanently delete this shopping record and all of its items. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _repository.deleteSession(session.id);
      _loadSessions();
    }
  }

  Future<void> _editSessionDate(ShoppingSession session) async {
    await SessionDateManager.editSessionDate(
      context: context,
      session: session,
      repository: _repository,
      onUpdated: _loadSessions,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No shopping history yet',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCustomDateDialog() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add Custom Date',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text('Past Date'),
              onTap: () => Navigator.pop(context, 'past'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month, color: Colors.purple),
              title: const Text('Future Date'),
              onTap: () => Navigator.pop(context, 'future'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: result == 'past'
          ? today.subtract(const Duration(days: 1))
          : today.add(const Duration(days: 1)),
      firstDate:
          result == 'past' ? DateTime(2000) : today.add(const Duration(days: 1)),
      lastDate: result == 'past'
          ? today.subtract(const Duration(days: 1))
          : DateTime(2100),
    );

    if (selectedDate == null) return;
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Date'),
        content: Text(DateFormat('d MMMM yyyy').format(selectedDate)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _openSession(selectedDate);
    }
  }
}
