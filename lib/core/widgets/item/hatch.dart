import 'package:flutter/material.dart';

import '../../models/item.dart';
import '../../models/pokemon.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';

class HatchDialog extends StatefulWidget {
  final InventoryItem item;
  final Pokemon pokemon;

  const HatchDialog({
    super.key,
    required this.item,
    required this.pokemon,
  });

  @override
  State<HatchDialog> createState() => _HatchDialogState();
}

class _HatchDialogState extends State<HatchDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;
  late final Animation<double> _eggScale;
  late final Animation<double> _pokemonOpacity;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..forward();

    _pulse = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    );
    _eggScale = Tween<double>(begin: 1, end: 0.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.78, curve: Curves.easeInBack),
      ),
    );
    _pokemonOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.66, 1.0, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _revealed = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rarity = widget.item.eggRarity ?? EggRarity.common;
    final colors = _colorsForRarity(rarity);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final glow = 0.25 + (_pulse.value * 0.35);
          return Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withOpacity(0.30 + glow),
                  blurRadius: 42,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _revealed ? '${widget.pokemon.name} Hatched!' : 'Egg Hatching',
                  style: AppTextStyles.title.copyWith(fontSize: 28),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _revealed
                      ? 'Your ${widget.item.name} cracked open and joined your team.'
                      : 'The shell is shaking... something is about to emerge.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: 260,
                  height: 260,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 220 + (_pulse.value * 26),
                        height: 220 + (_pulse.value * 26),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08 + glow * 0.18),
                        ),
                      ),
                      Opacity(
                        opacity: 1 - _pokemonOpacity.value,
                        child: Transform.scale(
                          scale: _eggScale.value,
                          child: _AssetImageOrFallback(
                            path: widget.item.imagePath,
                            icon: Icons.egg_alt_rounded,
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: _pokemonOpacity.value,
                        child: Transform.scale(
                          scale: 0.84 + (_pokemonOpacity.value * 0.18),
                          child: _AssetImageOrFallback(
                            path: 'assets/${widget.pokemon.imagePath}',
                            icon: Icons.catching_pokemon_rounded,
                          ),
                        ),
                      ),
                      ...List.generate(5, (index) {
                        final angle = (index / 5) * 6.28;
                        final distance = 96 + (_pulse.value * 18);
                        return Positioned(
                          left: 130 + (distance * (index.isEven ? 0.3 : -0.3)) + (12 * index),
                          top: 116 + (distance * (index % 3 == 0 ? -0.2 : 0.2)) - (10 * index),
                          child: Opacity(
                            opacity: 0.18 + (_pulse.value * 0.55),
                            child: Transform.rotate(
                              angle: angle,
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 16 + (index % 2 == 0 ? 6 : 0),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.pokemon.name,
                        style: AppTextStyles.title.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${widget.pokemon.type} • ${widget.pokemon.rarity}',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _revealed ? () => Navigator.of(context).pop() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: colors.last,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Click to continue',
                      style: AppTextStyles.button.copyWith(
                        color: colors.last,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Color> _colorsForRarity(EggRarity rarity) {
    switch (rarity) {
      case EggRarity.common:
        return const [
          Color(0xFF7C4110),
          Color(0xFFF39B48),
          Color(0xFFFFCF7A),
        ];
      case EggRarity.uncommon:
        return const [
          Color(0xFF295B29),
          Color(0xFF60BE62),
          Color(0xFFC3F79B),
        ];
      case EggRarity.rare:
        return const [
          Color(0xFF1E5691),
          Color(0xFF4FA8F7),
          Color(0xFFB6ECFF),
        ];
      case EggRarity.ultraRare:
        return const [
          Color(0xFF234A7B),
          Color(0xFF7ED6FF),
          Color(0xFFF7FDFF),
        ];
      case EggRarity.legendary:
        return const [
          Color(0xFFFF5A7A),
          Color(0xFFFFB84D),
          Color(0xFF52D6FF),
        ];
    }
  }
}

class _AssetImageOrFallback extends StatelessWidget {
  final String path;
  final IconData icon;

  const _AssetImageOrFallback({
    required this.path,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return Icon(icon, size: 148, color: Colors.white);
    }

    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(icon, size: 148, color: Colors.white);
      },
    );
  }
}
