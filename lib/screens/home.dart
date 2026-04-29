import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/data/item_inventory_service.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/textstyles.dart';
import '../core/widgets/item/egg.dart';
import '../core/widgets/item/hatch.dart';
import '../core/widgets/ui/topnav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ItemInventoryService _itemInventoryService;
  bool _loading = true;
  List<HatcheryEggEntry> _eggs = const [];

  @override
  void initState() {
    super.initState();
    _itemInventoryService = ItemInventoryService(Supabase.instance.client);
    _loadEggs();
  }

  Future<void> _loadEggs() async {
    setState(() {
      _loading = true;
    });

    try {
      final eggs = await _itemInventoryService.fetchActiveEggs();
      if (!mounted) {
        return;
      }
      setState(() {
        _eggs = eggs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load your hatchery right now.'),
        ),
      );
    }
  }

  Future<void> _handleEggTap(HatcheryEggEntry entry) async {
    if (!entry.isReadyToHatch) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            title: Text(
              'Still Hatching',
              style: AppTextStyles.title.copyWith(fontSize: 22),
            ),
            content: Text(
              'Pokeball has not hatched yet.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    try {
      final result = await _itemInventoryService.hatchEgg(entry);
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return HatchDialog(
            item: result.item,
            pokemon: result.pokemon,
          );
        },
      );

      await _loadEggs();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.pokemon.name} joined your inventory.'),
          backgroundColor: const Color(0xFF1E8E5A),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not hatch egg: $error'),
          backgroundColor: const Color(0xFFB53C2D),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppTopNav(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadEggs,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroPanel(
                    subtitle:
                        'Jump back into the adventure, check your active eggs, and keep your team growing.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _HomeHatcheryPanel(
                    eggs: _eggs,
                    loading: _loading,
                    onEggTap: _handleEggTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String subtitle;

  const _HeroPanel({
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF143A68),
            Color(0xFF1F6FB2),
            Color(0xFF4AB7E8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A4F8A).withOpacity(0.28),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Home Base',
            style: AppTextStyles.title.copyWith(fontSize: 28),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHatcheryPanel extends StatelessWidget {
  final List<HatcheryEggEntry> eggs;
  final bool loading;
  final ValueChanged<HatcheryEggEntry> onEggTap;

  const _HomeHatcheryPanel({
    required this.eggs,
    required this.loading,
    required this.onEggTap,
  });

  @override
  Widget build(BuildContext context) {
    final slots = List<HatcheryEggEntry?>.generate(
      3,
      (index) => index < eggs.length ? eggs[index] : null,
    );

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
            color: const Color(0xFF7A3412).withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
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
                'Hatchery',
                style: AppTextStyles.button.copyWith(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${eggs.length}/3 Active',
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFFFFF1D9),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Only 3 eggs can hatch at one time. Tap a ready egg to claim the Pokemon inside.',
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFFFFF1D9),
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < slots.length; i++) ...[
                    _HatcherySlot(
                      entry: slots[i],
                      onTap: slots[i] == null ? null : () => onEggTap(slots[i]!),
                    ),
                    if (i != slots.length - 1)
                      const SizedBox(width: AppSpacing.md),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HatcherySlot extends StatelessWidget {
  final HatcheryEggEntry? entry;
  final VoidCallback? onTap;

  const _HatcherySlot({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return Container(
        width: 180,
        height: 280,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.16),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.egg_alt_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.58),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Open Slot',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Buy an egg in the shop to start hatching.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFFFFF1D9),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 180,
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
            item: entry!.item,
            width: 148,
            height: 156,
            onTap: onTap,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            entry!.item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.button.copyWith(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            entry!.label,
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFFFFEED0),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (entry!.isReadyToHatch)
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
                'Tap To Hatch',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFFFFF3C8),
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: entry!.progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.14),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFFFE08A),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
