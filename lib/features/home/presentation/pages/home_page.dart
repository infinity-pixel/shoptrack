import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/record_hero.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/animation/rolling_digit.dart';
import '../../../../core/data/shopping_repository.dart';
import '../../../../core/theme/theme_presets.dart';
import '../../../../core/theme/atmospheric_background.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/utils/shopping_session_actions.dart';
import '../../../../core/widgets/scroll_aware_fab.dart';
import '../../../../core/widgets/shopping_list_share_sheet.dart';
import '../../../../core/widgets/shoptrack_modal.dart';
import '../../../../models/frequent_item_suggestion.dart';
import '../../../../models/shopping_item.dart';
import '../../../../models/shopping_list_group.dart';
import '../../../../models/shopping_session.dart';
import '../../../../services/frequent_items_service.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/shopping_item_tile.dart';
import '../widgets/shopping_list_name_dialog.dart';
import '../widgets/shopping_list_switcher.dart';
import '../widgets/item_selection_bar.dart';

class HomePage extends StatefulWidget {
  final DateTime? sessionDate;
  final int refreshRevision;
  final VoidCallback? onBackToHistory;
  final VoidCallback? onMoveToToday;
  final FrequentItemSuggestion? initialNewItemSuggestion;

  const HomePage({
    super.key,
    this.sessionDate,
    this.refreshRevision = 0,
    this.onBackToHistory,
    this.onMoveToToday,
    this.initialNewItemSuggestion,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late ShoppingSession _currentSession;
  final LocalShoppingRepository _repository = LocalShoppingRepository();
  int _saving = 0;
  int _loadRequest = 0;
  int _openEditors = 0;
  bool _selectionMode = false;
  bool _selectionBusy = false;
  bool _hasLoadedSession = false;
  String? _loadError;
  final Set<String> _selectedItemIds = {};
  late final FrequentItemsService _frequentItemsService;
  List<FrequentItemSuggestion> _frequentSuggestions = [];
  bool _isLoading = true;
  late final ScrollController _scrollController;
  late final ScrollAwareFabController _fabController;
  String _activeListId = ShoppingListGroup.defaultId;
  final Set<String> _transitioningItemIds = <String>{};
  final Map<String, bool> _checkmarkTransitionStates = <String, bool>{};
  final Map<String, GlobalKey> _itemKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fabController = ScrollAwareFabController();
    _frequentItemsService = FrequentItemsService(_repository);
    _repository.changes?.addListener(_onShoppingChanged);
    _loadSession().then((_) {
      if (widget.initialNewItemSuggestion != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openAddSheet(suggestion: widget.initialNewItemSuggestion);
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldDate = oldWidget.sessionDate;
    final newDate = widget.sessionDate;
    final didChangeDate =
        oldDate?.year != newDate?.year ||
        oldDate?.month != newDate?.month ||
        oldDate?.day != newDate?.day;

    if (didChangeDate ||
        (oldDate != null && newDate == null) ||
        oldWidget.refreshRevision != widget.refreshRevision) {
      _clearSelection();
      _loadSession();
    }
  }

  @override
  void dispose() {
    _repository.changes?.removeListener(_onShoppingChanged);
    _scrollController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    if (_openEditors > 0) return;
    final request = ++_loadRequest;
    final date = widget.sessionDate ?? DateTime.now();
    try {
      final session = await _repository.getSessionByDate(date);
      if (mounted && request == _loadRequest) {
        setState(() {
          _currentSession = session;
          _hasLoadedSession = true;
          _loadError = null;
          final listIds = session.orderedLists.map((list) => list.id).toSet();
          if (!listIds.contains(_activeListId)) {
            _activeListId = session.orderedLists.first.id;
          }
          _isLoading = false;
        });
        await _refreshFrequentSuggestions();
      }
    } catch (_) {
      if (!mounted || request != _loadRequest) return;
      setState(() {
        _loadError =
            'Could not open this shopping list. Your data is still on this device.';
        _isLoading = false;
      });
      if (_hasLoadedSession) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_loadError!)));
      }
    }
  }

  Future<void> _withStableEditor(Future<void> Function() edit) async {
    if (!mounted) return;
    _openEditors++;
    _loadRequest++;
    try {
      await edit();
    } finally {
      _openEditors--;
      if (mounted && _openEditors == 0) await _loadSession();
    }
  }

  void _selectItem(ShoppingItem item) {
    if (_selectionBusy ||
        _saving > 0 ||
        _transitioningItemIds.isNotEmpty ||
        _checkmarkTransitionStates.isNotEmpty) {
      return;
    }
    setState(() {
      if (!_selectionMode) {
        _selectionMode = true;
        // Keep the repository baseline from when selection began, just as an
        // open item editor does. Remote changes will be merged at save time.
        _openEditors++;
        _loadRequest++;
      }
      if (!_selectedItemIds.add(item.id)) _selectedItemIds.remove(item.id);
    });
  }

