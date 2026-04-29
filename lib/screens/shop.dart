import 'package:flutter/material.dart';
import 'dart:math';

import '../core/models/item.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/textstyles.dart';
import '../core/widgets/item/card.dart';
import '../core/widgets/item/card_detail.dart';
import '../core/widgets/item/egg.dart';
import '../core/widgets/ui/topnav.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final catalog = _shopCatalog;
    final hatcheryEggs = _hatcheryEggs;
    final dailyOffers = _buildDailyOffers(catalog);

    return Column(
      children: [
        const AppTopNav(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'Hatchery',
                  subtitle: 'Warm nests where your eggs slowly crack open between battles.',
                ),
                const SizedBox(height: AppSpacing.md),
                _HatcheryPanel(
                  eggs: hatcheryEggs,
                  onItemTap: (item) => _showItemDetails(context, item),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionHeader(
                  title: 'Daily Offers',
                  subtitle: 'Three rotating picks with 50% off in both coins and diamonds.',
                ),
                const SizedBox(height: AppSpacing.md),
                _DailyOffersSection(
                  offers: dailyOffers,
                  onItemTap: (item) => _showItemDetails(context, item),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SectionHeader(
                  title: 'Shop',
                  subtitle: 'Stock up on boosts, tickets, and progression items for the next run.',
                ),
                const SizedBox(height: AppSpacing.md),
                _ShopGrid(
                  items: catalog,
                  onItemTap: (item) => _showItemDetails(context, item),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showItemDetails(BuildContext context, InventoryItem item) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(AppSpacing.lg),
          child: ItemCardDetail(
            item: item,
            margin: EdgeInsets.zero,
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.title),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary.withOpacity(0.92),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _HatcheryPanel extends StatelessWidget {
  final List<_HatcheryEggEntry> eggs;
  final ValueChanged<InventoryItem> onItemTap;

  const _HatcheryPanel({
    required this.eggs,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final eggTiles =
        eggs
            .map(
              (entry) => _HatcheryEggTile(
                entry: entry,
                onTap: () => onItemTap(entry.item),
              ),
            )
            .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6A2F12),
            Color(0xFFB95A1F),
            Color(0xFFF39B48),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A3412).withOpacity(0.34),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -6,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _NestTexturePainter(),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.egg_alt_rounded,
                    color: Color(0xFFFFE2B6),
                    size: 22,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Incubation Queue',
                    style: AppTextStyles.button.copyWith(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Battle, wait, and come back when the shell starts to split.',
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFFFFF1D9),
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: eggTiles,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HatcheryEggTile extends StatelessWidget {
  final _HatcheryEggEntry entry;
  final VoidCallback onTap;

  const _HatcheryEggTile({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = entry.progress.clamp(0.0, 1.0);
    final ready = entry.isReadyToHatch;

    return Container(
      width: 188,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.16),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EggCard(
            item: entry.item,
            width: 156,
            height: 156,
            onTap: onTap,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            entry.item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.button.copyWith(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            entry.label,
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFFFFEED0),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (ready)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1C1).withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Ready To Hatch',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFFFFF3C8),
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: progress,
                backgroundColor: Colors.white.withOpacity(0.14),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFE08A)),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${(progress * 100).round()}% warmed up',
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFFFFEED0),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DailyOffersSection extends StatelessWidget {
  final List<_DailyOffer> offers;
  final ValueChanged<InventoryItem> onItemTap;

  const _DailyOffersSection({
    required this.offers,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      children: offers
          .map(
            (offer) => _OfferTile(
              offer: offer,
              onTap: () => onItemTap(offer.item),
            ),
          )
          .toList(),
    );
  }
}

class _OfferTile extends StatelessWidget {
  final _DailyOffer offer;
  final VoidCallback onTap;

  const _OfferTile({
    required this.offer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD166).withOpacity(0.24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD166).withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '50% OFF',
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFFFFD166),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: offer.item.itemType == InventoryItemType.egg
                ? EggCard(
                    item: offer.item,
                    width: 132,
                    height: 144,
                    onTap: onTap,
                  )
                : ItemCard(
                    item: offer.item,
                    width: 132,
                    height: 178,
                    onTap: onTap,
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            offer.item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.button.copyWith(fontSize: 15),
          ),
          const SizedBox(height: AppSpacing.sm),
          _OfferPriceRow(
            label: 'Coins',
            current: offer.discountedCoins,
            original: offer.item.coinValue,
            color: const Color(0xFFFFC857),
            icon: Icons.monetization_on_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          _OfferPriceRow(
            label: 'Diamonds',
            current: offer.discountedDiamonds,
            original: offer.item.diamondValue,
            color: const Color(0xFF61D0FF),
            icon: Icons.diamond_rounded,
          ),
        ],
      ),
    );
  }
}

class _OfferPriceRow extends StatelessWidget {
  final String label;
  final int current;
  final int original;
  final Color color;
  final IconData icon;

  const _OfferPriceRow({
    required this.label,
    required this.current,
    required this.original,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$label ',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '$current',
          style: AppTextStyles.body.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$original',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary.withOpacity(0.72),
            decoration: TextDecoration.lineThrough,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ShopGrid extends StatelessWidget {
  final List<InventoryItem> items;
  final ValueChanged<InventoryItem> onItemTap;

  const _ShopGrid({
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      children: items
          .map(
            (item) => item.itemType == InventoryItemType.egg
                ? EggCard(
                    item: item,
                    width: 132,
                    height: 152,
                    onTap: () => onItemTap(item),
                  )
                : ItemCard(
                    item: item,
                    width: 132,
                    height: 184,
                    onTap: () => onItemTap(item),
                  ),
          )
          .toList(),
    );
  }
}

class _NestTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    for (double y = 24; y < size.height; y += 34) {
      final path = Path();
      path.moveTo(0, y);
      path.quadraticBezierTo(size.width * 0.25, y - 10, size.width * 0.5, y);
      path.quadraticBezierTo(size.width * 0.75, y + 10, size.width, y - 4);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HatcheryEggEntry {
  final InventoryItem item;
  final String label;
  final double progress;

  const _HatcheryEggEntry({
    required this.item,
    required this.label,
    required this.progress,
  });

  bool get isReadyToHatch => progress >= 1;
}

class _DailyOffer {
  final InventoryItem item;
  final int discountedCoins;
  final int discountedDiamonds;

  const _DailyOffer({
    required this.item,
    required this.discountedCoins,
    required this.discountedDiamonds,
  });
}

List<_DailyOffer> _buildDailyOffers(List<InventoryItem> catalog) {
  final now = DateTime.now();
  final seed = (now.year * 10000) + (now.month * 100) + now.day;
  final shuffled = [...catalog]..shuffle(Random(seed));
  final picks = shuffled.take(3);

  return picks
      .map(
        (item) => _DailyOffer(
          item: item,
          discountedCoins: max(1, (item.coinValue * 0.5).round()),
          discountedDiamonds: max(1, (item.diamondValue * 0.5).round()),
        ),
      )
      .toList();
}

final List<InventoryItem> _shopCatalog = [
  InventoryItem.evolutionCore(
    id: 'shop_evolution_core',
    imagePath: 'assets/items/evolution_core.png',
  ),
  InventoryItem.xpBoostChip(
    id: 'shop_xp_boost_chip',
    imagePath: 'assets/items/xp_boost_chip.png',
  ),
  InventoryItem.egg(
    id: 'shop_common_egg',
    name: 'Starter Egg',
    imagePath: 'assets/items/common_egg.png',
    rarity: EggRarity.common,
    coinValue: 750,
    diamondValue: 8,
    eggProgress: const EggProgress(
      subjectId: 'General Knowledge',
      hatchBattleRequirement: 3,
    ),
  ),
  InventoryItem.egg(
    id: 'shop_rare_egg',
    name: 'Scholar Egg',
    imagePath: 'assets/items/rare_egg.png',
    rarity: EggRarity.rare,
    coinValue: 1200,
    diamondValue: 12,
    eggProgress: const EggProgress(
      subjectId: 'Science',
      hatchBattleRequirement: 5,
    ),
  ),
  InventoryItem.egg(
    id: 'shop_legendary_egg',
    name: 'Mythic Egg',
    imagePath: 'assets/items/legendary_egg.png',
    rarity: EggRarity.legendary,
    coinValue: 2400,
    diamondValue: 24,
    eggProgress: const EggProgress(
      subjectId: 'History',
      hatchBattleRequirement: 8,
    ),
  ),
  InventoryItem.energyRefill(
    id: 'shop_energy_refill',
    imagePath: 'assets/items/energy_refill.png',
  ),
  InventoryItem.battleTicket(
    id: 'shop_battle_ticket',
    imagePath: 'assets/items/battle_ticket.png',
  ),
];

final List<_HatcheryEggEntry> _hatcheryEggs = [
  _HatcheryEggEntry(
    item: InventoryItem.egg(
      id: 'hatchery_math_egg',
      name: 'Math Egg',
      imagePath: 'assets/items/common_egg.png',
      rarity: EggRarity.uncommon,
      eggProgress: const EggProgress(
        subjectId: 'Mathematics',
        hatchBattleRequirement: 4,
      ),
    ),
    label: '2 / 4 battles complete',
    progress: 0.5,
  ),
  _HatcheryEggEntry(
    item: InventoryItem.egg(
      id: 'hatchery_science_egg',
      name: 'Science Egg',
      imagePath: 'assets/items/rare_egg.png',
      rarity: EggRarity.rare,
      eggProgress: const EggProgress(
        subjectId: 'Science',
        hatchBattleRequirement: 5,
      ),
    ),
    label: '4 / 5 battles complete',
    progress: 0.8,
  ),
  _HatcheryEggEntry(
    item: InventoryItem.egg(
      id: 'hatchery_history_egg',
      name: 'History Egg',
      imagePath: 'assets/items/legendary_egg.png',
      rarity: EggRarity.legendary,
      eggProgress: const EggProgress(
        subjectId: 'History',
        hatchBattleRequirement: 6,
      ),
    ),
    label: 'Shell cracked and glowing',
    progress: 1,
  ),
];
