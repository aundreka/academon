import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/item_inventory_service.dart';
import '../../core/models/item.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/textstyles.dart';
import '../../core/widgets/item/egg.dart';
import '../../core/widgets/item/item.dart';
import '../../core/widgets/item/item_detail.dart';
import '../../core/widgets/ui/topnav.dart';

enum InventorySortMode { name, type }

class InventoryScreen extends StatefulWidget {
  final bool embedded;

  const InventoryScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late final ItemInventoryService _inventoryService;
  late Future<List<OwnedInventoryItem>> _itemsFuture;
  InventorySortMode _sortMode = InventorySortMode.name;

  @override
  void initState() {
    super.initState();
    _inventoryService = ItemInventoryService(Supabase.instance.client);
    _itemsFuture = _inventoryService.fetchOwnedItems();
  }

  @override
  Widget build(BuildContext context) {
    final content = FutureBuilder<List<OwnedInventoryItem>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _InventoryMessageCard(
            title: 'Inventory unavailable',
            body: 'We could not load your items right now.',
            actionLabel: 'Retry',
            onTap: _refresh,
          );
        }

        final items = _sortItems(snapshot.data ?? const <OwnedInventoryItem>[]);
        if (items.isEmpty) {
          return _InventoryMessageCard(
            title: 'No items yet',
            body: 'Buy items from the shop and they will appear here.',
          );
        }

        return _InventoryPanel(
          items: items,
          sortMode: _sortMode,
          onSortChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => _sortMode = value);
          },
          onItemTap: _openItemDetails,
        );
      },
    );

    if (widget.embedded) {
      return content;
    }

    return Column(
      children: [
        const AppTopNav(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: content,
          ),
        ),
      ],
    );
  }

  List<OwnedInventoryItem> _sortItems(List<OwnedInventoryItem> items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      if (_sortMode == InventorySortMode.type) {
        final typeCompare = a.item.itemType.label.compareTo(b.item.itemType.label);
        if (typeCompare != 0) {
          return typeCompare;
        }
      }

      return a.item.name.compareTo(b.item.name);
    });
    return sorted;
  }

  Future<void> _openItemDetails(OwnedInventoryItem ownedItem) async {
    final updated = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.76),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(AppSpacing.md),
          child: ItemCardDetail(
            item: ownedItem.item,
            quantity: ownedItem.quantity,
            margin: EdgeInsets.zero,
            onUse: ownedItem.canUse
                ? () => _inventoryService.useItem(ownedItem)
                : null,
            onSell: ownedItem.canSell
                ? () => _inventoryService.sellItem(ownedItem)
                : null,
          ),
        );
      },
    );

    if (updated == true && mounted) {
      _refresh();
    }
  }

  void _refresh() {
    setState(() {
      _itemsFuture = _inventoryService.fetchOwnedItems();
    });
  }
}

class _InventoryPanel extends StatelessWidget {
  final List<OwnedInventoryItem> items;
  final InventorySortMode sortMode;
  final ValueChanged<InventorySortMode?> onSortChanged;
  final ValueChanged<OwnedInventoryItem> onItemTap;

  const _InventoryPanel({
    required this.items,
    required this.sortMode,
    required this.onSortChanged,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Item Inventory',
                  style: AppTextStyles.title.copyWith(fontSize: 18),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${items.length} item types',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap an item to use it or sell it for coins.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 170,
              child: _InventorySortDropdown(
                value: sortMode,
                onChanged: onSortChanged,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = AppSpacing.sm;
                var columns = (constraints.maxWidth / 130).floor();
                if (columns < 2) {
                  columns = 2;
                }
                if (columns > 5) {
                  columns = 5;
                }

                final cardWidth =
                    (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                return SingleChildScrollView(
                  child: Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: items
                        .map(
                          (ownedItem) => SizedBox(
                            width: cardWidth,
                            child: _InventoryTile(
                              ownedItem: ownedItem,
                              width: cardWidth,
                              onTap: () => onItemTap(ownedItem),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  final OwnedInventoryItem ownedItem;
  final double width;
  final VoidCallback onTap;

  const _InventoryTile({
    required this.ownedItem,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final item = ownedItem.item;

    return Stack(
      children: [
        item.itemType == InventoryItemType.egg
            ? EggCard(
                item: item,
                width: width,
                height: width * 1.35,
                onTap: onTap,
              )
            : ItemCard(
                item: item,
                width: width,
                height: width * 1.62,
                onTap: onTap,
              ),
        Positioned(
          top: 6,
          right: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'x${ownedItem.quantity}',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InventorySortDropdown extends StatelessWidget {
  final InventorySortMode value;
  final ValueChanged<InventorySortMode?> onChanged;

  const _InventorySortDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<InventorySortMode>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.card,
          iconEnabledColor: AppColors.textPrimary,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          onChanged: onChanged,
          items: const [
            DropdownMenuItem(
              value: InventorySortMode.name,
              child: Text('By Name'),
            ),
            DropdownMenuItem(
              value: InventorySortMode.type,
              child: Text('By Type'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryMessageCard extends StatelessWidget {
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onTap;

  const _InventoryMessageCard({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTextStyles.title.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onTap,
              child: Text(
                actionLabel!,
                style: AppTextStyles.button.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