  void _clearSelection() {
    if (_selectionMode) _openEditors--;
    _selectionMode = false;
    _selectedItemIds.clear();
  }

  void _cancelSelection() {
    if (_selectionBusy) return;
    setState(_clearSelection);
    _loadSession();
  }

  Future<void> _saveSelection(
    ShoppingSession updated,
    String message, {
    Future<void> Function()? onUndo,
  }) async {
    setState(() => _selectionBusy = true);
    _saving++;
    _loadRequest++;
    try {
      final conflictsBefore = _repository.conflictCount;
      await _repository.saveSession(updated);
      if (!mounted) return;
      final conflicted = _repository.conflictCount > conflictsBefore;
      setState(_clearSelection);
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            conflicted
                ? 'This record changed elsewhere. Both versions are kept; review them in Profile → Cloud Sync.'
                : message,
          ),
          duration: const Duration(seconds: 5),
          persist: false,
          action: conflicted || onUndo == null
              ? null
              : SnackBarAction(label: 'Undo', onPressed: onUndo),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not save this change. Your selection is kept; please try again.',
            ),
          ),
        );
      }
    } finally {
      _saving--;
      if (mounted) {
        setState(() => _selectionBusy = false);
        await _loadSession();
      }
    }
  }

  Future<void> _moveSelection() async {
    final destinations = _currentSession.orderedLists
        .where((list) => list.id != _activeListId)
        .toList();
    final choice = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShopTrackSheetHeader(
                title: 'Move to List',
                subtitle: 'Choose where the selected items should go.',
                onClose: () => Navigator.pop(context),
              ),
              if (destinations.isEmpty)
                Flexible(
                  child: SingleChildScrollView(
                    child: ShopTrackSheetEmptyState(
                      icon: Icons.playlist_add_outlined,
                      title: 'No other lists yet',
                      message:
                          'Create another list, then move these items into it.',
                      actionLabel: 'Create List',
                      onAction: () => Navigator.pop(context, 'create'),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    itemCount: destinations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final list = destinations[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: const Icon(Icons.checklist_rounded),
                        title: Text(list.name),
                        subtitle: Text(
                          '${_currentSession.itemsForList(list.id).length} ${_currentSession.itemsForList(list.id).length == 1 ? 'item' : 'items'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, list),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null || !_selectionMode) return;
    ShoppingListGroup target;
    var sessionForMove = _currentSession;
    if (choice == 'create') {
      final name = await showDialog<String>(
        context: context,
        builder: (_) => const ShoppingListNameDialog(
          title: 'New shopping list',
          actionLabel: 'Create',
          hintText: 'e.g. Household',
        ),
      );
      if (!mounted || name == null || name.isEmpty || !_selectionMode) return;
      if (_currentSession.orderedLists.any(
        (list) => list.name.toLowerCase() == name.toLowerCase(),
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A list with that name already exists.'),
          ),
        );
        return;
      }
      target = ShoppingListGroup(
        id: const Uuid().v4(),
        name: name,
        position: _currentSession.orderedLists.length,
      );
      sessionForMove = _currentSession.copyWith(
        lists: [..._currentSession.orderedLists, target],
      );
    } else {
      target = choice as ShoppingListGroup;
    }
    final count = _selectedItemIds.length;
    if (!await _confirmSelectionAction(
          'Move $count ${count == 1 ? 'item' : 'items'}?',
          'Move the selected ${count == 1 ? 'item' : 'items'} to ${target.name}?',
          'Move',
        ) ||
        !mounted ||
        !_selectionMode) {
      return;
    }
    final originals = _currentSession.items
        .where((item) => _selectedItemIds.contains(item.id))
        .toList();
    final date = _currentSession.date;
    final updated = ShoppingSessionActions.move(
      sessionForMove,
      sourceListId: _activeListId,
      destinationListId: target.id,
      ids: _selectedItemIds,
    );
    await _saveSelection(
      updated,
      'Moved $count ${count == 1 ? 'item' : 'items'} to ${target.name}.',
      onUndo: () => _undoMove(date, originals, updated),
    );
  }

  Future<bool> _confirmSelectionAction(
    String title,
    String message,
    String action,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            scrollable: true,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(action),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _undoMove(
    DateTime date,
    List<ShoppingItem> originals,
    ShoppingSession moved,
  ) async {
    if (!mounted) return;
    _saving++;
    _loadRequest++;
    try {
      final latest = await _repository.getSessionByDate(date);
      final beforeConflicts = _repository.conflictCount;
      await _repository.saveSession(
        ShoppingSessionActions.undoMove(
          latest,
          originals: originals,
          moved: moved,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _repository.conflictCount > beforeConflicts
                ? 'This record changed elsewhere. Review changes in Profile → Cloud Sync.'
                : 'Move undone.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not undo the move. The items or lists may have changed; your latest data is kept.',
            ),
          ),
        );
      }
    } finally {
      _saving--;
      if (mounted) await _loadSession();
    }
  }

  Future<void> _deleteSelection() async {
    final count = _selectedItemIds.length;
    if (count == 0) return;
    if (!await _confirmSelectionAction(
          'Delete $count ${count == 1 ? 'item' : 'items'}?',
          'Remove the selected ${count == 1 ? 'item' : 'items'} from this list?',
          'Delete',
        ) ||
        !mounted ||
        !_selectionMode) {
      return;
    }
    final deletedItems = _currentSession
        .itemsForList(_activeListId)
        .where((item) => _selectedItemIds.contains(item.id))
        .toList(growable: false);
    await _saveSelection(
      ShoppingSessionActions.delete(
        _currentSession,
        sourceListId: _activeListId,
        ids: _selectedItemIds,
      ),
      'Deleted $count ${count == 1 ? 'item' : 'items'}.',
      onUndo: () => _restoreDeletedItems(deletedItems),
    );
  }

  Future<void> _restoreDeletedItems(List<ShoppingItem> deletedItems) async {
    if (deletedItems.isEmpty) return;
    _saving++;
    _loadRequest++;
    try {
      final latest = await _repository.getSessionByDate(_currentSession.date);
      final availableLists = latest.orderedLists.map((list) => list.id).toSet();
      final existingIds = latest.items.map((item) => item.id).toSet();
      final restorable = deletedItems
          .where((item) {
            final listId = item.listId ?? ShoppingListGroup.defaultId;
            return !existingIds.contains(item.id) &&
                availableLists.contains(listId);
          })
          .toList(growable: false);
      if (restorable.length != deletedItems.length) {
        throw StateError('The original list or items changed.');
      }
      await _repository.saveSession(
        latest.copyWith(items: [...latest.items, ...restorable]),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restored ${restorable.length} ${restorable.length == 1 ? 'item' : 'items'}.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not undo the deletion because this list changed. Your latest data is kept.',
            ),
          ),
        );
      }
    } finally {
      _saving--;
      if (mounted) await _loadSession();
    }
  }

  Widget _selectionBar() => ItemSelectionBar(
    count: _selectedItemIds.length,
    allSelected: _selectedItemIds.length == _activeItems.length,
    busy: _selectionBusy,
    onClose: _cancelSelection,
    onSelectAll: () => setState(() {
      if (_selectedItemIds.length == _activeItems.length) {
        _selectedItemIds.clear();
      } else {
        _selectedItemIds.addAll(_activeItems.map((item) => item.id));
      }
    }),
    onShare: () => showShoppingListShareSheet(
      context,
      _currentSession,
      currentListId: _activeListId,
      selectedItemIds: Set.unmodifiable(_selectedItemIds),
      preferSelectedItems: true,
    ),
    onMove: _moveSelection,
    onDelete: _deleteSelection,
  );

  Widget _shoppingTile(ShoppingItem item, int index) => ShoppingItemTile(
    item: item,
    index: index,
    visualPurchased: _checkmarkTransitionStates[item.id],
    selectionMode: _selectionMode,
    selected: _selectedItemIds.contains(item.id),
    onLongPress: () => _selectItem(item),
    onToggle: () => _selectionMode ? _selectItem(item) : _toggleItem(item),
    onTap: () => _selectionMode ? _selectItem(item) : _openEditSheet(item),
    onDelete: () => _deleteItem(item),
  );

  Future<void> _openAddSheet({FrequentItemSuggestion? suggestion}) =>
      _withStableEditor(() async {
        final newItem = await showModalBottomSheet<dynamic>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AddItemSheet(
            nextPosition:
                _activeItems.fold<int>(
                  -1,
                  (last, item) => item.position > last ? item.position : last,
                ) +
                1,
            frequentSuggestions: _frequentSuggestions,
            initialSuggestion: suggestion,
            onRemoveFrequentSuggestion: _dismissFrequentSuggestion,
          ),
        );

        if (mounted && newItem is ShoppingItem) {
          await _addItem(newItem);
        }
      });

  Future<void> _refreshFrequentSuggestions() async {
    final suggestions = await _frequentItemsService.getSuggestions(
      excludeNames: _activeItems.map((item) => item.name),
    );
    if (mounted) {
      setState(() {
        _frequentSuggestions = suggestions;
      });
    }
  }

  Future<void> _persistSession() async {
    _saving++;
    _loadRequest++;
    try {
      final conflictsBefore = _repository.conflictCount;
      await _repository.saveSession(_currentSession);
      if (mounted && _repository.conflictCount > conflictsBefore) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This record changed elsewhere. Both versions are kept; review them in Profile → Cloud Sync.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save this change. Please try again.'),
          ),
        );
      }
    } finally {
      _saving--;
      if (mounted && _saving == 0) await _loadSession();
    }
  }

  void _onShoppingChanged() {
    if (!mounted ||
        _openEditors > 0 ||
        _saving > 0 ||
        _transitioningItemIds.isNotEmpty ||
        _checkmarkTransitionStates.isNotEmpty) {
      return;
    }
    _loadSession();
  }

  double get _totalAmount {
    return _activeItems
        .where((i) => !i.isPurchased)
        .fold(0.0, (sum, item) => sum + item.pricing.totalPrice);
  }

  double get _purchasedAmount {
    return _activeItems
        .where((i) => i.isPurchased)
        .fold(0.0, (sum, item) => sum + item.pricing.totalPrice);
  }

  Future<void> _addItem(ShoppingItem item) async {
    setState(() {
      _currentSession.items.add(item.copyWith(listId: _activeListId));
    });
    await _persistSession();
    await _refreshFrequentSuggestions();
  }

  List<ShoppingItem> get _activeItems =>
      _currentSession.itemsForList(_activeListId);

  Future<void> _dismissFrequentSuggestion(
    FrequentItemSuggestion suggestion,
  ) async {
    await _frequentItemsService.dismissSuggestion(suggestion.name);
    await _refreshFrequentSuggestions();
  }

  Future<void> _updateItem(ShoppingItem updatedItem) async {
    final index = _currentSession.items.indexWhere(
      (it) => it.id == updatedItem.id,
    );
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
              if (!mounted) return;
              setState(() {
                _currentSession.items.insert(
                  index < _currentSession.items.length
                      ? index
                      : _currentSession.items.length,
                  item,
                );
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
    if (!_hasLoadedSession) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 42),
                  const SizedBox(height: 12),
                  Text(
                    _loadError ?? 'Could not open this shopping list.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() => _isLoading = true);
                      _loadSession();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final String formattedDate = widget.sessionDate != null
        ? DateFormat('EEEE, d MMMM yyyy').format(_currentSession.date)
        : DateFormat('EEEE, d MMMM').format(_currentSession.date);

    final activeListItems = _activeItems;
    final activeItems = activeListItems.where((i) => !i.isPurchased).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final purchasedItems = activeListItems.where((i) => i.isPurchased).toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final bool hasItems = _currentSession.items.isNotEmpty;
    final bool hasActiveListItems = activeListItems.isNotEmpty;
    final bool allPurchased = hasActiveListItems && activeItems.isEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_selectionMode) {
          _cancelSelection();
          return;
        }

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
        appBar: widget.onBackToHistory != null && _currentSession.isToday
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () async {
                    if (_selectionMode) {
                      _cancelSelection();
                      return;
                    }
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
                title: Text(
                  _currentSession.isToday
                      ? 'Today'
                      : DateFormat('d MMM').format(_currentSession.date),
                ),
                centerTitle: true,
              )
            : null,
        body: Container(
          decoration: BoxDecoration(
            gradient: Theme.of(context).brightness == Brightness.dark
                ? darkEdgeGradient(context)
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(
                        ShopTrackThemeTokens.of(context).palette.background,
                        ShopTrackThemeTokens.of(context).palette.primary,
                        0.16,
                      )!,
                      ShopTrackThemeTokens.of(context).palette.background,
                      Color.lerp(
                        ShopTrackThemeTokens.of(context).palette.background,
                        ShopTrackThemeTokens.of(context).palette.primary,
                        0.16,
                      )!,
                    ],
                    stops: [0, 0.5, 1],
                  ),
          ),
          child: SafeArea(
            top: widget.onBackToHistory != null && _currentSession.isToday,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_currentSession.isToday && widget.onBackToHistory != null)
                  RecordHero(
                    date: _currentSession.date,
                    onBack: () async {
                      if (_selectionMode) {
                        _cancelSelection();
                        return;
                      }
                      if (!hasItems) {
                        final discard = await _showDiscardWarning();
                        if (!discard || !mounted) return;
                      }
                      widget.onBackToHistory!();
                    },
                  )
                else
                  _buildHeader(formattedDate),
                _buildListSwitcher(),
                // Content Area
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _fabController.handleNotification,
                    child: !hasActiveListItems
                        ? _buildEmptyState()
                        : ListView(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              if (allPurchased) _buildCompletedState(),

                              // To Buy Section
                              if (activeItems.isNotEmpty) ...[
                                _buildSectionLabel(
                                  'To Buy',
                                  Icons.shopping_cart_outlined,
                                  activeItems.length,
                                ),
                                const SizedBox(height: 8),
                                ReorderableListView.builder(
                                  buildDefaultDragHandles: false,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: activeItems.length,
                                  proxyDecorator: _buildReorderProxy,
                                  // ignore: deprecated_member_use
                                  onReorder: (oldIndex, newIndex) => _onReorder(
                                    activeItems,
                                    oldIndex,
                                    newIndex,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = activeItems[index];
                                    return KeyedSubtree(
                                      key: _itemKey(item.id),
                                      child: Opacity(
                                        opacity:
                                            _transitioningItemIds.contains(
                                              item.id,
                                            )
                                            ? 0
                                            : 1,
                                        child: _shoppingTile(item, index),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildTotalAmountRow(),
                                const SizedBox(height: 28),
                              ],

                              // Purchased Section
                              if (purchasedItems.isNotEmpty) ...[
                                _buildSectionLabel(
                                  'Purchased',
                                  Icons.check_circle_outline,
                                  purchasedItems.length,
                                ),
                                const SizedBox(height: 8),
                                ReorderableListView.builder(
                                  buildDefaultDragHandles: false,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: purchasedItems.length,
                                  proxyDecorator: _buildReorderProxy,
                                  // ignore: deprecated_member_use
                                  onReorder: (oldIndex, newIndex) => _onReorder(
                                    purchasedItems,
                                    oldIndex,
                                    newIndex,
                                  ),
                                  itemBuilder: (context, index) {
                                    final item = purchasedItems[index];
                                    return KeyedSubtree(
                                      key: _itemKey(item.id),
                                      child: Opacity(
                                        opacity:
                                            _transitioningItemIds.contains(
                                              item.id,
                                            )
                                            ? 0
                                            : 1,
                                        child: _shoppingTile(item, index),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 20),
                                _buildPurchasedAmountCard(),
                              ],
                              const SizedBox(height: 100), // FAB Clearance
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: _selectionMode ? _selectionBar() : _buildFAB(),
        floatingActionButtonLocation: _selectionMode
            ? FloatingActionButtonLocation.centerFloat
            : FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildHeader(String date) {
    final tokens = ShopTrackThemeTokens.of(context);
    final palette = tokens.palette;
    final isCompactWidth = MediaQuery.sizeOf(context).width < 360;
    final topInset = MediaQuery.paddingOf(context).top;
    final useDarkStatusIcons = palette.surface.computeLuminance() > 0.5;
    final contentHeight =
        (isCompactWidth ? 116.0 : 126.0) +
        (MediaQuery.textScalerOf(context).scale(24) - 24).clamp(0, 70);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: useDarkStatusIcons
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: useDarkStatusIcons
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Container(
        key: const ValueKey('today-shopping-hero'),
        height: topInset + contentHeight,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          key: const ValueKey('today-shopping-hero-surface'),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(23),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (tokens.headerArtworkPath != null)
                Image.asset(
                  tokens.headerArtworkPath!,
                  fit: BoxFit.cover,
                  alignment: useDarkStatusIcons
                      ? Alignment.center
                      : const Alignment(0, -0.5),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      palette.surface.withValues(
                        alpha: useDarkStatusIcons ? 0.90 : 0.45,
                      ),
                      palette.surface.withValues(
                        alpha: useDarkStatusIcons ? 0.58 : 0.20,
                      ),
                      palette.surface.withValues(
                        alpha: useDarkStatusIcons ? 0.12 : 0,
                      ),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentSession.isToday)
                      Row(
                        children: [
                          Icon(
                            Icons.today_outlined,
                            size: 17,
                            color: palette.secondary,
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 2,
                            height: 24,
                            decoration: BoxDecoration(
                              color: palette.secondary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: palette.secondary,
                                fontSize: isCompactWidth ? 13 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    if (_currentSession.isToday) ...[
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: _HeroGradientText(
                          text: "Today's Shopping",
                          style: TextStyle(
                            fontSize: isCompactWidth ? 22 : 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Stay organized. Shop smarter.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ] else
                      _buildRecordDateLockup(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordDateLockup() {
    final palette = ShopTrackThemeTokens.of(context).palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(Icons.event_note_outlined, size: 29, color: palette.secondary),
        const SizedBox(width: 8),
        Container(
          width: 2,
          height: 58,
          decoration: BoxDecoration(
            color: palette.secondary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('EEEE').format(_currentSession.date).toUpperCase(),
              style: TextStyle(
                color: palette.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              DateFormat('d MMM').format(_currentSession.date),
              style: TextStyle(
                color: palette.onBackground,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            Text(
              DateFormat('yyyy').format(_currentSession.date),
              style: TextStyle(color: palette.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label, IconData icon, int count) {
    final palette = ShopTrackThemeTokens.of(context).palette;
    final isPurchased = label == 'Purchased';
    final color = isPurchased ? palette.purchased : palette.secondary;
    return Row(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: palette.onBackground,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (isPurchased ? palette.surfacePurchased : palette.primary)
                .withValues(alpha: isPurchased ? 1 : 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count ${count == 1 ? 'item' : 'items'}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPurchased ? palette.purchased : palette.secondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListSwitcher() {
    return IgnorePointer(
      ignoring: _selectionBusy,
      child: ShoppingListSwitcher(
        lists: _currentSession.orderedLists,
        activeListId: _activeListId,
        itemCountForList: (listId) =>
            _currentSession.itemsForList(listId).length,
        onSelected: (listId) {
          if (listId == _activeListId) return;
          setState(() {
            _clearSelection();
            _activeListId = listId;
          });
          _loadSession();
          _refreshFrequentSuggestions();
        },
        onCreate: () async {
          if (_selectionMode) {
            setState(_clearSelection);
            await _loadSession();
          }
          if (mounted) _createShoppingList();
        },
        onManage: (list) async {
          if (_selectionMode) {
            setState(_clearSelection);
            await _loadSession();
          }
          if (mounted) _showListActions(list);
        },
        onShare: () => showShoppingListShareSheet(
          context,
          _currentSession,
          currentListId: _activeListId,
        ),
      ),
    );
  }

  Future<void> _createShoppingList() => _withStableEditor(() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const ShoppingListNameDialog(
        title: 'New shopping list',
        actionLabel: 'Create',
        hintText: 'e.g. Grandmother',
      ),
    );
    if (!mounted || name == null || name.isEmpty) return;
    if (_currentSession.orderedLists.any(
      (list) => list.name.toLowerCase() == name.toLowerCase(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A list with that name already exists.')),
      );
      return;
    }

    final list = ShoppingListGroup(
      id: const Uuid().v4(),
      name: name,
      position: _currentSession.orderedLists.length,
    );
    setState(() {
      _currentSession = _currentSession.copyWith(
        lists: [..._currentSession.orderedLists, list],
      );
      _activeListId = list.id;
    });
    await _persistSession();
    await _refreshFrequentSuggestions();
  });

  Future<void> _showListActions(ShoppingListGroup list) =>
      _withStableEditor(() async {
        final action = await showModalBottomSheet<String>(
          context: context,
          showDragHandle: true,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShopTrackSheetHeader(
                  title: list.name,
                  subtitle: 'Manage this shopping list.',
                  onClose: () => Navigator.pop(context),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Rename List'),
                  onTap: () => Navigator.pop(context, 'rename'),
                ),
                if (_currentSession.orderedLists.length > 1)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    leading: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      'Delete List',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    onTap: () => Navigator.pop(context, 'delete'),
                  ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
        if (!mounted) return;
        if (action == 'rename') {
          await _renameShoppingList(list);
        } else if (action == 'delete') {
          await _deleteShoppingList(list);
        }
      });

  Future<void> _renameShoppingList(
    ShoppingListGroup list,
  ) => _withStableEditor(() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => ShoppingListNameDialog(
        title: 'Rename shopping list',
        actionLabel: 'Save',
        initialName: list.name,
      ),
    );
    if (!mounted || name == null || name.isEmpty || name == list.name) return;
    if (_currentSession.orderedLists.any(
      (candidate) =>
          candidate.id != list.id &&
          candidate.name.toLowerCase() == name.toLowerCase(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A list with that name already exists.')),
      );
      return;
    }
    setState(() {
      _currentSession = _currentSession.copyWith(
        lists: _currentSession.orderedLists
            .map(
              (candidate) => candidate.id == list.id
                  ? candidate.copyWith(name: name)
                  : candidate,
            )
            .toList(),
      );
    });
    await _persistSession();
  });

  Future<void> _deleteShoppingList(
    ShoppingListGroup list,
  ) => _withStableEditor(() async {
    final itemCount = _currentSession.itemsForList(list.id).length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${list.name}?'),
        content: Text(
          itemCount == 0
              ? 'This empty list will be deleted.'
              : 'This will permanently delete $itemCount ${itemCount == 1 ? 'item' : 'items'} in this list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final remainingLists = _currentSession.orderedLists
        .where((candidate) => candidate.id != list.id)
        .toList();
    setState(() {
      _currentSession.items.removeWhere(
        (item) => (item.listId ?? ShoppingListGroup.defaultId) == list.id,
      );
      _currentSession = _currentSession.copyWith(lists: remainingLists);
      if (_activeListId == list.id) {
        _activeListId = remainingLists.first.id;
      }
    });
    await _persistSession();
    await _refreshFrequentSuggestions();
  });

  Widget _buildFAB() {
    return ListenableBuilder(
      listenable: _fabController,
      builder: (context, _) => DelayedExtendedFab(
        expanded: _fabController.isExpanded,
        onPressed: () => _openAddSheet(),
        icon: const Icon(Icons.add),
        label: 'Add Item',
        tooltip: 'Add item',
      ),
    );
  }

  Future<bool> _showDiscardWarning() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No items added'),
        content: const Text(
          'You must add at least one item for this date to be saved.',
        ),
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

  Future<void> _openEditSheet(ShoppingItem item) => _withStableEditor(() async {
    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemSheet(
        nextPosition: _currentSession.items.length,
        initialItem: item,
      ),
    );

    if (!mounted) return;
    if (result == 'delete') {
      await _deleteItem(item);
    } else if (result is ShoppingItem) {
      await _updateItem(result);
    }
  });

  void _onReorder(List<ShoppingItem> sectionList, int oldIndex, int newIndex) {
    if (_selectionMode) return;
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = sectionList.removeAt(oldIndex);
      sectionList.insert(newIndex, item);

      // Update positions for the entire section to persist the order
      for (int i = 0; i < sectionList.length; i++) {
        final originalIndex = _currentSession.items.indexWhere(
          (it) => it.id == sectionList[i].id,
        );
        if (originalIndex != -1) {
          _currentSession.items[originalIndex] = _currentSession
              .items[originalIndex]
              .copyWith(position: i);
        }
      }
    });
    _persistSession();
  }

  Widget _buildReorderProxy(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    final palette = ShopTrackThemeTokens.of(context).palette;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          elevation: 6 * animation.value,
          shadowColor: palette.onBackground.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: child,
        );
      },
      child: child,
    );
  }

  GlobalKey _itemKey(String itemId) {
    return _itemKeys.putIfAbsent(itemId, GlobalKey.new);
  }

  Future<void> _animateItemTransfer(
    ShoppingItem item,
    bool becomingPurchased,
  ) async {
    final sourceContext = _itemKey(item.id).currentContext;
    final sourceBox = sourceContext?.findRenderObject() as RenderBox?;
    final itemIndex = _currentSession.items.indexWhere(
      (current) => current.id == item.id,
    );
    if (sourceBox == null || itemIndex == -1) {
      if (itemIndex != -1) {
        setState(() {
          _currentSession.items[itemIndex] = item.copyWith(
            isPurchased: becomingPurchased,
          );
          _checkmarkTransitionStates.remove(item.id);
        });
      }
      return;
    }

    final sourcePosition = sourceBox.localToGlobal(Offset.zero);
    final sourceRect = sourcePosition & sourceBox.size;
    final movedItem = item.copyWith(isPurchased: becomingPurchased);

    setState(() {
      _currentSession.items[itemIndex] = movedItem;
      _checkmarkTransitionStates.remove(item.id);
      _transitioningItemIds.add(item.id);
    });

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final targetContext = _itemKey(item.id).currentContext;
    final targetBox = targetContext?.findRenderObject() as RenderBox?;
    if (targetBox == null) {
      setState(() => _transitioningItemIds.remove(item.id));
      return;
    }

    final targetPosition = targetBox.localToGlobal(Offset.zero);
    final targetRect = targetPosition & targetBox.size;
    final controller = AnimationController(
      duration: const Duration(milliseconds: 720),
      vsync: this,
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubicEmphasized,
    );
    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final rect = Rect.lerp(sourceRect, targetRect, animation.value)!;
            return Positioned.fromRect(
              rect: rect,
              child: IgnorePointer(
                child: Material(
                  color: Colors.transparent,
                  child: _ItemFlight(item: movedItem),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(entry);
    await controller.forward();
    entry.remove();
    controller.dispose();
    if (mounted) {
      setState(() => _transitioningItemIds.remove(item.id));
    }
  }

  Future<void> _toggleItem(ShoppingItem item) async {
    if (_transitioningItemIds.contains(item.id) ||
        _checkmarkTransitionStates.containsKey(item.id)) {
      return;
    }
    final bool becomingPurchased = !item.isPurchased;

    // Rule 9: Move future item to today if marked as purchased
    if (becomingPurchased && _currentSession.isFuture) {
      final today = DateTime.now();
      final todaySession = await _repository.getSessionByDate(today);

      final sourceListId = item.listId ?? ShoppingListGroup.defaultId;
      final sourceList = _currentSession.orderedLists.firstWhere(
        (list) => list.id == sourceListId,
        orElse: () => ShoppingListGroup.defaultList,
      );
      final todayLists = List<ShoppingListGroup>.from(
        todaySession.orderedLists,
      );
      if (!todayLists.any((list) => list.id == sourceListId)) {
        todayLists.add(sourceList.copyWith(position: todayLists.length));
      }

      final movedItem = item.copyWith(
        isPurchased: true,
        position: todaySession.items.length,
        listId: sourceListId,
      );

      todaySession.items.add(movedItem);
      _saving++;
      try {
        // Persist both dates together and upload them in one cloud transaction.
        await _repository.saveSessions([
          todaySession.copyWith(lists: todayLists),
          _currentSession.copyWith(
            items: _currentSession.items
                .where((it) => it.id != item.id)
                .toList(),
          ),
        ]);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not move this item. Please try again.'),
            ),
          );
        }
        return;
      } finally {
        _saving--;
        if (mounted) await _loadSession();
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${item.name} moved to Today\'s list'),
          duration: const Duration(seconds: 3),
        ),
      );
      widget.onMoveToToday?.call();
      return;
    }

    final index = _currentSession.items.indexWhere((it) => it.id == item.id);
    if (index == -1) return;

    setState(() {
      _checkmarkTransitionStates[item.id] = becomingPurchased;
    });
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    await _animateItemTransfer(item, becomingPurchased);
    await _persistSession();
  }

  Widget _buildEmptyState() {
    final palette = ShopTrackThemeTokens.of(context).palette;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: palette.surfaceToBuy,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: palette.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              "No items yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: palette.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tap + to add your first item.",
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedState() {
    final palette = ShopTrackThemeTokens.of(context).palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          palette.primary.withValues(alpha: .08),
          palette.surface,
        ),
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: palette.primary),
          const SizedBox(height: 16),
          Text(
            "Shopping Completed",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "All items have been purchased.",
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmountRow() {
    final palette = ShopTrackThemeTokens.of(context).palette;
    return Column(
      children: [
        Divider(color: palette.border, thickness: 1),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 16,
                  color: palette.onBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: RollingDigitText(
                  text: NumberFormatter.formatPrice(_totalAmount),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: palette.onBackground,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPurchasedAmountCard() {
    final palette = ShopTrackThemeTokens.of(context).palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: CustomPaint(
        painter: _ReceiptShadowPainter(palette.receiptShadow),
        child: ClipPath(
          clipper: _ReceiptEdgeClipper(),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [palette.surfaceReceipt, palette.receiptEdge],
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  color: palette.purchased,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchased Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: palette.onBackground,
                        ),
                      ),
                      Text(
                        'Total of all purchased items',
                        style: TextStyle(
                          fontSize: 12,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                RollingDigitText(
                  text: NumberFormatter.formatPrice(_purchasedAmount),
                  style: TextStyle(
                    fontFamily: 'LibreBaskerville',
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.35,
                    color: palette.purchased,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptEdgeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _receiptEdgePath(size);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

Path _receiptEdgePath(Size size) {
  const waveWidths = [22.0, 18.0, 25.0, 20.0, 24.0];
  const waveDepths = [8.0, 11.0, 7.0, 10.0, 8.5];
  final path = Path()..moveTo(0, 0);

  var x = 0.0;
  var waveIndex = 0;
  while (x < size.width) {
    final width = waveWidths[waveIndex % waveWidths.length];
    final depth = waveDepths[waveIndex % waveDepths.length];
    final end = (x + width).clamp(0.0, size.width).toDouble();
    path.cubicTo(
      x + (end - x) * 0.22,
      depth * 0.15,
      x + (end - x) * 0.62,
      depth * 1.18,
      end,
      0,
    );
    x = end;
    waveIndex++;
  }

  path.lineTo(size.width, size.height);
  x = size.width;
  waveIndex = 0;
  while (x > 0) {
    final width = waveWidths[waveIndex % waveWidths.length];
    final depth = waveDepths[waveIndex % waveDepths.length];
    final end = (x - width).clamp(0.0, size.width).toDouble();
    path.cubicTo(
      x - (x - end) * 0.24,
      size.height - depth * 0.12,
      x - (x - end) * 0.64,
      size.height - depth * 1.12,
      end,
      size.height,
    );
    x = end;
    waveIndex++;
  }
  return path..close();
}

class _ReceiptShadowPainter extends CustomPainter {
  final Color shadowColor;

  const _ReceiptShadowPainter(this.shadowColor);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawShadow(_receiptEdgePath(size), shadowColor, 7, false);
  }

  @override
  bool shouldRepaint(covariant _ReceiptShadowPainter oldDelegate) {
    return oldDelegate.shadowColor != shadowColor;
  }
}

class _ItemFlight extends StatelessWidget {
  final ShoppingItem item;

  const _ItemFlight({required this.item});

  @override
  Widget build(BuildContext context) {
    // Match the measured source/destination tile, including text scaling.
    return ShoppingItemTile(
      item: item,
      index: 0,
      onToggle: () {},
      onTap: () {},
      onDelete: () {},
    );
  }
}

class _HeroGradientText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _HeroGradientText({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    final palette = ShopTrackThemeTokens.of(context).palette;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: [palette.onBackground, palette.secondary, palette.primary],
      ).createShader(bounds),
      child: Text(text, style: style),
    );
  }
}
