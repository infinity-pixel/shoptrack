import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/animation/rolling_digit.dart';
import '../../../../core/data/shopping_repository.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../models/frequent_item_suggestion.dart';
import '../../../../models/shopping_item.dart';
import '../../../../models/shopping_search_result.dart';
import '../../../../services/frequent_items_service.dart';
import '../../../../services/search_service.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../widgets/smart_date_range_picker.dart';

class HistorySearchPage extends StatefulWidget {
  const HistorySearchPage({super.key});

  @override
  State<HistorySearchPage> createState() => _HistorySearchPageState();
}

class _HistorySearchPageState extends State<HistorySearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService(LocalShoppingRepository());
  final FrequentItemsService _frequentItemsService = FrequentItemsService(
    LocalShoppingRepository(),
  );

  List<ShoppingSearchResult> _results = [];
  List<FrequentItemSuggestion> _oftenBought = [];
  bool _isSearching = false;

  // Filters
  SearchItemStatus? _statusFilter;
  DateTimeRange? _dateRange;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadOftenBought();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadOftenBought() async {
    final items = await _frequentItemsService.getSuggestions(limit: 5);
    if (mounted) {
      setState(() {
        _oftenBought = items;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text;

    if (query.trim().isEmpty && _statusFilter == null && _dateRange == null) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await _searchService.searchItems(
      query: query,
      statusFilter: _statusFilter,
      dateRange: _dateRange,
    );

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _statusFilter = null;
      _dateRange = null;
    });
    _performSearch();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SmartDateRangePicker(initialRange: _dateRange),
    );

    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilters = _statusFilter != null || _dateRange != null;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search items...',
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _performSearch();
                      },
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          if (hasActiveFilters) _buildActiveFilterBadges(),
          const Divider(height: 1),
          if (_results.isNotEmpty && !_isSearching)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    '${_results.length} ${_results.length == 1 ? 'result' : 'results'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('All', null),
          const SizedBox(width: 8),
          _buildFilterChip('Pending', SearchItemStatus.pending),
          const SizedBox(width: 8),
          _buildFilterChip('Purchased', SearchItemStatus.purchased),
          const SizedBox(width: 8),
          _buildFilterChip('Planned', SearchItemStatus.planned),
          const VerticalDivider(width: 24),
          ActionChip(
            avatar: Icon(
              Icons.calendar_today,
              size: 16,
              color: _dateRange != null ? Colors.blue : Colors.grey[600],
            ),
            label: Text(
              _dateRange == null ? 'Date Range' : _formatRangeLabel(),
              style: TextStyle(
                color: _dateRange != null ? Colors.blue : null,
                fontWeight: _dateRange != null ? FontWeight.bold : null,
              ),
            ),
            onPressed: _selectDateRange,
          ),
          if (_statusFilter != null || _dateRange != null) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: _resetFilters, child: const Text('Reset')),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, SearchItemStatus? status) {
    final bool isSelected = _statusFilter == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _statusFilter = selected ? status : null;
        });
        _performSearch();
      },
    );
  }

  Widget _buildActiveFilterBadges() {
    if (_dateRange == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Chip(
            label: Text(
              _formatRangeLabel(),
              style: const TextStyle(fontSize: 12),
            ),
            onDeleted: () {
              setState(() => _dateRange = null);
              _performSearch();
            },
            deleteIconColor: Colors.blue,
            backgroundColor: Colors.blue[50],
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  String _formatRangeLabel() {
    if (_dateRange == null) return '';
    final df = DateFormat('d MMM');
    return '${df.format(_dateRange!.start)} - ${df.format(_dateRange!.end)}';
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    final query = _searchController.text.trim();
    if (query.isEmpty && _statusFilter == null && _dateRange == null) {
      return _buildInitialState();
    }

    if (_results.isEmpty) {
      return _buildEmptyState(
        'No matching items found',
        'You may refine the search or filters.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildInitialState() {
    return ListView(
      children: [
        if (_oftenBought.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Frequently Purchased',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
                letterSpacing: 0.5,
              ),
            ),
          ),
          ..._oftenBought.map(
            (suggestion) => ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                radius: 16,
                child: Icon(Icons.history, size: 16, color: Colors.white),
              ),
              title: Text(
                suggestion.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(_getOftenBoughtSubtitle(suggestion)),
              onTap: () => _searchPurchasedDates(suggestion),
            ),
          ),
        ],
        _buildEmptyState(
          'Search your shopping history',
          'Type to search for items or use filters.',
        ),
      ],
    );
  }

  String _getOftenBoughtSubtitle(FrequentItemSuggestion suggestion) {
    final item = suggestion.latestItem;
    String details = '';
    if (item.quantityValue != null && item.shoppingUnit != null) {
      details +=
          '${NumberFormatter.format(item.quantityValue!)} ${item.shoppingUnit!.symbol} • ';
    }
    if (item.priceValue != null) {
      details += 'Last price ${NumberFormatter.formatPrice(item.priceValue!)}';
    } else {
      details += 'No previous price';
    }
    return details;
  }

  void _searchPurchasedDates(FrequentItemSuggestion suggestion) {
    _debounce?.cancel();
    _searchController.text = suggestion.name;
    setState(() {
      _statusFilter = SearchItemStatus.purchased;
      _dateRange = null;
    });
    FocusScope.of(context).unfocus();
    _performSearch();
  }

  Widget _buildResultCard(ShoppingSearchResult result) {
    final item = result.item;
    final session = result.session;

    return InkWell(
      onTap: () => _navigateToSession(session.date),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d MMMM yyyy').format(session.date),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RollingDigitText(
                      text: NumberFormatter.formatPrice(
                        item.pricing.totalPrice,
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getPriceSubtitle(result),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStatusIndicator(result),
          ],
        ),
      ),
    );
  }

  String _getPriceSubtitle(ShoppingSearchResult result) {
    final pricing = result.item.pricing;
    if (result.item.pricingMode == PricingMode.total) {
      return 'Total Amount';
    } else {
      return '${NumberFormatter.formatPrice(pricing.unitPrice)}/${pricing.priceBasisSymbol}';
    }
  }

  Widget _buildStatusIndicator(ShoppingSearchResult result) {
    Color color;
    switch (result.status) {
      case SearchItemStatus.purchased:
        color = Colors.green;
        break;
      case SearchItemStatus.pending:
        color = Colors.red;
        break;
      case SearchItemStatus.planned:
        color = Colors.purple;
        break;
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          result.statusLabel,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSession(DateTime date) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(
          sessionDate: date,
          onBackToHistory: () => Navigator.pop(context),
        ),
      ),
    );
    // Refresh search results when returning in case item was edited/deleted
    _performSearch();
  }
}
