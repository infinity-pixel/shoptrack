import 'package:flutter/material.dart';

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
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 12,
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
                                  avatar: Icon(
                                    Icons.list_alt_outlined,
                                    size: 17,
                                    color: selected
                                        ? palette.onPrimary
                                        : palette.secondary,
                                  ),
                                  label: Text(
                                    '${list.name}  ${widget.itemCountForList(list.id)}',
                                    overflow: TextOverflow.ellipsis,
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
                            Positioned(
                              right: 0,
                              top: 6,
                              bottom: 6,
                              width: 16,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  key: const ValueKey('list-overflow-shadow'),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        palette.onBackground.withValues(
                                          alpha: 0,
                                        ),
                                        palette.onBackground.withValues(
                                          alpha: .10,
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
                  margin: const EdgeInsets.only(left: 2, right: 4),
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
                      tooltip: 'New shopping list',
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
