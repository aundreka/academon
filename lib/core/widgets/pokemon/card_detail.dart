import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';

class PokemonCardDetail extends StatelessWidget {
  final Pokemon pokemon;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const PokemonCardDetail({
    super.key,
    required this.pokemon,
    this.margin = const EdgeInsets.all(AppSpacing.lg),
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForType(pokemon.type);

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
            palette.secondary.withOpacity(0.7),
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
        child: _PlayableCard(
          pokemon: pokemon,
          palette: palette,
          normalizedAssetPath: _normalizedAssetPath(pokemon.imagePath),
        ),
      ),
    );
  }

  String _normalizedAssetPath(String path) {
    if (path.startsWith('assets/')) {
      return path;
    }

    if (path.startsWith('pokemons/')) {
      return 'assets/$path';
    }

    if (path.startsWith('images/')) {
      return path;
    }

    if (path.startsWith('image/')) {
      return path.replaceFirst('image/', 'images/');
    }

    return path;
  }

  _TypePalette _paletteForType(String type) {
    final primaryType = type.split('/').first.trim().toLowerCase();

    switch (primaryType) {
      case 'fire':
        return const _TypePalette(
          primary: Color(0xFFFF8A4C),
          secondary: Color(0xFF9F4324),
          accent: Color(0xFFFFE082),
          shadow: Color(0xFF5D220F),
          soft: Color(0xFFFFC9A8),
        );
      case 'water':
        return const _TypePalette(
          primary: Color(0xFF62B7FF),
          secondary: Color(0xFF235EAC),
          accent: Color(0xFFA6EAFF),
          shadow: Color(0xFF133661),
          soft: Color(0xFFCCE8FF),
        );
      case 'grass':
        return const _TypePalette(
          primary: Color(0xFF6FD86F),
          secondary: Color(0xFF2F7A3E),
          accent: Color(0xFFC8FFA5),
          shadow: Color(0xFF153A20),
          soft: Color(0xFFDFFFD8),
        );
      case 'electric':
        return const _TypePalette(
          primary: Color(0xFFFFD84D),
          secondary: Color(0xFF9E7B14),
          accent: Color(0xFFFFFFB3),
          shadow: Color(0xFF5D460B),
          soft: Color(0xFFFFF1B5),
        );
      case 'psychic':
        return const _TypePalette(
          primary: Color(0xFFFF7DB4),
          secondary: Color(0xFF8E2B77),
          accent: Color(0xFFFFD0E5),
          shadow: Color(0xFF531843),
          soft: Color(0xFFFFE0EF),
        );
      case 'fighting':
        return const _TypePalette(
          primary: Color(0xFFFF9D6C),
          secondary: Color(0xFF9A4A27),
          accent: Color(0xFFFFD5B3),
          shadow: Color(0xFF582714),
          soft: Color(0xFFFFE5D4),
        );
      case 'ghost':
        return const _TypePalette(
          primary: Color(0xFF8D7BFF),
          secondary: Color(0xFF43358E),
          accent: Color(0xFFD6CEFF),
          shadow: Color(0xFF251A58),
          soft: Color(0xFFE5E1FF),
        );
      default:
        return const _TypePalette(
          primary: Color(0xFF6D9EFF),
          secondary: Color(0xFF2F498D),
          accent: Color(0xFFC5D5FF),
          shadow: Color(0xFF1A2750),
          soft: Color(0xFFDDE7FF),
        );
    }
  }
}

Widget _buildPokemonImage(String path, String name) {
  final fallback = Center(
    child: Text(
      name,
      textAlign: TextAlign.center,
      style: AppTextStyles.title.copyWith(fontSize: 20),
    ),
  );

  return kIsWeb
      ? Image.network(
          path,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => fallback,
        )
      : Image.asset(
          path,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => fallback,
        );
}

class _PlayableCard extends StatelessWidget {
  final Pokemon pokemon;
  final _TypePalette palette;
  final String normalizedAssetPath;

