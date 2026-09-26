import 'package:flutter/material.dart';
import '../../../../core/localization/shoptrack_text.dart';

import '../../../../core/theme/theme_presets.dart';
import '../../../../models/shopping_list_group.dart';

class ShoppingListSwitcher extends StatefulWidget {
  const ShoppingListSwitcher({
    super.key,
    required this.lists,
    required this.activeListId,
    required this.itemCountForList,
    required this.onSelected,
    required this.onCreate,
    required this.onManage,
  });

  final List<ShoppingListGroup> lists;
  final String activeListId;
  final int Function(String listId) itemCountForList;
  final ValueChanged<String> onSelected;
  final VoidCallback onCreate;
  final ValueChanged<ShoppingListGroup> onManage;

  @override
  State<ShoppingListSwitcher> createState() => _ShoppingListSwitcherState();
}

class _ShoppingListSwitcherState extends State<ShoppingListSwitcher> {
  bool _hasMore = false;
  void _updateEdge(ScrollMetrics metrics) {
    final more = metrics.extentAfter > 1;
    if (more == _hasMore) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && more != _hasMore) setState(() => _hasMore = more);
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = ShopTrackThemeTokens.of(context).palette;
    return SizedBox(
      height:
          63 + (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(0, 28),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: NotificationListener<ScrollMetricsNotification>(
                    onNotification: (event) {
                      _updateEdge(event.metrics);
                      return false;
                    },
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (event) {
                        _updateEdge(event.metrics);
                        return false;
                      },
                      child: Stack(
                        children: [
                          ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsetsDirectional.only(
                              start: 16,
                              end: 12,
                              top: 4,
                              bottom: 4,
                            ),
                            itemCount: widget.lists.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final list = widget.lists[index];
                              final selected = list.id == widget.activeListId;
                              return GestureDetector(
                                onLongPress: () => widget.onManage(list),
                                child: ChoiceChip(
                                  selected: selected,
                                  onSelected: (_) => widget.onSelected(list.id),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  labelPadding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.list_alt_outlined,
                                        size: 17,
                                        color: selected
                                            ? palette.onPrimary
                                            : palette.secondary,
                                      ),
                                      const SizedBox(width: 5),
                                      ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              MediaQuery.sizeOf(context).width *
                                              .42,
                                        ),
                                        child: Text(
                                          shopListName(
                                            context,
                                            id: list.id,
                                            name: list.name,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 14,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                        ),
                                        color:
                                            (selected
                                                    ? palette.onPrimary
                                                    : palette.textSecondary)
                                                .withValues(alpha: .45),
                                      ),
                                      Text(
                                        shopNumber(
                                          context,
                                          widget.itemCountForList(list.id),
                                        ),
                                      ),
                                    ],
                                  ),
                                  labelStyle: TextStyle(
                                    color: selected
                                        ? palette.onPrimary
                                        : palette.onBackground,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  selectedColor: palette.secondary,
                                  backgroundColor: palette.surface,
                                  side: BorderSide(color: palette.border),
                                  showCheckmark: false,
                                ),
                              );
                            },
                          ),
                          if (_hasMore)
                            PositionedDirectional(
                              end: 0,
                              top: 6,
                              bottom: 6,
                              width: 12,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  key: const ValueKey('list-overflow-shadow'),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: AlignmentDirectional.centerStart,
                                      end: AlignmentDirectional.centerEnd,
                                      colors: [
                                        Colors.black.withValues(alpha: 0),
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.black.withValues(
                                                alpha: .35,
                                              )
                                            : Colors.black.withValues(
                                                alpha: .12,
                                              ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  key: const ValueKey('new-list-divider'),
                  width: 1.5,
                  height: 32,
                  margin: const EdgeInsetsDirectional.only(start: 2, end: 4),
                  decoration: BoxDecoration(
                    color: palette.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: palette.secondary.withValues(alpha: .035),
                          blurRadius: 7,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: shopTr(context, 'New shopping list'),
                      onPressed: widget.onCreate,
                      icon: Icon(
                        Icons.playlist_add,
                        color: palette.secondary,
                        size: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          SizedBox(height: 3),
          Container(
            key: const ValueKey('list-section-divider'),
            height: 5,
            color: Color.alphaBlend(
              palette.onBackground.withValues(alpha: .035),
              palette.background,
            ),
          ),
          SizedBox(height: 6),
        ],
      ),
    );
  }
}
