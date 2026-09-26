import 'package:flutter/material.dart';
import 'package:shoptrack/core/localization/shoptrack_text.dart';
import 'package:flutter/services.dart';
import '../calendar/shop_calendar.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/shopping_list_group.dart';
import '../../models/shopping_session.dart';
import '../utils/shopping_list_text_formatter.dart';
import 'shoptrack_modal.dart';

enum _ShareAction { copy, share }

class _ShareRequest {
  const _ShareRequest({
    required this.action,
    required this.listIds,
    required this.itemIds,
    required this.selectedItems,
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
      const SnackBar(
        content: ShopText('Add an item before sharing this list.'),
      ),
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
    translate: (value) => shopTr(context, value),
    defaultListLabel: shopTr(context, 'My List'),
    formatCount: (value) => shopNumber(context, value),
    dateLabel: shopDate(context, session.date, 'EEEE, d MMMM yyyy'),
    formatNumberText: (value) =>
        shopIsArabic(context) ? shopDigits(context, value) : value,
  );
  try {
    if (request.action == _ShareAction.copy) {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: ShopText('Shopping list copied.')),
        );
      }
    } else {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject:
              'ShopTrack — ${shopDate(context, session.date, 'd MMMM yyyy')}',
        ),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ShopText(
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
  late final List<ShoppingListGroup> _availableLists;
  late final Set<String> _validSelectedItemIds;
  late final bool _selectedItemsOnly;
  late Set<String> _chosenListIds;

  @override
  void initState() {
    super.initState();
    _availableLists = widget.session.orderedLists
        .where((list) => widget.session.itemsForList(list.id).isNotEmpty)
        .toList(growable: false);
    final validItemIds = widget.session.items.map((item) => item.id).toSet();
    _validSelectedItemIds = widget.selectedItemIds.intersection(validItemIds);
    _selectedItemsOnly =
        widget.preferSelectedItems && _validSelectedItemIds.isNotEmpty;

    final currentIsAvailable = _availableLists.any(
      (list) => list.id == widget.currentListId,
    );
    _chosenListIds = currentIsAvailable
        ? {widget.currentListId!}
        : _availableLists.map((list) => list.id).toSet();
  }

  bool get _allChosen =>
      _chosenListIds.length == _availableLists.length &&
      _availableLists.isNotEmpty;

  bool get _canExport => _selectedItemsOnly || _chosenListIds.isNotEmpty;

  void _finish(_ShareAction action) {
    if (!_canExport) return;
    Navigator.pop(
      context,
      _ShareRequest(
        action: action,
        listIds: _selectedItemsOnly ? null : Set.unmodifiable(_chosenListIds),
        itemIds: _selectedItemsOnly
            ? Set.unmodifiable(_validSelectedItemIds)
            : null,
        selectedItems: _selectedItemsOnly,
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
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShopTrackSheetHeader(
              title: _selectedItemsOnly
                  ? 'Share Selected Items'
                  : 'Share Your List',
              subtitle: shopDate(
                context,
                widget.session.date,
                'EEEE, d MMMM yyyy',
              ),
              onClose: () => Navigator.pop(context),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _selectedItemsOnly
                    ? _selectedSummary(theme, colors)
                    : _listChooser(theme, colors),
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
                      label: const ShopText('Copy Text'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _canExport
                          ? () => _finish(_ShareAction.share)
                          : null,
                      icon: const Icon(Icons.ios_share_outlined),
                      label: const ShopText('Share'),
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

  Widget _selectedSummary(ThemeData theme, ColorScheme colors) {
    final count = _validSelectedItemIds.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.done_all_rounded, color: colors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              shopTr(
                context,
                count == 1 ? '{count} selected item' : '{count} selected items',
              ).replaceAll('{count}', shopNumber(context, count)),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listChooser(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShopText(
          'Choose one or more lists',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: colors.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colors.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              if (_availableLists.length > 1) ...[
                CheckboxListTile(
                  dense: true,
                  value: _allChosen,
                  title: const ShopText('All Lists'),
                  subtitle: Text(
                    shopCount(
                      context,
                      _availableLists.length,
                      singular: 'list',
                      plural: 'lists',
                    ),
                  ),
                  secondary: const Icon(Icons.select_all_rounded),
                  onChanged: (checked) => setState(() {
                    _chosenListIds = checked ?? false
                        ? _availableLists.map((list) => list.id).toSet()
                        : <String>{};
                  }),
                ),
                Divider(height: 1, color: colors.outlineVariant),
              ],
              for (var index = 0; index < _availableLists.length; index++) ...[
                Builder(
                  builder: (context) {
                    final list = _availableLists[index];
                    final count = widget.session.itemsForList(list.id).length;
                    return CheckboxListTile(
                      dense: true,
                      value: _chosenListIds.contains(list.id),
                      title: Text(
                        shopListName(context, id: list.id, name: list.name),
                      ),
                      subtitle: Text(
                        shopCount(
                          context,
                          count,
                          singular: 'item',
                          plural: 'items',
                        ),
                      ),
                      secondary: const Icon(Icons.checklist_rounded),
                      onChanged: (checked) => setState(() {
                        if (checked ?? false) {
                          _chosenListIds.add(list.id);
                        } else {
                          _chosenListIds.remove(list.id);
                        }
                      }),
                    );
                  },
                ),
                if (index != _availableLists.length - 1)
                  Divider(height: 1, color: colors.outlineVariant),
              ],
            ],
          ),
        ),
        if (_chosenListIds.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: ShopText(
              'Select at least one list.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
            ),
          ),
      ],
    );
  }
}
