import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/item.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';

class EggCard extends StatelessWidget {
  final InventoryItem item;
  final double width;
  final double? height;
  final VoidCallback? onTap;

  const EggCard({
    super.key,
    required this.item,
    this.width = 112,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final rarity = item.eggRarity ?? EggRarity.common;
    final palette = _paletteForRarity(rarity);
    final resolvedHeight = height ?? (width * 1.36);

    return SizedBox(
      width: width,
      height: resolvedHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.shadow.withOpacity(0.92),
                  palette.primary.withOpacity(0.82),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow.withOpacity(0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Stack(
                children: [
                  Positioned(
                    top: -18,
                    right: -10,
                    child: Container(
                      width: width * 0.52,
                      height: width * 0.52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.14),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: _buildEggImage(item.imagePath, item.name),
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _labelForRarity(rarity),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEggImage(String path, String name) {
    final fallback = Icon(
      Icons.egg_rounded,
      size: 54,
      color: AppColors.textPrimary.withOpacity(0.94),
    );

    if (path.isEmpty) {
      return fallback;
    }

    final normalizedPath = _normalizedAssetPath(path);

    if (kIsWeb && (normalizedPath.startsWith('http://') || normalizedPath.startsWith('https://'))) {
      return Image.network(
        normalizedPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    return Image.asset(
      normalizedPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => fallback,
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

  _EggPalette _paletteForRarity(EggRarity rarity) {
    switch (rarity) {
      case EggRarity.common:
        return const _EggPalette(
          primary: Color(0xFFFFC06E),
          shadow: Color(0xFF7C4110),
        );
      case EggRarity.uncommon:
        return const _EggPalette(
          primary: Color(0xFF8CD96B),
          shadow: Color(0xFF2E6B22),
        );
      case EggRarity.rare:
        return const _EggPalette(
          primary: Color(0xFF69C7FF),
          shadow: Color(0xFF1E5691),
        );
      case EggRarity.ultraRare:
        return const _EggPalette(
          primary: Color(0xFFC186FF),
          shadow: Color(0xFF5A2F9A),
        );
      case EggRarity.legendary:
        return const _EggPalette(
          primary: Color(0xFFFF7FA2),
          shadow: Color(0xFF8A2448),
        );
    }
  }

  String _labelForRarity(EggRarity rarity) {
    switch (rarity) {
      case EggRarity.common:
        return 'Common Egg';
      case EggRarity.uncommon:
        return 'Uncommon Egg';
      case EggRarity.rare:
        return 'Rare Egg';
      case EggRarity.ultraRare:
        return 'Ultra Rare Egg';
      case EggRarity.legendary:
        return 'Legendary Egg';
    }
  }
}

class _EggPalette {
  final Color primary;
  final Color shadow;

  const _EggPalette({
    required this.primary,
    required this.shadow,
  });
}
