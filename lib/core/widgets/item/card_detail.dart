import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/item.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';

class ItemCardDetail extends StatelessWidget {
  final InventoryItem item;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const ItemCardDetail({
    super.key,
    required this.item,
    this.margin = const EdgeInsets.all(AppSpacing.lg),
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForCategory(item.category);

    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.shadow.withOpacity(0.95),
            AppColors.card,
            palette.secondary.withOpacity(0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withOpacity(0.32),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: _ItemPlayableCard(
          item: item,
          palette: palette,
        ),
      ),
    );
  }

  _ItemPalette _paletteForCategory(ItemCategory category) {
    switch (category) {
      case ItemCategory.progression:
        return const _ItemPalette(
          primary: Color(0xFF9B7BFF),
          secondary: Color(0xFF5136B3),
          accent: Color(0xFFE5DBFF),
          shadow: Color(0xFF27185C),
          soft: Color(0xFFE9E1FF),
        );
      case ItemCategory.boost:
        return const _ItemPalette(
          primary: Color(0xFFFFA756),
          secondary: Color(0xFFAA5E21),
          accent: Color(0xFFFFE0B8),
          shadow: Color(0xFF5C2E0D),
          soft: Color(0xFFFFE8D0),
        );
      case ItemCategory.potion:
        return const _ItemPalette(
          primary: Color(0xFF57D18C),
          secondary: Color(0xFF217A4D),
          accent: Color(0xFFD5FFE4),
          shadow: Color(0xFF103D25),
          soft: Color(0xFFDEFFEA),
        );
      case ItemCategory.ticket:
        return const _ItemPalette(
          primary: Color(0xFF5AB8FF),
          secondary: Color(0xFF245DA6),
          accent: Color(0xFFD8EFFF),
          shadow: Color(0xFF12335A),
          soft: Color(0xFFE4F4FF),
        );
      case ItemCategory.special:
        return const _ItemPalette(
          primary: Color(0xFFFF7E9E),
          secondary: Color(0xFFA52B5A),
          accent: Color(0xFFFFD6E1),
          shadow: Color(0xFF58162F),
          soft: Color(0xFFFFE4EB),
        );
      case ItemCategory.support:
        return const _ItemPalette(
          primary: Color(0xFF6ED0C3),
          secondary: Color(0xFF28796F),
          accent: Color(0xFFD7FFF9),
          shadow: Color(0xFF12443E),
          soft: Color(0xFFE0FFFA),
        );
      case ItemCategory.access:
        return const _ItemPalette(
          primary: Color(0xFFFFD45D),
          secondary: Color(0xFF9A7717),
          accent: Color(0xFFFFF0BF),
          shadow: Color(0xFF554107),
          soft: Color(0xFFFFF5D4),
        );
      case ItemCategory.consumable:
        return const _ItemPalette(
          primary: Color(0xFF7E9BFF),
          secondary: Color(0xFF3650AF),
          accent: Color(0xFFDDE5FF),
          shadow: Color(0xFF1B285B),
          soft: Color(0xFFE6ECFF),
        );
    }
  }
}

