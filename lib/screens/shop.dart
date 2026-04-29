import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/data/item_inventory_service.dart';
import '../core/data/shop_catalog.dart';
import '../core/models/item.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/textstyles.dart';
import '../core/widgets/item/buy.dart';
import '../core/widgets/item/egg.dart';
import '../core/widgets/item/item.dart';
import '../core/widgets/ui/topnav.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late final ItemInventoryService _itemInventoryService;
  int _topNavRefreshSeed = 0;

  @override
  void initState() {
    super.initState();
    _itemInventoryService = ItemInventoryService(Supabase.instance.client);
  }

  @override
  Widget build(BuildContext context) {
    final dailyOffers = _buildDailyOffers(shopCatalog);

    return Stack(
      children: [
        const Positioned.fill(
          child: _ShopBackground(),
        ),
        Column(
          children: [
            AppTopNav(key: ValueKey(_topNavRefreshSeed)),
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
                      title: 'Daily Offers',
                      subtitle:
                          'Three rotating picks with 50% off in both coins and diamonds.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DailyOffersSection(
                      offers: dailyOffers,
                      onOfferTap: (offer) {
                        _showPurchaseDialog(
                          offer.item,
                          coinPrice: offer.discountedCoins,
                          diamondPrice: offer.discountedDiamonds,
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionHeader(
                      title: 'Egg Market',
                      subtitle:
                          'Choose your next hatch carefully. Only 3 eggs can incubate at once.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ShopGrid(
                      items: shopEggCatalog,
                      onItemTap: _showPurchaseDialog,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionHeader(
                      title: 'Items',
                      subtitle:
                          'Boosts, refills, and battle access for the next run.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ShopGrid(
                      items: shopItemCatalog,
                      onItemTap: _showPurchaseDialog,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showPurchaseDialog(
    InventoryItem item, {
    int? coinPrice,
    int? diamondPrice,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return ItemPurchaseDialog(
          item: item,
          coinPrice: coinPrice,
          diamondPrice: diamondPrice,
          onPurchase: (currency) {
            return _itemInventoryService.purchaseItem(
              item: item,
              currency: currency,
              coinPrice: coinPrice,
              diamondPrice: diamondPrice,
            );
          },
          onSuccess: () {
            if (!mounted) {
              return;
            }
            setState(() {
              _topNavRefreshSeed++;
            });
          },
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

class _DailyOffersSection extends StatelessWidget {
  final List<_DailyOffer> offers;
  final ValueChanged<_DailyOffer> onOfferTap;

  const _DailyOffersSection({
    required this.offers,
    required this.onOfferTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 236,
      child: ScrollConfiguration(
        behavior: const _DesktopFriendlyScrollBehavior(),
        child: ListView.separated(
          primary: false,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(right: AppSpacing.md),
          itemCount: offers.length,
          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.lg),
          itemBuilder: (context, index) {
            final offer = offers[index];
            return _OfferTile(
              offer: offer,
              onTap: () => onOfferTap(offer),
            );
          },
        ),
      ),
    );
  }
}

class _DesktopFriendlyScrollBehavior extends MaterialScrollBehavior {
  const _DesktopFriendlyScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.unknown,
      };
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
      width: 178,
      decoration: BoxDecoration(
        color: const Color(0xFF182544).withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.background.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _OfferArt(
              item: offer.item,
              onTap: onTap,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  offer.item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.button.copyWith(fontSize: 13),
                ),
                if (offer.item.itemType == InventoryItemType.egg) ...[
                  const SizedBox(height: 2),
                  Text(
                    (offer.item.eggRarity ?? EggRarity.common).label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: const Color(0xFFB6C8F9),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                _OfferPriceRow(
                  label: 'Coins',
                  current: offer.discountedCoins,
                  original: offer.item.coinValue,
                  color: const Color(0xFFFFC857),
                  icon: Icons.monetization_on_rounded,
                ),
                const SizedBox(height: 2),
                _OfferPriceRow(
                  label: 'Diamonds',
                  current: offer.discountedDiamonds,
                  original: offer.item.diamondValue,
                  color: const Color(0xFF61D0FF),
                  icon: Icons.diamond_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferArt extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;

  const _OfferArt({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
          bottom: Radius.circular(18),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
            bottom: Radius.circular(18),
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
                bottom: Radius.circular(18),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _previewColors(item),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2E3F).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '50% OFF',
                      style: AppTextStyles.body.copyWith(
                        color: const Color(0xFFFFD166),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -14,
                  right: -10,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: _OfferImage(item: item),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _previewColors(InventoryItem item) {
    if (item.itemType == InventoryItemType.egg) {
      switch (item.eggRarity ?? EggRarity.common) {
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

    switch (item.category) {
      case ItemCategory.progression:
        return const [Color(0xFF9B7BFF), Color(0xFF5136B3)];
      case ItemCategory.boost:
        return const [Color(0xFFFFA756), Color(0xFFAA5E21)];
      case ItemCategory.potion:
        return const [Color(0xFF57D18C), Color(0xFF217A4D)];
      case ItemCategory.ticket:
        return const [Color(0xFF5AB8FF), Color(0xFF245DA6)];
      case ItemCategory.special:
        return const [Color(0xFFFF7E9E), Color(0xFFA52B5A)];
      case ItemCategory.support:
        return const [Color(0xFF6ED0C3), Color(0xFF28796F)];
      case ItemCategory.access:
        return const [Color(0xFFFFD45D), Color(0xFF9A7717)];
      case ItemCategory.consumable:
        return const [Color(0xFF7E9BFF), Color(0xFF3650AF)];
    }
  }
}

class _OfferImage extends StatelessWidget {
  final InventoryItem item;

  const _OfferImage({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final path = _normalizedAssetPath(item.imagePath);
    if (path.isEmpty) {
      return _OfferFallback(label: item.name);
    }

    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _OfferFallback(label: item.name),
    );
  }

  String _normalizedAssetPath(String path) {
    if (path.isEmpty) {
      return '';
    }
    if (path.startsWith('assets/')) {
      return path;
    }
    if (path.startsWith('items/')) {
      return 'assets/$path';
    }
    return path;
  }
}

class _OfferFallback extends StatelessWidget {
  final String label;

  const _OfferFallback({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label.substring(0, 1).toUpperCase(),
      style: AppTextStyles.title.copyWith(
        fontSize: 30,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ShopBackground extends StatelessWidget {
  const _ShopBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1024),
            Color(0xFF101B39),
            Color(0xFF13264A),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            left: -40,
            child: _GlowBlob(
              size: 220,
              color: Color(0xFF54D2FF),
            ),
          ),
          Positioned(
            top: 140,
            right: -40,
            child: _GlowBlob(
              size: 200,
              color: Color(0xFFFFA94D),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 40,
            child: _GlowBlob(
              size: 180,
              color: Color(0xFF7D6BFF),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ShopTexturePainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.34),
            color.withOpacity(0.12),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _ShopTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    final dotPaint = Paint()
      ..color = const Color(0xFF9AE7FF).withOpacity(0.12);

    const gap = 28.0;
    for (double y = -20; y < size.height + 20; y += gap) {
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(size.width * 0.3, y + 10, size.width * 0.6, y - 8)
        ..quadraticBezierTo(size.width * 0.84, y - 18, size.width, y);
      canvas.drawPath(path, linePaint);
    }

    for (double x = 22; x < size.width; x += 72) {
      for (double y = 18; y < size.height; y += 72) {
        canvas.drawCircle(Offset(x, y), 2.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
        const SizedBox(width: 3),
        Text(
          '$label ',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
        Text(
          '$current',
          style: AppTextStyles.body.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '$original',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary.withOpacity(0.72),
            decoration: TextDecoration.lineThrough,
            fontSize: 9,
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
  final random = Random(seed);
  final eggs = catalog
      .where((item) => item.itemType == InventoryItemType.egg)
      .toList()
    ..shuffle(random);
  final items = catalog
      .where((item) => item.itemType != InventoryItemType.egg)
      .toList()
    ..shuffle(random);

  final picks = <InventoryItem>[
    if (eggs.isNotEmpty) eggs.first,
    ...items.take(2),
  ]..shuffle(random);

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
