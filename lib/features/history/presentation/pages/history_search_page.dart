import 'dart:async';
import 'package:shoptrack/core/localization/shoptrack_text.dart';
import 'package:flutter/material.dart';
import 'package:shoptrack/core/calendar/shop_calendar.dart';
import '../../../../core/data/shopping_repository.dart';
import '../../../../core/theme/theme_presets.dart';
import '../../../../core/widgets/shoptrack_navigation_bar.dart';
import '../../../../models/frequent_item_suggestion.dart';
import '../../../../models/shopping_search_result.dart';
import '../../../../services/settings_service.dart';
import '../../../../services/frequent_items_service.dart';
import '../../../../services/search_service.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../widgets/search_result_card.dart';
import '../widgets/smart_date_range_picker.dart';

class HistorySearchPage extends StatefulWidget {
  const HistorySearchPage({
    super.key,
    this.onTabSelected,
    this.settingsService,
  });
  final ValueChanged<int>? onTabSelected;
  final SettingsService? settingsService;
  @override
  State<HistorySearchPage> createState() => _HistorySearchPageState();
}

class _HistorySearchPageState extends State<HistorySearchPage> {
  final _repository = LocalShoppingRepository();
  final _searchController = TextEditingController();
  final _searchService = SearchService(LocalShoppingRepository());
  final _frequent = FrequentItemsService(LocalShoppingRepository());
  List<ShoppingSearchResult> _results = [];
  List<FrequentItemSuggestion> _suggestions = [];
  SearchItemStatus? _status;
  DateTimeRange? _range;
  Timer? _debounce;
  int _request = 0;
  bool _loading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _repository.changes?.addListener(_onShoppingChanged);
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      final values = await _frequent.getSuggestions(limit: 5);
      if (mounted) setState(() => _suggestions = values);
    } catch (_) {
      /* Search remains available. */
    }
  }

  @override
  void dispose() {
    _repository.changes?.removeListener(_onShoppingChanged);
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onShoppingChanged() {
    if (!mounted) return;
    _loadSuggestions();
    _search();
  }

  bool get _active =>
      _searchController.text.trim().isNotEmpty ||
      _status != null ||
      _range != null;
  Future<void> _search() async {
    _debounce?.cancel();
    final request = ++_request;
    if (!mounted) return;
    if (!_active) {
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _searchService.searchItems(
        query: _searchController.text,
        statusFilter: _status,
        dateRange: _range,
      );
      if (mounted && request == _request) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _loading = false;
          _error = 'Could not load history. Please try again.';
        });
      }
    }
  }

  Future<void> _pickRange() async {
    FocusScope.of(context).unfocus();
    final selection = await showModalBottomSheet<DateRangeSelection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SmartDateRangePicker(initialRange: _range),
    );
    if (!mounted || selection == null) return;
    setState(() => _range = selection.range);
    _search();
  }

  Future<void> _open(ShoppingSearchResult result) async {
    FocusScope.of(context).unfocus();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) => HomePage(
          sessionDate: result.session.date,
          settingsService: widget.settingsService,
          onBackToHistory: () => Navigator.pop(routeContext),
        ),
      ),
    );
    if (mounted) _search();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ShopTrackThemeTokens.of(context);
    final p = tokens.palette;
    final calendarAccent = tokens.calendarAccent ?? p.onSurface;
    return Scaffold(
      bottomNavigationBar: widget.onTabSelected == null
          ? null
          : ShopTrackNavigationBar(
              currentIndex: 1,
              onTap: (index) {
                Navigator.pop(context);
                widget.onTabSelected!(index);
              },
            ),
      backgroundColor: p.background,
      appBar: AppBar(title: const ShopText('Search History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: shopTr(context, 'Search items'),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: p.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: shopTr(context, 'Clear search'),
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          _search();
                        },
                      ),
              ),
              onChanged: (_) {
                ++_request;
                setState(() {});
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), _search);
              },
              onSubmitted: (_) => _search(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final status in [null, ...SearchItemStatus.values])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: FilterChip(
                      selected: _status == status,
                      selectedColor: p.secondary,
                      labelStyle: TextStyle(
                        color: _status == status ? p.onSecondary : p.onSurface,
                      ),
                      showCheckmark: false,
                      avatar: status == null
                          ? null
                          : Icon(
                              Icons.circle,
                              size: 10,
                              color: _status == status
                                  ? p.onSecondary
                                  : switch (status) {
                                      SearchItemStatus.purchased =>
                                        p.purchasedStatus,
                                      SearchItemStatus.pending => p.pending,
                                      _ => p.planned,
                                    },
                            ),
                      label: ShopText(switch (status) {
                        null => 'All',
                        SearchItemStatus.purchased => 'Purchased',
                        SearchItemStatus.pending => 'Pending',
                        _ => 'Planned',
                      }),
                      onSelected: (_) {
                        setState(
                          () => _status = _status == status ? null : status,
                        );
                        _search();
                      },
                    ),
                  ),
                ActionChip(
                  backgroundColor: _range != null ? p.secondary : p.surface,
                  labelStyle: TextStyle(
                    color: _range != null ? p.onSecondary : p.onSurface,
                  ),
                  avatar: Icon(
                    Icons.date_range,
                    size: 18,
                    color: _range != null ? p.onSecondary : calendarAccent,
                  ),
                  label: const ShopText('Date Range'),
                  onPressed: _pickRange,
                ),
              ],
            ),
          ),
          if (_range != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: InputChip(
                  label: Text(
                    '${shopDate(context, _range!.start)} — ${shopDate(context, _range!.end)}',
                    maxLines: 2,
                  ),
                  onDeleted: () {
                    setState(() => _range = null);
                    _search();
                  },
                ),
              ),
            ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    final p = ShopTrackThemeTokens.of(context).palette;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: TextButton(onPressed: _search, child: ShopText(_error!)),
      );
    }
    if (!_active) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ShopText(
            'Find items across your shopping dates',
            style: TextStyle(color: p.textSecondary),
          ),
          if (_suggestions.isNotEmpty) ...[
            const SizedBox(height: 20),
            ShopText(
              'Frequently Purchased',
              style: TextStyle(
                color: p.onBackground,
                fontWeight: FontWeight.bold,
              ),
            ),
            for (final suggestion in _suggestions)
              ListTile(
                leading: Icon(Icons.history, color: p.purchasedStatus),
                title: Text(suggestion.name),
                trailing: const Icon(Icons.search),
                onTap: () {
                  _searchController.text = suggestion.name;
                  setState(() => _status = SearchItemStatus.purchased);
                  _search();
                },
              ),
          ],
        ],
      );
    }
    return ListView.builder(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(16),
      itemCount: _results.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              _results.isEmpty
                  ? shopTr(
                      context,
                      'No matching items. Try another search or filter.',
                    )
                  : '${shopNumber(context, _results.length)} ${shopTr(context, _results.length == 1 ? 'result' : 'results')}',
              style: TextStyle(color: p.textSecondary),
            ),
          );
        }
        final result = _results[index - 1];
        final date = result.session.date;
        final previous = index > 1 ? _results[index - 2].session.date : null;
        return Column(
          children: [
            if (previous == null ||
                ShopCalendarScope.of(context).monthStart(previous) !=
                    ShopCalendarScope.of(context).monthStart(date))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        shopDate(context, date, 'yMMMM').toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: p.onBackground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Divider(color: p.border)),
                  ],
                ),
              ),
            SearchResultCard(result: result, onTap: () => _open(result)),
          ],
        );
      },
    );
  }
}
