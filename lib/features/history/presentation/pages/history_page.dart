import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/data/shopping_repository.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../models/shopping_session.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    return _buildSessionTile(_sessions[index]);
                  },
                ),
    );
  }

  Widget _buildSessionTile(ShoppingSession session) {
    final String dateStr = session.isToday
        ? 'Today'
        : DateFormat('d MMMM yyyy').format(session.date);
    
    final int itemCount = session.items.length;
    final double purchasedAmount = session.items
        .where((i) => i.isPurchased)
        .fold(0.0, (sum, item) => sum + item.pricing.totalPrice);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: () => widget.onSessionSelected(session.date),
        title: Text(
          dateStr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('$itemCount items'),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              NumberFormatter.formatPrice(purchasedAmount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
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
}
