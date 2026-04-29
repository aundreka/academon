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
    final resolvedHeight = height ?? (width * 1.32);
    final colors = _colorsForRarity(item.eggRarity ?? EggRarity.common);

    return SizedBox(
      width: width,
      height: resolvedHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.first.withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    top: -16,
                    right: -10,
                    child: Container(
                      width: width * 0.48,
                      height: width * 0.48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.14),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: _EggImage(path: item.imagePath),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.button.copyWith(fontSize: 13),
                        ),
                      ],
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

  List<Color> _colorsForRarity(EggRarity rarity) {
    switch (rarity) {
      case EggRarity.common:
        return const [Color(0xFF8A531F), Color(0xFFD9853A)];
      case EggRarity.uncommon:
        return const [Color(0xFF3B7F45), Color(0xFF82D46F)];
      case EggRarity.rare:
        return const [Color(0xFF275FA7), Color(0xFF65B7FF)];
      case EggRarity.ultraRare:
        return const [Color(0xFF5B49A8), Color(0xFFA68BFF)];
      case EggRarity.legendary:
        return const [Color(0xFFE56A4A), Color(0xFFFFD166)];
    }
  }
}

class _EggImage extends StatelessWidget {
  final String path;

  const _EggImage({
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    if (path.isNotEmpty) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const _EggFallback(),
      );
    }

    return const _EggFallback();
  }
}

class _EggFallback extends StatelessWidget {
  const _EggFallback();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.egg_alt_rounded,
      size: 72,
      color: AppColors.textPrimary,
    );
  }
}
