import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import '../../../../core/animation/rolling_digit.dart';
import '../../../../core/data/shopping_repository.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../models/frequent_item_suggestion.dart';
import '../../../../models/shopping_item.dart';
import '../../../../models/shopping_session.dart';
import '../../../../services/frequent_items_service.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/shopping_item_tile.dart';

class HomePage extends StatefulWidget {
  final DateTime? sessionDate;
  final VoidCallback? onBackToHistory;
  final FrequentItemSuggestion? initialNewItemSuggestion;

  const HomePage({
    super.key,
    this.sessionDate,
    this.onBackToHistory,
    this.initialNewItemSuggestion,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ShoppingSession _currentSession;
  final ShoppingRepository _repository = LocalShoppingRepository();
  late final FrequentItemsService _frequentItemsService;
  List<FrequentItemSuggestion> _frequentSuggestions = [];
  bool _isLoading = true;
  late final ScrollController _scrollController;
  bool _isFabExpanded = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    _frequentItemsService = FrequentItemsService(_repository);
    _loadSession().then((_) {
      if (widget.initialNewItemSuggestion != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openAddSheet(suggestion: widget.initialNewItemSuggestion);
        });
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isFabExpanded) {
        setState(() => _isFabExpanded = false);
      }
    } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
      if (!_isFabExpanded) {
        setState(() => _isFabExpanded = true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final date = widget.sessionDate ?? DateTime.now();
    final session = await _repository.getSessionByDate(date);
    if (mounted) {
      setState(() {
        _currentSession = session;
        _isLoading = false;
      });
      await _refreshFrequentSuggestions();
    }
  }

  Future<void> _openAddSheet({FrequentItemSuggestion? suggestion}) async {
    final newItem = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemSheet(
        nextPosition: _currentSession.items.length,
        frequentSuggestions: _frequentSuggestions,
        initialSuggestion: suggestion,
      ),
    );

    if (newItem is ShoppingItem) {
      _addItem(newItem);
    }
  }

  Future<void> _refreshFrequentSuggestions() async {
    final suggestions = await _frequentItemsService.getSuggestions(
      excludeNames: _currentSession.items.map((item) => item.name),
    );
    if (mounted) {
      setState(() {
        _frequentSuggestions = suggestions;
      });
    }
  }

  Future<void> _persistSession() async {
    await _repository.saveSession(_currentSession);
  }

  double get _totalAmount {
    return _currentSession.items
        .where((i) => !i.isPurchased)
        .fold(0.0, (sum, item) => sum + item.pricing.totalPrice);
  }

  double get _purchasedAmount {
    return _currentSession.items
        .where((i) => i.isPurchased)
        .fold(0.0, (sum, item) => sum + item.pricing.totalPrice);
  }

  Future<void> _addItem(ShoppingItem item) async {
    setState(() {
      _currentSession.items.add(item);
    });
    await _persistSession();
    await _refreshFrequentSuggestions();
  }

  Future<void> _quickAddSuggestion(FrequentItemSuggestion suggestion) async {
    await _addItem(
      suggestion.toNewItem(position: _currentSession.items.length),
    );
  }

  Future<void> _updateItem(ShoppingItem updatedItem) async {
    final index = _currentSession.items.indexWhere((it) => it.id == updatedItem.id);
    if (index != -1) {
      setState(() {
        _currentSession.items[index] = updatedItem;
      });
      await _persistSession();
    }
  }

  Future<void> _deleteItem(ShoppingItem item) async {
    final index = _currentSession.items.indexOf(item);
    if (index != -1) {
      setState(() {
        _currentSession.items.removeAt(index);
      });
      await _persistSession();

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Item deleted'),
          duration: const Duration(seconds: 4),
          persist: false,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() {
                _currentSession.items.insert(
                    index < _currentSession.items.length ? index : _currentSession.items.length, item);
              });
              _persistSession();
              _refreshFrequentSuggestions();
            },
          ),
        ),
      );
      await _refreshFrequentSuggestions();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String formattedDate = widget.sessionDate != null
        ? DateFormat('EEEE, d MMMM yyyy').format(_currentSession.date)
        : DateFormat('EEEE, d MMMM').format(_currentSession.date);

    final activeItems = _currentSession.items.where((i) => !i.isPurchased).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final purchasedItems = _currentSession.items.where((i) => i.isPurchased).toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final bool hasItems = _currentSession.items.isNotEmpty;
    final bool allPurchased = hasItems && activeItems.isEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        if (!hasItems && widget.onBackToHistory != null) {
          final shouldDiscard = await _showDiscardWarning();
          if (shouldDiscard && mounted) {
            widget.onBackToHistory!();
          }
        } else {
          if (widget.onBackToHistory != null) {
            widget.onBackToHistory!();
          } else {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: widget.onBackToHistory != null
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () async {
                    if (!hasItems) {
                      final shouldDiscard = await _showDiscardWarning();
                      if (shouldDiscard && mounted) {
                        widget.onBackToHistory!();
                      }
                    } else {
                      widget.onBackToHistory!();
                    }
                  },
                ),
                title: Text(_currentSession.isToday ? 'Today' : DateFormat('d MMM').format(_currentSession.date)),
                centerTitle: true,
              )
            : null,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(formattedDate),
              if (_frequentSuggestions.isNotEmpty)
                _buildFrequentSuggestionsRow(),

              // Content Area
              Expanded(
                child: !hasItems
                    ? _buildEmptyState()
                    : ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          if (allPurchased)
                            _buildCompletedState(),

                          // To Buy Section
                          if (activeItems.isNotEmpty) ...[
                            _buildSectionLabel(
                              'To Buy',
                              Icons.shopping_cart_outlined,
                              activeItems.length,
                            ),
                            const SizedBox(height: 12),
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activeItems.length,
                              // ignore: deprecated_member_use
                              onReorder: (oldIndex, newIndex) =>
                                  _onReorder(activeItems, oldIndex, newIndex),
                              itemBuilder: (context, index) {
                                final item = activeItems[index];
                                return ShoppingItemTile(
                                  key: ValueKey(item.id),
                                  item: item,
                                  index: index,
                                  onToggle: () => _toggleItem(item),
                                  onTap: () => _openEditSheet(item),
                                  onDelete: () => _deleteItem(item),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTotalAmountRow(),
                            const SizedBox(height: 32),
                          ],

                          // Purchased Section
                          if (purchasedItems.isNotEmpty) ...[
                            _buildSectionLabel(
                              'Purchased',
                              Icons.check_circle_outline,
                              purchasedItems.length,
                            ),
                            const SizedBox(height: 12),
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: purchasedItems.length,
                              // ignore: deprecated_member_use
                              onReorder: (oldIndex, newIndex) =>
                                  _onReorder(purchasedItems, oldIndex, newIndex),
                              itemBuilder: (context, index) {
                                final item = purchasedItems[index];
                                return ShoppingItemTile(
                                  key: ValueKey(item.id),
                                  item: item,
                                  index: index,
                                  onToggle: () => _toggleItem(item),
                                  onTap: () => _openEditSheet(item),
                                  onDelete: () => _deleteItem(item),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildPurchasedAmountCard(),
                          ],
                          const SizedBox(height: 100), // FAB Clearance
                        ],
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  Widget _buildHeader(String date) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: Colors.teal[50]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.teal[700]),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.teal[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _currentSession.isToday ? "Today's Shopping" : "Shopping Record",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Stay organized. Shop smarter.",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.shopping_basket_outlined, size: 56, color: Colors.teal[200]),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count items',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFAB() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: _isFabExpanded ? 140 : 56,
      height: 56,
      child: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(),
        isExtended: _isFabExpanded,
        icon: const Icon(Icons.add),
        label: _isFabExpanded ? const Text('Add Item') : const SizedBox.shrink(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }

  Future<bool> _showDiscardWarning() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No items added'),
        content: const Text('You must add at least one item for this date to be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay Here'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard & Go Back'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _openEditSheet(ShoppingItem item) async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemSheet(
        nextPosition: _currentSession.items.length,
        initialItem: item,
      ),
    );

    if (result == 'delete') {
      _deleteItem(item);
    } else if (result is ShoppingItem) {
      _updateItem(result);
    }
  }

  void _onReorder(List<ShoppingItem> sectionList, int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = sectionList.removeAt(oldIndex);
      sectionList.insert(newIndex, item);

      // Update positions for the entire section to persist the order
      for (int i = 0; i < sectionList.length; i++) {
        final originalIndex = _currentSession.items.indexWhere((it) => it.id == sectionList[i].id);
        if (originalIndex != -1) {
          _currentSession.items[originalIndex] = _currentSession.items[originalIndex].copyWith(position: i);
        }
      }
    });
    _persistSession();
  }

  void _toggleItem(ShoppingItem item) async {
    final bool becomingPurchased = !item.isPurchased;
    
    // Rule 9: Move future item to today if marked as purchased
    if (becomingPurchased && _currentSession.isFuture) {
      final today = DateTime.now();
      final todaySession = await _repository.getSessionByDate(today);
      
      final movedItem = item.copyWith(isPurchased: true, position: todaySession.items.length);
      
      setState(() {
        _currentSession.items.removeWhere((it) => it.id == item.id);
      });
      await _persistSession();
      
      todaySession.items.add(movedItem);
      await _repository.saveSession(todaySession);
      
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${item.name} moved to Today\'s list'),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    final index = _currentSession.items.indexWhere((it) => it.id == item.id);
    if (index != -1) {
      setState(() {
        _currentSession.items[index] = item.copyWith(isPurchased: !item.isPurchased);
      });
    }
    _persistSession();
  }

  Widget _buildFrequentSuggestionsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Often Bought',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _frequentSuggestions.map((suggestion) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: Text(suggestion.name),
                    onPressed: () => _quickAddSuggestion(suggestion),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              "No items yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap + to add your first item.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedState() {
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.blue),
          const SizedBox(height: 16),
          const Text(
            "Shopping Completed",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            "All items have been purchased.",
            style: TextStyle(color: Colors.blue[700], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmountRow() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Amount',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          RollingDigitText(
            text: NumberFormatter.formatPrice(_totalAmount),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchasedAmountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal[50]?.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.teal.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.teal.withValues(alpha: 0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.teal, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Purchased Amount",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Total of all purchased items",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          RollingDigitText(
            text: NumberFormatter.formatPrice(_purchasedAmount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.teal[700],
            ),
          ),
        ],
      ),
    );
  }
}
