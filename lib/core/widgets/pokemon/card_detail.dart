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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PlayableCard(
              pokemon: pokemon,
              palette: palette,
              normalizedAssetPath: _normalizedAssetPath(pokemon.imagePath),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Description',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              pokemon.description,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Abilities',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.md),
            if (pokemon.abilities.isEmpty)
              Text(
                'No abilities listed.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
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
    );
  }

  String _normalizedAssetPath(String path) {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pokemon.name,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 22,
                          color: palette.shadow,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _InfoChip(value: pokemon.type, color: palette.primary),
                          _InfoChip(value: pokemon.rarity, color: palette.secondary),
                          _InfoChip(
                            value: 'Stage ${pokemon.evolution}',
                            color: palette.shadow,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.primary.withOpacity(0.16),
                  ),
                  child: Center(
                    child: Text(
                      pokemon.name.substring(0, 1).toUpperCase(),
                      style: AppTextStyles.title.copyWith(
                        fontSize: 28,
                        color: palette.shadow,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: 1.45,
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
                      top: -18,
                      right: -12,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.16),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Image.asset(
                        normalizedAssetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Text(
                              pokemon.name,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.title.copyWith(fontSize: 20),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _StatsPanel(
              pokemon: pokemon,
              palette: palette,
            ),
          ],
        ),
      ),
    );
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

class _StatsPanel extends StatelessWidget {
  final Pokemon pokemon;
  final _TypePalette palette;

  const _StatsPanel({
    required this.pokemon,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.shadow.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'HP',
                  value: pokemon.baseHp,
                  color: const Color(0xFFE85F5F),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(
                  label: 'ATK',
                  value: pokemon.baseAttack,
                  color: const Color(0xFFF1A545),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'DEF',
                  value: pokemon.baseDefense,
                  color: const Color(0xFF4CAEE8),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatTile(
                  label: 'SPD',
                  value: pokemon.baseSpeed,
                  color: const Color(0xFF4BC973),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$value',
            style: AppTextStyles.button.copyWith(
              fontSize: 20,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
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
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: AppTextStyles.button.copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            type.toUpperCase(),
            style: AppTextStyles.body.copyWith(
              color: palette.accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
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