Widget _buildItemImage(String path, String name) {
  final fallback = Center(
    child: Text(
      name.substring(0, 1).toUpperCase(),
      textAlign: TextAlign.center,
      style: AppTextStyles.title.copyWith(fontSize: 42),
    ),
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

class _ItemPlayableCard extends StatelessWidget {
  final InventoryItem item;
  final _ItemPalette palette;

  const _ItemPlayableCard({
    required this.item,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.soft,
            Colors.white,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    style: AppTextStyles.title.copyWith(
                      fontSize: 22,
                      color: palette.shadow,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _MetaBadge(
                  label: item.isPremium ? 'PREMIUM' : 'ITEM',
                  color: item.isPremium ? const Color(0xFFFFBF47) : palette.primary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _InfoChip(value: _titleCaseEnum(item.category.name), color: palette.primary),
                _InfoChip(value: _titleCaseEnum(item.itemType.name), color: palette.secondary),
                _InfoChip(
                  value: item.isConsumable ? 'Consumable' : 'Permanent',
                  color: palette.shadow,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 1.35,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            palette.primary,
                            palette.secondary,
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: -20,
                      right: -12,
                      child: Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.16),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: _buildItemImage(item.imagePath, item.name),
                    ),
                    Positioned(
                      top: AppSpacing.md,
                      left: AppSpacing.md,
                      child: _OverlayPriceGroup(
                        children: [
                          _OverlayPriceTile(
                            label: 'COINS',
                            value: '${item.coinValue}',
                            color: const Color(0xFFFFD166),
                          ),
                          _OverlayPriceTile(
                            label: 'DIAMONDS',
                            value: '${item.diamondValue}',
                            color: const Color(0xFF8AE7FF),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.0),
                              Colors.black.withOpacity(0.68),
                            ],
                          ),
                        ),
                        child: Text(
                          item.description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Details',
              style: AppTextStyles.button.copyWith(
                fontSize: 16,
                color: palette.shadow,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DetailTile(
              title: 'Description',
              content: item.description.isEmpty ? 'No description available.' : item.description,
              palette: palette,
            ),
            const SizedBox(height: AppSpacing.sm),
            _DetailTile(
              title: 'Effect',
              content: _effectDescription(item),
              palette: palette,
            ),
          ],
        ),
      ),
    );
  }

  String _effectDescription(InventoryItem item) {
    switch (item.itemType) {
      case InventoryItemType.evolutionCore:
        return 'Evolves a Pokemon by ${item.evolutionStagesGranted} stage instantly.';
      case InventoryItemType.xpBoostChip:
        final effect = item.xpBoostEffect;
        if (effect == null) {
          return 'Applies an XP boost.';
        }
        final bonusPercent = ((effect.multiplier - 1) * 100).round();
        return '+$bonusPercent% XP for the next ${effect.battleCount} battles.';
      case InventoryItemType.egg:
        final egg = item.eggProgress;
        if (egg == null) {
          return 'Hatches over time or after enough battles.';
        }
        final parts = <String>[];
        if (egg.subjectId != null && egg.subjectId!.isNotEmpty) {
          parts.add('Linked to ${egg.subjectId}');
        }
        if (egg.hatchBattleRequirement > 0) {
          parts.add('Hatches after ${egg.hatchBattleRequirement} battles');
        }
        if (egg.hatchDuration != null) {
          parts.add('or ${egg.hatchDuration!.inHours}h of waiting');
        }
        return parts.isEmpty ? 'Hatches over time or after enough battles.' : '${parts.join('. ')}.';
      case InventoryItemType.energyRefill:
        final energy = item.energyRefillEffect;
        if (energy == null) {
          return 'Restores energy for PvE progression.';
        }
        if (energy.restoresToFull) {
          return 'Fully restores PvE energy.';
        }
        return 'Restores ${energy.restoreAmount} PvE energy.';
      case InventoryItemType.battleTicket:
        final ticket = item.battleTicketAccess;
        if (ticket == null) {
          return 'Required for battle entry.';
        }
        return 'Required for ${ticket.mode.name.toUpperCase()} entry. ${ticket.requiredPerEntry} ticket per battle.';
      case InventoryItemType.generic:
        return 'General-purpose inventory item.';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String value;
  final Color color;

  const _InfoChip({
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: AppTextStyles.body.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OverlayPriceGroup extends StatelessWidget {
  final List<_OverlayPriceTile> children;

  const _OverlayPriceGroup({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .map(
            (tile) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${tile.label} ',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text: tile.value,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 10,
                          color: tile.color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _OverlayPriceTile {
  final String label;
  final String value;
  final Color color;

  const _OverlayPriceTile({
    required this.label,
    required this.value,
    required this.color,
  });
}

class _DetailTile extends StatelessWidget {
  final String title;
  final String content;
  final _ItemPalette palette;

  const _DetailTile({
    required this.title,
    required this.content,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.shadow.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.button.copyWith(
              fontSize: 16,
              color: palette.shadow,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content,
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFF111827),
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _titleCaseEnum(String value) {
  if (value.isEmpty) {
    return value;
  }

  final withSpaces = value.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );

  return withSpaces[0].toUpperCase() + withSpaces.substring(1);
}

class _ItemPalette {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color shadow;
  final Color soft;

  const _ItemPalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.shadow,
    required this.soft,
  });
}
