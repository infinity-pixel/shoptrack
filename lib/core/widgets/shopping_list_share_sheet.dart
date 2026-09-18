import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/shopping_list_group.dart';
import '../../models/shopping_session.dart';
import '../utils/shopping_list_text_formatter.dart';
import 'shoptrack_modal.dart';

enum _ShareScope { current, choose, all, selected }

enum _ShareAction { copy, share }

class _ShareRequest {
  const _ShareRequest({
    required this.action,
    this.listIds,
    this.itemIds,
    this.selectedItems = false,
  });

  final _ShareAction action;
  final Set<String>? listIds;
  final Set<String>? itemIds;
  final bool selectedItems;
}

Future<void> showShoppingListShareSheet(
  BuildContext context,
  ShoppingSession session, {
  String? currentListId,
  Set<String> selectedItemIds = const {},
  bool preferSelectedItems = false,
}) async {
  if (session.items.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add an item before sharing this list.')),
    );
    return;
  }

  final request = await showModalBottomSheet<_ShareRequest>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _ShoppingListShareSheet(
      session: session,
      currentListId: currentListId,
      selectedItemIds: selectedItemIds,
      preferSelectedItems: preferSelectedItems,
    ),
  );
  if (!context.mounted || request == null) return;

  final text = ShoppingListTextFormatter.format(
    session,
    listIds: request.listIds,
    itemIds: request.itemIds,
    selectedItems: request.selectedItems,
  );
  try {
    if (request.action == _ShareAction.copy) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Shopping list copied.')));
      }
    } else {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject:
              'ShopTrack — ${DateFormat('d MMMM yyyy').format(session.date)}',
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            request.action == _ShareAction.copy
                ? 'Could not copy this list. Please try again.'
                : 'Could not share this list. Please try again.',
          ),
        ),
      );
    }
  }
}

class _ShoppingListShareSheet extends StatefulWidget {
  const _ShoppingListShareSheet({
    required this.session,
    required this.currentListId,
    required this.selectedItemIds,
    required this.preferSelectedItems,
  });

  final ShoppingSession session;
  final String? currentListId;
  final Set<String> selectedItemIds;
  final bool preferSelectedItems;

  @override
  State<_ShoppingListShareSheet> createState() =>
      _ShoppingListShareSheetState();
}

class _ShoppingListShareSheetState extends State<_ShoppingListShareSheet> {
  late _ShareScope _scope;
  late Set<String> _chosenListIds;

  List<ShoppingListGroup> get _nonEmptyLists => widget.session.orderedLists
      .where((list) => widget.session.itemsForList(list.id).isNotEmpty)
      .toList(growable: false);

  ShoppingListGroup? get _currentList {
    for (final list in _nonEmptyLists) {
      if (list.id == widget.currentListId) return list;
    }
    return null;
  }

  Set<String> get _validSelectedItemIds {
    final validIds = widget.session.items.map((item) => item.id).toSet();
    return widget.selectedItemIds.intersection(validIds);
  }

  @override
  void initState() {
    super.initState();
    final current = _currentList;
    _chosenListIds = {if (current != null) current.id};
    if (_chosenListIds.isEmpty && _nonEmptyLists.isNotEmpty) {
      _chosenListIds.add(_nonEmptyLists.first.id);
    }
    _scope = widget.preferSelectedItems && _validSelectedItemIds.isNotEmpty
        ? _ShareScope.selected
        : current != null
        ? _ShareScope.current
        : _ShareScope.all;
  }

  Set<String>? get _listIds {
    return switch (_scope) {
      _ShareScope.current => {_currentList!.id},
      _ShareScope.choose => _chosenListIds,
      _ShareScope.all || _ShareScope.selected => null,
    };
  }

  Set<String>? get _itemIds =>
      _scope == _ShareScope.selected ? _validSelectedItemIds : null;

  bool get _canExport =>
      _scope != _ShareScope.choose || _chosenListIds.isNotEmpty;

  String get _preview => ShoppingListTextFormatter.format(
    widget.session,
    listIds: _listIds,
    itemIds: _itemIds,
    selectedItems: _scope == _ShareScope.selected,
  );

  void _finish(_ShareAction action) {
    if (!_canExport) return;
    Navigator.pop(
      context,
      _ShareRequest(
        action: action,
        listIds: _listIds == null ? null : Set.unmodifiable(_listIds!),
        itemIds: _itemIds == null ? null : Set.unmodifiable(_itemIds!),
        selectedItems: _scope == _ShareScope.selected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShopTrackSheetHeader(
              title: 'Copy or Share',
              subtitle: DateFormat(
                'EEEE, d MMMM yyyy',
              ).format(widget.session.date),
              onClose: () => Navigator.pop(context),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Choose what to include',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RadioGroup<_ShareScope>(
                      groupValue: _scope,
                      onChanged: (scope) {
                        if (scope != null) setState(() => _scope = scope);
                      },
                      child: Column(
                        children: [
                          if (_currentList case final current?)
                            _scopeTile(
                              value: _ShareScope.current,
                              icon: Icons.checklist_rounded,
                              title: 'Current List',
                              subtitle: current.name,
                            ),
                          if (_nonEmptyLists.length > 1)
                            _scopeTile(
                              value: _ShareScope.choose,
                              icon: Icons.library_add_check_outlined,
                              title: 'Choose Lists',
                              subtitle: 'Select one or more lists',
                            ),
                          _scopeTile(
                            value: _ShareScope.all,
                            icon: Icons.select_all_rounded,
                            title: 'All Lists',
                            subtitle:
                                '${_nonEmptyLists.length} ${_nonEmptyLists.length == 1 ? 'list' : 'lists'}',
                          ),
                          if (_validSelectedItemIds.isNotEmpty)
                            _scopeTile(
                              value: _ShareScope.selected,
                              icon: Icons.done_all_rounded,
                              title: 'Selected Items',
                              subtitle:
                                  '${_validSelectedItemIds.length} ${_validSelectedItemIds.length == 1 ? 'item' : 'items'}',
                            ),
                        ],
                      ),
                    ),
                    if (_scope == _ShareScope.choose) ...[
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            for (final list in _nonEmptyLists)
                              CheckboxListTile(
                                dense: true,
                                value: _chosenListIds.contains(list.id),
                                title: Text(list.name),
                                subtitle: Text(
                                  '${widget.session.itemsForList(list.id).length} ${widget.session.itemsForList(list.id).length == 1 ? 'item' : 'items'}',
                                ),
                                onChanged: (checked) => setState(() {
                                  if (checked ?? false) {
                                    _chosenListIds.add(list.id);
                                  } else {
                                    _chosenListIds.remove(list.id);
                                  }
                                }),
                              ),
                          ],
                        ),
                      ),
                      if (_chosenListIds.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                          child: Text(
                            'Select at least one list.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.error,
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Preview',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _preview,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.45,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _canExport
                          ? () => _finish(_ShareAction.copy)
                          : null,
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Copy Text'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _canExport
                          ? () => _finish(_ShareAction.share)
                          : null,
                      icon: const Icon(Icons.ios_share_outlined),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scopeTile({
    required _ShareScope value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return RadioListTile<_ShareScope>(
      dense: true,
      value: value,
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
