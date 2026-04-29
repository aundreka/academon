import 'package:flutter/material.dart';

import '../../data/item_inventory_service.dart';
import '../../models/item.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';
import 'egg.dart';
import 'item.dart';

class ItemCardDetail extends StatefulWidget {
  final InventoryItem item;
  final EdgeInsetsGeometry margin;
  final int? quantity;
  final Future<InventoryActionResult> Function()? onUse;
  final Future<InventoryActionResult> Function()? onSell;

  const ItemCardDetail({
    super.key,
    required this.item,
    this.margin = const EdgeInsets.all(AppSpacing.lg),
    this.quantity,
    this.onUse,
    this.onSell,
  });

  @override
  State<ItemCardDetail> createState() => _ItemCardDetailState();
}

class _ItemCardDetailState extends State<ItemCardDetail> {
  bool _runningUse = false;
  bool _runningSell = false;

  bool get _canUse => widget.onUse != null;
  bool get _canSell => widget.onSell != null;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final quantity = widget.quantity;

    return Container(
      margin: widget.margin,
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primary.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.32),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: AppTextStyles.title.copyWith(fontSize: 24),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: item.itemType == InventoryItemType.egg
                  ? EggCard(
                      item: item,
                      width: 190,
                      height: 220,
                    )
                  : ItemCard(
                      item: item,
                      width: 190,
                      height: 250,
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _InfoPill(label: 'Type', value: item.itemType.label),
                _InfoPill(label: 'Category', value: item.category.label),
                if (quantity != null)
                  _InfoPill(label: 'Owned', value: 'x$quantity'),
                _InfoPill(label: 'Coins', value: '${item.coinValue}'),
                _InfoPill(label: 'Diamonds', value: '${item.diamondValue}'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              item.description,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (item.itemType == InventoryItemType.xpBoostChip &&
                item.xpBoostEffect != null)
              _EffectLine(
                text:
                    '${((item.xpBoostEffect!.multiplier - 1) * 100).round()}% extra XP for ${item.xpBoostEffect!.battleCount} battles.',
              ),
            if (item.itemType == InventoryItemType.energyRefill &&
                item.energyRefillEffect != null)
              _EffectLine(
                text: item.energyRefillEffect!.restoresToFull
                    ? 'Restores your energy bar to full.'
                    : 'Restores ${item.energyRefillEffect!.restoreAmount} energy.',
              ),
            if (item.itemType == InventoryItemType.evolutionCore)
              const _EffectLine(
                text: 'Requires a Pokemon target before it can be consumed.',
              ),
            const SizedBox(height: AppSpacing.xl),
            if (_canUse || _canSell)
              Row(
                children: [
                  if (_canUse)
                    Expanded(
                      child: _ActionButton(
                        label: _runningUse ? 'Using...' : 'Use Item',
                        color: const Color(0xFF3BA6FF),
                        onTap: _runningUse ? null : _handleUse,
                      ),
                    ),
                  if (_canUse && _canSell)
                    const SizedBox(width: AppSpacing.md),
                  if (_canSell)
                    Expanded(
                      child: _ActionButton(
                        label: _runningSell ? 'Selling...' : 'Sell Item',
                        color: const Color(0xFFFFB74D),
                        onTap: _runningSell ? null : _handleSell,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUse() async {
    final action = widget.onUse;
    if (action == null) {
      return;
    }

    setState(() => _runningUse = true);
    final result = await action();
    if (!mounted) {
      return;
    }

    setState(() => _runningUse = false);
    _showResult(result);
  }

  Future<void> _handleSell() async {
    final action = widget.onSell;
    if (action == null) {
      return;
    }

    setState(() => _runningSell = true);
    final result = await action();
    if (!mounted) {
      return;
    }

    setState(() => _runningSell = false);
    _showResult(result);
  }

  void _showResult(InventoryActionResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? const Color(0xFF1E8E5A)
            : const Color(0xFFB53C2D),
      ),
    );

    if (result.success) {
      Navigator.of(context).maybePop(true);
    }
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.4),
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: value,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EffectLine extends StatelessWidget {
  final String text;

  const _EffectLine({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.button.copyWith(fontSize: 15),
      ),
    );
  }
}
