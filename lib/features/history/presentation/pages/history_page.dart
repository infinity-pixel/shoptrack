import 'package:flutter/material.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';
import 'package:intl/intl.dart';

import '../../../../core/data/shopping_repository.dart';
import '../../../../core/theme/theme_presets.dart';
import '../../../../core/utils/session_date_manager.dart';
import '../../../../core/widgets/scroll_aware_fab.dart';
import '../../../../core/widgets/shopping_list_share_sheet.dart';
import '../../../../core/widgets/shoptrack_modal.dart';
import '../../../../models/app_settings.dart';
import '../../../../models/shopping_session.dart';
import '../../../../services/settings_service.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../widgets/session_card.dart';
import 'history_search_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    required this.onSessionSelected,
    this.onTabSelected,
    this.settingsService,
  });

  final ValueChanged<DateTime> onSessionSelected;
  final ValueChanged<int>? onTabSelected;
  final SettingsService? settingsService;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  final LocalShoppingRepository _repository = LocalShoppingRepository();
  late final AnimationController _headingGlowController;
  late final Animation<double> _headingGlow;
  List<ShoppingSession> _sessions = [];
  bool _isLoading = true;
  bool _fabExpanded = true;
  final FabScrollIntent _fabScrollIntent = FabScrollIntent();
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _repository.changes?.addListener(_loadSessions);
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
    _repository.changes?.removeListener(_loadSessions);
    _headingGlowController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await _repository.getAllSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loadError = null;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError =
            'Could not load history. Your saved records have not been changed.';
        _isLoading = false;
      });
    }
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
            const ShopText('History'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _loadError != null
                ? _buildErrorState()
                : _sessions.isEmpty
                ? _buildEmptyState()
                : NotificationListener<ScrollUpdateNotification>(
                    onNotification: (notification) {
                      if (notification.depth != 0) return false;
                      final desired = _fabScrollIntent.update(
                        notification.scrollDelta ?? 0,
                        atStart:
                            notification.metrics.pixels <=
                            notification.metrics.minScrollExtent,
                      );
                      if (desired != null && _fabExpanded != desired) {
                        setState(() => _fabExpanded = desired);
                      }
                      return false;
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                      children: [
                        if (upcoming.isNotEmpty) ...[
                          _buildSectionHeader(
                            'UPCOMING',
                            palette.planned,
                            animated: true,
                          ),
                          ...upcoming.map(_buildSessionCard),
                          const SizedBox(height: 16),
                        ],
                        if (today.isNotEmpty) ...[
                          _buildSectionHeader(
                            'TODAY',
                            palette.today,
                            animated: true,
                          ),
                          ...today.map(_buildSessionCard),
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
      floatingActionButton: DelayedExtendedFab(
        expanded: _fabExpanded,
        onPressed: _showAddCustomDateDialog,
        icon: const CalendarAddIcon(),
        label: shopTr(context, 'New Date'),
        tooltip: shopTr(context, 'Create a past or future date'),
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
              MaterialPageRoute(
                builder: (_) => HistorySearchPage(
                  onTabSelected: widget.onTabSelected,
                  settingsService: widget.settingsService,
                ),
              ),
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
                ShopText(
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
              ShopText(
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
      numberFormat:
          widget.settingsService?.settings.numberFormat ??
          NumberFormatPreference.automatic,
      onTap: () => _openSession(session.date),
      onShare: () => showShoppingListShareSheet(context, session),
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
          settingsService: widget.settingsService,
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
        title: const ShopText('Delete this date?'),
        content: const ShopText(
          'This permanently deletes this shopping record and every list inside it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const ShopText('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: palette.pending),
            onPressed: () => Navigator.pop(context, true),
            child: const ShopText('Delete Permanently'),
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
          ShopText(
            'No shopping history yet',
            style: TextStyle(color: palette.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final palette = ShopTrackThemeTokens.of(context).palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: palette.pending),
            const SizedBox(height: 12),
            ShopText(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                setState(() => _isLoading = true);
                _loadSessions();
              },
              icon: const Icon(Icons.refresh),
              label: const ShopText('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddCustomDateDialog() async {
    final tokens = ShopTrackThemeTokens.of(context);
    final palette = tokens.palette;
    final calendarAccent = tokens.calendarAccent ?? palette.planned;
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
              ShopTrackSheetHeader(
                title: 'New Date',
                subtitle: 'Add an earlier record or plan a future trip.',
                onClose: () => Navigator.pop(context),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Icon(Icons.history, color: palette.secondary),
                title: const ShopText('Past Date'),
                onTap: () => Navigator.pop(context, 'past'),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                leading: Icon(Icons.calendar_month, color: calendarAccent),
                title: const ShopText('Future Date'),
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
        title: const ShopText('Create shopping date?'),
        content: Text(DateFormat('d MMMM yyyy').format(selectedDate)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const ShopText('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const ShopText('Create'),
          ),
        ],
      ),
    );
    if (confirmed == true) _openSession(selectedDate);
  }
}