  const _PlayableCard({
    required this.pokemon,
    required this.palette,
    required this.normalizedAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    final isLegendary = pokemon.rarity.toLowerCase() == 'legendary';
    final isUltraRare = pokemon.rarity.toLowerCase() == 'ultra rare';

    final cardContent = Container(
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
        boxShadow: isLegendary
            ? [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          if (isUltraRare || isLegendary)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isLegendary
                          ? [
                              Colors.white.withOpacity(0.26),
                              const Color(0xFFFF80AB).withOpacity(0.14),
                              const Color(0xFFFFD93D).withOpacity(0.12),
                              const Color(0xFF80D8FF).withOpacity(0.12),
                              const Color(0xFF7C4DFF).withOpacity(0.10),
                              Colors.transparent,
                            ]
                          : [
                              Colors.white.withOpacity(0.22),
                              const Color(0xFFFFE082).withOpacity(0.16),
                              Colors.transparent,
                            ],
                      stops: isLegendary
                          ? const [0.0, 0.18, 0.38, 0.56, 0.72, 0.92]
                          : const [0.0, 0.32, 0.82],
                    ),
                  ),
                ),
              ),
            ),
          if (isLegendary)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: SweepGradient(
                      colors: [
                        const Color(0xFFFF6B6B).withOpacity(0.10),
                        const Color(0xFFFFD93D).withOpacity(0.10),
                        const Color(0xFF6BFF95).withOpacity(0.10),
                        const Color(0xFF59D8FF).withOpacity(0.10),
                        const Color(0xFF7C4DFF).withOpacity(0.10),
                        const Color(0xFFFF6B6B).withOpacity(0.10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        pokemon.name,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 22,
                          color: palette.shadow,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _RarityBadge(
                      label: _raritySymbol(pokemon.rarity),
                      rarity: pokemon.rarity,
                      color: palette.shadow,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _InfoChip(value: pokemon.type, color: palette.primary),
                    _InfoChip(value: pokemon.rarity, color: palette.secondary),
                    _InfoChip(value: 'Stage ${pokemon.evolution}', color: palette.shadow),
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
                        if (isUltraRare || isLegendary)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.20),
                                    Colors.transparent,
                                    (isLegendary
                                            ? const Color(0xFF80D8FF)
                                            : const Color(0xFFFFF59D))
                                        .withOpacity(0.10),
                                  ],
                                  stops: const [0.0, 0.38, 1.0],
                                ),
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
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: _buildPokemonImage(normalizedAssetPath, pokemon.name),
                        ),
                        Positioned(
                          top: AppSpacing.md,
                          left: AppSpacing.md,
                          child: _OverlayStatsGroup(
                            alignment: CrossAxisAlignment.start,
                            tiles: [
                              _OverlayStat(label: 'HP', value: '${pokemon.baseHp}'),
                              _OverlayStat(label: 'ATK', value: '${pokemon.baseAttack}'),
                            ],
                          ),
                        ),
                        Positioned(
                          top: AppSpacing.md,
                          right: AppSpacing.md,
                          child: _OverlayStatsGroup(
                            alignment: CrossAxisAlignment.end,
                            tiles: [
                              _OverlayStat(
                                label: 'DEF',
                                value: '${pokemon.baseDefense}',
                              ),
                              _OverlayStat(
                                label: 'SPD',
                                value: '${pokemon.baseSpeed}',
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
                              pokemon.description,
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
                  'Abilities',
                  style: AppTextStyles.button.copyWith(
                    fontSize: 16,
                    color: palette.shadow,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (pokemon.abilities.isEmpty)
                  Text(
                    'No abilities listed.',
                    style: AppTextStyles.body.copyWith(color: palette.shadow),
                  )
                else
                  Column(
                    children: pokemon.abilities
                        .map(
                          (ability) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _AbilityTile(
                              name: ability.name,
                              type: ability.type,
                              description: ability.description,
                              palette: palette,
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isLegendary) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const SweepGradient(
            colors: [
              Color(0xFFFF6B6B),
              Color(0xFFFFD93D),
              Color(0xFF6BFF95),
              Color(0xFF59D8FF),
              Color(0xFF7C4DFF),
              Color(0xFFFF6B6B),
            ],
          ),
        ),
        child: CustomPaint(
          painter: _LegendaryBorderPainter(),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  String _raritySymbol(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'ultra rare':
        return 'UR';
      case 'legendary':
        return 'S';
      case 'rare':
        return 'R';
      case 'uncommon':
        return 'U';
      default:
        return 'C';
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

class _OverlayStatsGroup extends StatelessWidget {
  final CrossAxisAlignment alignment;
  final List<_OverlayStat> tiles;

  const _OverlayStatsGroup({
    required this.alignment,
    required this.tiles,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: tiles
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
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
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

class _OverlayStat {
  final String label;
  final String value;

  const _OverlayStat({
    required this.label,
    required this.value,
  });
}

class _AbilityTile extends StatelessWidget {
  final String name;
  final String type;
  final String description;
  final _TypePalette palette;

  const _AbilityTile({
    required this.name,
    required this.type,
    required this.description,
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
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTextStyles.button.copyWith(
                    fontSize: 16,
                    color: palette.shadow,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: palette.secondary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: AppTextStyles.body.copyWith(
                    color: palette.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
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

class _RarityBadge extends StatelessWidget {
  final String label;
  final String rarity;
  final Color color;

  const _RarityBadge({
    required this.label,
    required this.rarity,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final lower = rarity.toLowerCase();
    final isLegendary = lower == 'legendary';
    final isUltraRare = lower == 'ultra rare';

    final rarityText = Text(
      label,
      style: AppTextStyles.title.copyWith(
        fontSize: 30,
        color: isLegendary ? Colors.white : color,
        shadows: isLegendary
            ? const [
                Shadow(color: Color(0xFFFF6B6B), blurRadius: 10),
                Shadow(color: Color(0xFFFFD93D), blurRadius: 18),
                Shadow(color: Color(0xFF59D8FF), blurRadius: 26),
                Shadow(color: Color(0xFF7C4DFF), blurRadius: 34),
              ]
            : isUltraRare
                ? [
                    Shadow(
                      color: color.withOpacity(0.28),
                      blurRadius: 12,
                    ),
                  ]
                : null,
      ),
    );

    if (isLegendary) {
      return ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B6B),
            Color(0xFFFFD93D),
            Color(0xFF59D8FF),
            Color(0xFF7C4DFF),
          ],
        ).createShader(bounds),
        child: rarityText,
      );
    }

    return rarityText;
  }
}

class _LegendaryBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(28));
    final paint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFF6B6B),
          Color(0xFFFFD93D),
          Color(0xFF6BFF95),
          Color(0xFF59D8FF),
          Color(0xFF7C4DFF),
          Color(0xFFFF6B6B),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(rrect.deflate(1.25), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TypePalette {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color shadow;
  final Color soft;

  const _TypePalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.shadow,
    required this.soft,
  });
}
