import 'package:flutter/material.dart';

import '../../../../core/theme/theme_presets.dart';
import '../../../../models/shopping_list_group.dart';

class ShoppingListSwitcher extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final palette = ShopTrackThemeTokens.of(context).palette;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16, right: 6),
              itemCount: lists.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final list = lists[index];
                final selected = list.id == activeListId;
                return GestureDetector(
                  onLongPress: () => onManage(list),
                  child: ChoiceChip(
                    selected: selected,
                    onSelected: (_) => onSelected(list.id),
                    avatar: Icon(
                      Icons.list_alt_outlined,
                      size: 17,
                      color: selected ? palette.onPrimary : palette.secondary,
                    ),
                    label: Text(
                      '${list.name}  ${itemCountForList(list.id)}',
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
          ),
          IconButton(
            onPressed: onCreate,
            tooltip: 'New shopping list',
            icon: Icon(Icons.playlist_add, color: palette.secondary),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
