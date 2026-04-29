import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';

class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;
  final int level;
  final int xp;
  final int xpGoal;
  final double width;
  final double? height;
  final VoidCallback? onTap;

  const PokemonCard({
    super.key,
    required this.pokemon,
    required this.level,
    required this.xp,
    this.xpGoal = 1000,
    this.width = 112,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = xpGoal <= 0 ? 0.0 : (xp / xpGoal).clamp(0.0, 1.0);
    final palette = _paletteForType(pokemon.type);
    final resolvedHeight = height ?? (width * 1.48);

    return SizedBox(
      width: width,
      height: resolvedHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  palette.shadow.withOpacity(0.65),
                  AppColors.background.withOpacity(0.94),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow.withOpacity(0.34),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            palette.primary,
                            palette.secondary,
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -18,
                            right: -12,
                            child: Container(
                              width: width * 0.52,
                              height: width * 0.52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.12),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: _TypeBadge(
                              label: pokemon.type,
                              backgroundColor: Colors.white.withOpacity(0.22),
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.sm,
                                28,
                                AppSpacing.sm,
                                AppSpacing.sm,
                              ),
                              child: Image.asset(
                                _normalizedAssetPath(pokemon.imagePath),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(
                                    pokemon.name.substring(0, 1).toUpperCase(),
                                    style: AppTextStyles.title.copyWith(
                                      fontSize: 32,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    pokemon.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.button.copyWith(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Level $level',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: palette.highlight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: progress,
                      backgroundColor: Colors.white.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        palette.highlight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$xp/$xpGoal XP',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
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
          highlight: Color(0xFFFFE082),
          shadow: Color(0xFF5D220F),
        );
      case 'water':
        return const _TypePalette(
          primary: Color(0xFF62B7FF),
          secondary: Color(0xFF235EAC),
          highlight: Color(0xFFA6EAFF),
          shadow: Color(0xFF133661),
        );
      case 'grass':
        return const _TypePalette(
          primary: Color(0xFF6FD86F),
          secondary: Color(0xFF2F7A3E),
          highlight: Color(0xFFC8FFA5),
          shadow: Color(0xFF153A20),
        );
      case 'electric':
        return const _TypePalette(
          primary: Color(0xFFFFD84D),
          secondary: Color(0xFF9E7B14),
          highlight: Color(0xFFFFFFB3),
          shadow: Color(0xFF5D460B),
        );
      case 'psychic':
        return const _TypePalette(
          primary: Color(0xFFFF7DB4),
          secondary: Color(0xFF8E2B77),
          highlight: Color(0xFFFFD0E5),
          shadow: Color(0xFF531843),
        );
      case 'fighting':
        return const _TypePalette(
          primary: Color(0xFFFF9D6C),
          secondary: Color(0xFF9A4A27),
          highlight: Color(0xFFFFD5B3),
          shadow: Color(0xFF582714),
        );
      default:
        return const _TypePalette(
          primary: Color(0xFF6D9EFF),
          secondary: Color(0xFF2F498D),
          highlight: Color(0xFFC5D5FF),
          shadow: Color(0xFF1A2750),
        );
    }
  }
}

class _TypeBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;

  const _TypeBadge({
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TypePalette {
  final Color primary;
  final Color secondary;
  final Color highlight;
  final Color shadow;

  const _TypePalette({
    required this.primary,
    required this.secondary,
    required this.highlight,
    required this.shadow,
  });
}
