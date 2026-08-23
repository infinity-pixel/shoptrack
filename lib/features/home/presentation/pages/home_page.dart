import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../app.dart';
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

  const HomePage({
    super.key,
    this.sessionDate,
    this.onBackToHistory,
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

  @override
  void initState() {
    super.initState();
    _frequentItemsService = FrequentItemsService(_repository);
    _loadSession();
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

      final messenger = ShopTrackApp.scaffoldMessengerKey.currentState;
      if (messenger != null) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Item deleted'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () async {
                messenger.hideCurrentSnackBar();
                setState(() {
                  _currentSession.items.insert(
                      index < _currentSession.items.length ? index : _currentSession.items.length, item);
                });
                await _persistSession();
                await _refreshFrequentSuggestions();
              },
            ),
          ),
        );
      }
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
              // Custom Header (only if not using AppBar)
              if (widget.onBackToHistory == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentSession.isToday ? "Today's Shopping" : "Shopping Record",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              if (_frequentSuggestions.isNotEmpty)
                _buildFrequentSuggestionsRow(),

              // Content Area
              Expanded(
                child: !hasItems
                    ? _buildEmptyState()
                    : ListView(
                        children: [
                          if (allPurchased)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: _buildCompletedState(),
                            ),

                          // Active Items Section
                          if (activeItems.isNotEmpty) ...[
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activeItems.length,
                              // ignore: deprecated_member_use
                              onReorder: (oldIndex, newIndex) =>
                                  _onReorder(activeItems, oldIndex, newIndex),
                              itemBuilder: (context, index) {
                                final item = activeItems[index];
                                return Padding(
                                  key: ValueKey(item.id),
                                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: ShoppingItemTile(
                                    item: item,
                                    index: index,
                                    onToggle: () => _toggleItem(item),
                                    onTap: () => _openEditSheet(item),
                                    onDelete: () => _deleteItem(item),
                                  ),
                                );
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                              child: Column(
                                children: [
                                  const Divider(height: 32),
                                  _buildTotalAmountRow(),
                                ],
                              ),
                            ),
                          ],

                          // Purchased Section
                          if (purchasedItems.isNotEmpty)
                            Container(
                              color: Colors.grey[50], // Edge-to-edge background
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12.0),
                                    child: Text(
                                      'Purchased',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ReorderableListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: purchasedItems.length,
                                    // ignore: deprecated_member_use
                                    onReorder: (oldIndex, newIndex) =>
                                        _onReorder(purchasedItems, oldIndex, newIndex),
                                    itemBuilder: (context, index) {
                                      final item = purchasedItems[index];
                                      return Padding(
                                        key: ValueKey(item.id),
                                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                        child: ShoppingItemTile(
                                          item: item,
                                          index: index,
                                          onToggle: () => _toggleItem(item),
                                          onTap: () => _openEditSheet(item),
                                          onDelete: () => _deleteItem(item),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                    child: _buildPurchasedAmountCard(),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 80), // FAB Clearance
                        ],
                      ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final newItem = await showModalBottomSheet<dynamic>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddItemSheet(
                nextPosition: _currentSession.items.length,
                frequentSuggestions: _frequentSuggestions,
              ),
            );

            if (newItem is ShoppingItem) {
              _addItem(newItem);
            }
          },
          child: const Icon(Icons.add),
        ),
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
      
      final messenger = ShopTrackApp.scaffoldMessengerKey.currentState;
      messenger?.showSnackBar(
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
            'Often bought',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Amount',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            NumberFormatter.formatPrice(_totalAmount),
            style: const TextStyle(
              fontSize: 20,
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
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Purchased Amount",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          Text(
            NumberFormatter.formatPrice(_purchasedAmount),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
