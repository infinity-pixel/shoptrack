import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/data/shopping_repository.dart';
import '../../../../core/utils/session_date_manager.dart';
import '../../../../models/monthly_summary.dart';
import '../../../../models/shopping_session.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../widgets/session_card.dart';

class MonthlyHistoryPage extends StatefulWidget {
  final MonthlySummary summary;
  final Function(DateTime) onSessionSelected;

  const MonthlyHistoryPage({
    super.key,
    required this.summary,
    required this.onSessionSelected,
  });

  @override
  State<MonthlyHistoryPage> createState() => _MonthlyHistoryPageState();
}

class _MonthlyHistoryPageState extends State<MonthlyHistoryPage> {
  late List<ShoppingSession> _sessions;
  final ShoppingRepository _repository = LocalShoppingRepository();

  @override
  void initState() {
    super.initState();
    _sessions = List.from(widget.summary.sessions);
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
    
    // Always reload from repository to ensure consistency
    final all = await _repository.getAllSessions(includeEmpty: true);
    final monthSessions = all.where((s) => 
      s.date.year == widget.summary.year && 
      s.date.month == widget.summary.month &&
      s.items.isNotEmpty
    ).toList()..sort((a, b) => b.date.compareTo(a.date));

    if (mounted) {
      setState(() {
        _sessions = monthSessions;
      });
      if (_sessions.isEmpty) {
        Navigator.pop(context, true);
      }
    }
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
      setState(() {
        _sessions.removeWhere((s) => s.id == session.id);
      });
      
      if (_sessions.isEmpty && mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _editSessionDate(ShoppingSession session) async {
    await SessionDateManager.editSessionDate(
      context: context,
      session: session,
      repository: _repository,
      onUpdated: () async {
        final all = await _repository.getAllSessions(includeEmpty: true);
        final monthSessions = all.where((s) => 
          s.date.year == widget.summary.year && 
          s.date.month == widget.summary.month &&
          s.items.isNotEmpty
        ).toList()..sort((a, b) => b.date.compareTo(a.date));

        if (mounted) {
          setState(() {
            _sessions = monthSessions;
          });
          if (_sessions.isEmpty) {
            Navigator.pop(context, true);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.summary.displayTitle),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          return SessionCard(
            session: session,
            onTap: () => _openSession(session.date),
            onEdit: () => _editSessionDate(session),
            onDelete: () => _deleteSession(session),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDateDialog() async {
    final firstDate = DateTime(widget.summary.year, widget.summary.month, 1);
    final lastDate = DateTime(widget.summary.year, widget.summary.month + 1, 0);
    
    // Task 3: Use the first day of the month as a neutral default initial date
    final initialDate = firstDate;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select date in ${widget.summary.monthName}',
    );

    if (selectedDate == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Shopping Date'),
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

    if (confirmed == true && mounted) {
      _openSession(selectedDate);
    }
  }
}
