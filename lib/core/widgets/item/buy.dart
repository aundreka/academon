import 'package:flutter/material.dart';

import '../../data/item_inventory_service.dart';
import '../../models/item.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';

class ItemPurchaseDialog extends StatelessWidget {
  final InventoryItem item;
  final Future<PurchaseResult> Function(PurchaseCurrency currency) onPurchase;
  final VoidCallback? onSuccess;
  final int? coinPrice;
  final int? diamondPrice;

  const ItemPurchaseDialog({
    super.key,
    required this.item,
    required this.onPurchase,
    this.onSuccess,
    this.coinPrice,
    this.diamondPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.primary.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Purchase Item',
              style: AppTextStyles.title.copyWith(fontSize: 24),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Purchase this item for coins or diamonds.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.44),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTextStyles.button.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.description,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _PurchaseButton(
                    label: 'Buy with Coins',
                    icon: Icons.monetization_on_rounded,
                    color: const Color(0xFFFFC857),
                    value: coinPrice ?? item.coinValue,
                    enabled: (coinPrice ?? item.coinValue) > 0,
                    onTap: () => _purchase(context, PurchaseCurrency.coins),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _PurchaseButton(
                    label: 'Buy with Diamonds',
                    icon: Icons.diamond_rounded,
                    color: const Color(0xFF61D0FF),
                    value: diamondPrice ?? item.diamondValue,
                    enabled: (diamondPrice ?? item.diamondValue) > 0,
                    onTap: () => _purchase(context, PurchaseCurrency.diamonds),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchase(BuildContext context, PurchaseCurrency currency) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = await onPurchase(currency);
    if (!context.mounted) {
      return;
    }

    navigator.pop();

    if (result.success) {
      onSuccess?.call();
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? const Color(0xFF1E8E5A)
            : const Color(0xFFB53C2D),
      ),
    );
  }
}

class _PurchaseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final int value;
  final bool enabled;
  final VoidCallback onTap;

  const _PurchaseButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.28)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$value',
                style: AppTextStyles.title.copyWith(
                  fontSize: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
