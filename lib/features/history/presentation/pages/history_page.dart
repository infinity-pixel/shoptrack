import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/data/shopping_repository.dart';
import '../../../../core/theme/theme_presets.dart';
import '../../../../core/utils/session_date_manager.dart';
import '../../../../core/widgets/scroll_aware_fab.dart';
import '../../../../models/shopping_session.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../widgets/session_card.dart';
import 'history_search_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.onSessionSelected});

  final ValueChanged<DateTime> onSessionSelected;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  final ShoppingRepository _repository = LocalShoppingRepository();
  late final ScrollAwareFabController _fabController;
  late final AnimationController _headingGlowController;
  late final Animation<double> _headingGlow;
  List<ShoppingSession> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fabController = ScrollAwareFabController();
    _headingGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat(reverse: true);
    _headingGlow = CurvedAnimation(
      parent: _headingGlowController,
      curve: Curves.easeInOut,
    );
    _loadSessions();
  }

  @override
  void didUpdateWidget(covariant HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadSessions();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _headingGlowController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final sessions = await _repository.getAllSessions();
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = ShopTrackThemeTokens.of(context).palette;
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final upcoming = _sessions.where((session) => session.isFuture).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final today = _sessions.where((session) => session.isToday).toList();
    final past = _sessions.where((session) => session.isPast).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final pastGroups = _groupPastSessions(past);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, color: palette.secondary),
            const SizedBox(width: 10),
            const Text('History'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _fabController.handleNotification,
              child: _sessions.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                      children: [
                        if (today.isNotEmpty) ...[
                          _buildSectionHeader(
                            'TODAY',
                            palette.today,
                            animated: true,
                          ),
                          ...today.map(_buildSessionCard),
                          const SizedBox(height: 16),
                        ],
                        if (upcoming.isNotEmpty) ...[
                          _buildSectionHeader(
                            'UPCOMING',
                            palette.planned,
                            animated: true,
                          ),
                          ...upcoming.map(_buildSessionCard),
                          const SizedBox(height: 16),
                        ],
                        for (final entry in pastGroups.entries) ...[
                          _buildSectionHeader(entry.key, palette.textSecondary),
                          ...entry.value.map(_buildSessionCard),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _fabController,
        builder: (context, _) => DelayedExtendedFab(
          expanded: _fabController.isExpanded,
          onPressed: _showAddCustomDateDialog,
          icon: const _CalendarAddIcon(),
          label: 'New Date',
          tooltip: 'Create a past or future date',
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final palette = ShopTrackThemeTokens.of(context).palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: palette.border),
        ),
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistorySearchPage()),
            );
            _loadSessions();
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(Icons.search, color: palette.textSecondary),
                const SizedBox(width: 10),
                Text(
                  'Search history',
                  style: TextStyle(color: palette.textSecondary, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    Color color, {
    bool animated = false,
  }) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animation = animated && !reduceMotion
        ? _headingGlow
        : const AlwaysStoppedAnimation(0.35);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final strength = animated ? 0.10 + animation.value * 0.18 : 0.0;
          return Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 1.25,
                  shadows: animated
                      ? [
                          Shadow(
                            color: color.withValues(alpha: strength),
                            blurRadius: 4 + animation.value * 4,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Divider(color: color.withValues(alpha: 0.22))),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSessionCard(ShoppingSession session) {
    return SessionCard(
      key: ValueKey(session.id),
      session: session,
      glowAnimation: _headingGlow,
      onTap: () => _openSession(session.date),
      onEdit: () => _editSessionDate(session),
      onDelete: () => _deleteSession(session),
    );
  }

  Map<String, List<ShoppingSession>> _groupPastSessions(
    List<ShoppingSession> sessions,
  ) {
    final groups = <String, List<ShoppingSession>>{};
    for (final session in sessions) {
      final key = DateFormat('MMMM yyyy').format(session.date).toUpperCase();
      groups.putIfAbsent(key, () => []).add(session);
    }
    return groups;
  }

  Future<void> _openSession(DateTime date) async {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (isToday) {
      widget.onSessionSelected(date);
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          sessionDate: date,
          onBackToHistory: () => Navigator.pop(context, true),
          onMoveToToday: () {
            Navigator.pop(context, true);
            widget.onSessionSelected(DateTime.now());
          },
        ),
      ),
    );
    _loadSessions();
  }

  Future<void> _deleteSession(ShoppingSession session) async {
    final palette = ShopTrackThemeTokens.of(context).palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this date?'),
        content: const Text(
          'This permanently deletes this shopping record and every list inside it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: palette.pending),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repository.deleteSession(session.id);
      await _loadSessions();
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
    final palette = ShopTrackThemeTokens.of(context).palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 56, color: palette.border),
          const SizedBox(height: 14),
          Text(
            'No shopping history yet',
            style: TextStyle(color: palette.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCustomDateDialog() async {
    final palette = ShopTrackThemeTokens.of(context).palette;
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(8, 4, 8, 12),
                child: Text(
                  'New Date',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: Icon(Icons.history, color: palette.secondary),
                title: const Text('Past Date'),
                onTap: () => Navigator.pop(context, 'past'),
              ),
              ListTile(
                leading: Icon(Icons.calendar_month, color: palette.planned),
                title: const Text('Future Date'),
                onTap: () => Navigator.pop(context, 'future'),
              ),
            ],
          ),
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
      firstDate: result == 'past'
          ? DateTime(2000)
          : today.add(const Duration(days: 1)),
      lastDate: result == 'past'
          ? today.subtract(const Duration(days: 1))
          : DateTime(2100),
    );
    if (selectedDate == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create shopping date?'),
        content: Text(DateFormat('d MMMM yyyy').format(selectedDate)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (confirmed == true) _openSession(selectedDate);
  }
}

class _CalendarAddIcon extends StatelessWidget {
  const _CalendarAddIcon();

  @override
  Widget build(BuildContext context) {
    final palette = ShopTrackThemeTokens.of(context).palette;
    return SizedBox(
      width: 26,
      height: 26,
      child: Stack(
        children: [
          const Icon(Icons.calendar_month_outlined, size: 24),
          Positioned(
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.onPrimary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, size: 12, color: palette.primary),
            ),
          ),
        ],
      ),
    );
  }
}
