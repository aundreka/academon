import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/item.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';

class ItemCard extends StatelessWidget {
  final InventoryItem item;
  final double width;
  final double? height;
  final VoidCallback? onTap;

  const ItemCard({
    super.key,
    required this.item,
    this.width = 112,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForCategory(item.category);
    final resolvedHeight = height ?? (width * 1.48);

    return SizedBox(
      width: width,
      height: resolvedHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.shadow.withOpacity(0.7),
                  AppColors.background.withOpacity(0.94),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow.withOpacity(0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  palette.primary,
                                  palette.secondary,
                                ],
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.hardEdge,
                              children: [
                                Positioned(
                                  top: -18,
                                  right: -12,
                                  child: Container(
                                    width: width * 0.52,
                                    height: width * 0.52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.12),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    child: _buildItemImage(item.imagePath, item.name),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.button.copyWith(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _PricePill(
                              color: const Color(0xFFFFC857),
                              icon: Icons.monetization_on_rounded,
                              text: '${item.coinValue}',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: _PricePill(
                              color: const Color(0xFF61D0FF),
                              icon: Icons.diamond_rounded,
                              text: '${item.diamondValue}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    top: -10,
                    left: -8,
                    child: _CategoryBadge(
                      icon: _categoryIcon(item.category),
                      backgroundColor: palette.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemImage(String path, String name) {
    if (path.isEmpty) {
      return _buildFallback(name);
    }

    final normalizedPath = _normalizedAssetPath(path);

    if (kIsWeb && (normalizedPath.startsWith('http://') || normalizedPath.startsWith('https://'))) {
      return Image.network(
        normalizedPath,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildFallback(name),
      );
    }

    return Image.asset(
      normalizedPath,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => _buildFallback(name),
    );
  }

  Widget _buildFallback(String name) {
    return Center(
      child: Text(
        name.substring(0, 1).toUpperCase(),
        style: AppTextStyles.title.copyWith(
          fontSize: 32,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  String _normalizedAssetPath(String path) {
    if (path.startsWith('assets/')) {
      return path;
    }

    if (path.startsWith('items/')) {
      return 'assets/$path';
    }

    return path;
  }

  _ItemPalette _paletteForCategory(ItemCategory category) {
    switch (category) {
      case ItemCategory.progression:
        return const _ItemPalette(
          primary: Color(0xFF9B7BFF),
          secondary: Color(0xFF5136B3),
          highlight: Color(0xFFE0D4FF),
          shadow: Color(0xFF27185C),
        );
      case ItemCategory.boost:
        return const _ItemPalette(
          primary: Color(0xFFFFA756),
          secondary: Color(0xFFAA5E21),
          highlight: Color(0xFFFFD7A6),
          shadow: Color(0xFF5C2E0D),
        );
      case ItemCategory.potion:
        return const _ItemPalette(
          primary: Color(0xFF57D18C),
          secondary: Color(0xFF217A4D),
          highlight: Color(0xFFC9FFD6),
          shadow: Color(0xFF103D25),
        );
      case ItemCategory.ticket:
        return const _ItemPalette(
          primary: Color(0xFF5AB8FF),
          secondary: Color(0xFF245DA6),
          highlight: Color(0xFFCFEAFF),
          shadow: Color(0xFF12335A),
        );
      case ItemCategory.special:
        return const _ItemPalette(
          primary: Color(0xFFFF7E9E),
          secondary: Color(0xFFA52B5A),
          highlight: Color(0xFFFFD1DF),
          shadow: Color(0xFF58162F),
        );
      case ItemCategory.support:
        return const _ItemPalette(
          primary: Color(0xFF6ED0C3),
          secondary: Color(0xFF28796F),
          highlight: Color(0xFFD1FFF7),
          shadow: Color(0xFF12443E),
        );
      case ItemCategory.access:
        return const _ItemPalette(
          primary: Color(0xFFFFD45D),
          secondary: Color(0xFF9A7717),
          highlight: Color(0xFFFFF0B8),
          shadow: Color(0xFF554107),
        );
      case ItemCategory.consumable:
        return const _ItemPalette(
          primary: Color(0xFF7E9BFF),
          secondary: Color(0xFF3650AF),
          highlight: Color(0xFFD8E1FF),
          shadow: Color(0xFF1B285B),
        );
    }
  }

  IconData _categoryIcon(ItemCategory category) {
    switch (category) {
      case ItemCategory.progression:
        return Icons.auto_awesome_rounded;
      case ItemCategory.boost:
        return Icons.rocket_launch_rounded;
      case ItemCategory.potion:
        return Icons.local_drink_rounded;
      case ItemCategory.ticket:
        return Icons.confirmation_number_rounded;
      case ItemCategory.special:
        return Icons.stars_rounded;
      case ItemCategory.support:
        return Icons.favorite_rounded;
      case ItemCategory.access:
        return Icons.key_rounded;
      case ItemCategory.consumable:
        return Icons.inventory_2_rounded;
    }
  }
}

class _PricePill extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String text;

  const _PricePill({
    required this.color,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;

  const _CategoryBadge({
    required this.icon,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(
          icon,
          size: 16,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _ItemPalette {
  final Color primary;
  final Color secondary;
  final Color highlight;
  final Color shadow;

  const _ItemPalette({
    required this.primary,
    required this.secondary,
    required this.highlight,
    required this.shadow,
  });
}
