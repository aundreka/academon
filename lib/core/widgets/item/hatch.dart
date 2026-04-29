import 'dart:math' as math;

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
  late final Animation<double> _shake;
  late final Animation<double> _glowPulse;
  late final Animation<double> _flashOpacity;
  late final Animation<double> _eggScale;
  late final Animation<double> _eggOpacity;
  late final Animation<double> _pokemonOpacity;
  late final Animation<double> _pokemonScale;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();

    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -14.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -14.0, end: 12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -4.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.42, curve: Curves.easeInOut),
      ),
    );
    _glowPulse = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.82, curve: Curves.easeInOutCubic),
    );
    _flashOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.48, 0.68, curve: Curves.easeOut),
      ),
    );
    _eggScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.45), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 0.08), weight: 3),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.78, curve: Curves.easeInOutCubic),
      ),
    );
    _eggOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 3),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 2),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.8, curve: Curves.easeOut),
      ),
    );
    _pokemonOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.64, 1.0, curve: Curves.easeOutCubic),
    );
    _pokemonScale = Tween<double>(begin: 0.52, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.62, 1.0, curve: Curves.elasticOut),
      ),
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
          final glow = 0.28 + (_glowPulse.value * 0.45);
          final flashOpacity =
              ((_flashOpacity.value - 0.5) * 2).clamp(0.0, 1.0).toDouble();
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
                  color: colors.first.withOpacity(0.24 + glow),
                  blurRadius: 48,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _revealed ? '${widget.pokemon.name} Hatched!' : widget.item.name,
                  style: AppTextStyles.title.copyWith(fontSize: 28),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _statusText(rarity),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: rarity.hatchChances
                      .map((chance) => _ChanceChip(label: chance.label))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: 270,
                  height: 270,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 190 + (_glowPulse.value * 42),
                        height: 190 + (_glowPulse.value * 42),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08 + glow * 0.16),
                        ),
                      ),
                      Container(
                        width: 138 + (_glowPulse.value * 84),
                        height: 138 + (_glowPulse.value * 84),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.22 + glow * 0.18),
                              Colors.white.withOpacity(0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: flashOpacity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.95),
                                    Colors.white.withOpacity(0.22),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: _eggOpacity.value,
                        child: Transform.translate(
                          offset: Offset(_shake.value, 0),
                          child: Transform.scale(
                            scale: _eggScale.value,
                            child: _AssetImageOrFallback(
                              path: widget.item.imagePath,
                              icon: Icons.egg_alt_rounded,
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: _pokemonOpacity.value,
                        child: Transform.scale(
                          scale: _pokemonScale.value,
                          child: _AssetImageOrFallback(
                            path: 'assets/${widget.pokemon.imagePath}',
                            icon: Icons.catching_pokemon_rounded,
                          ),
                        ),
                      ),
                      ...List.generate(7, (index) {
                        final angle = (index / 7) * math.pi * 2;
                        final distance = 92 + (_glowPulse.value * 26);
                        return Positioned(
                          left: 135 + (math.cos(angle) * distance),
                          top: 135 + (math.sin(angle) * distance),
                          child: Opacity(
                            opacity: 0.16 + (_glowPulse.value * 0.62),
                            child: Transform.rotate(
                              angle: angle,
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: index.isEven ? 18 : 14,
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
                      _revealed ? 'Continue' : 'Hatching...',
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

  String _statusText(EggRarity rarity) {
    if (_revealed) {
      return 'Your ${widget.item.name} burst open and ${widget.pokemon.name} joined your collection.';
    }

    if (rarity == EggRarity.legendary) {
      return 'The shell is shaking, glowing, and charging up for a Mythic reveal. This egg has a 50/50 split between Legendary and Ultra Rare hatches.';
    }

    return 'The shell is trembling. Watch it shake, glow, and burst into its new Pokemon form.';
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
          Color(0xFF5A2E87),
          Color(0xFFB96DFF),
          Color(0xFFF2D7FF),
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

class _ChanceChip extends StatelessWidget {
  final String label;

  const _ChanceChip({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
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
