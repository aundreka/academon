//pokemon_sprite.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/pokemon.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';

enum BattleSpriteSide {
  left,
  right,
}

class PokemonBattleSprite extends StatelessWidget {
  final Pokemon pokemon;
  final int currentHp;
  final int maxHp;
  final String? displayName;
  final BattleSpriteSide side;
  final double width;
  final double height;
  final bool showType;
  final Widget? badge;

  const PokemonBattleSprite({
    super.key,
    required this.pokemon,
    required this.currentHp,
    required this.maxHp,
    this.displayName,
    this.side = BattleSpriteSide.left,
    this.width = 180,
    this.height = 220,
    this.showType = true,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForType(pokemon.type);
    final hpRatio = maxHp <= 0 ? 0.0 : (currentHp / maxHp).clamp(0.0, 1.0);
    final alignRight = side == BattleSpriteSide.right;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _BattleHealthCard(
              name: displayName ?? pokemon.name,
              subtitle: showType ? pokemon.type : pokemon.rarity,
              currentHp: currentHp,
              maxHp: maxHp,
              hpRatio: hpRatio,
              palette: palette,
              alignRight: alignRight,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: height - 52,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    bottom: 6,
                    child: Container(
                      width: width * 0.58,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..scale(alignRight ? -1.0 : 1.0, 1.0),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: _buildPokemonImage(
                        _normalizedAssetPath(pokemon.imagePath),
                        pokemon.name,
                      ),
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      bottom: 8,
                      right: alignRight ? null : 0,
                      left: alignRight ? 0 : null,
                      child: badge!,
                    ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildPokemonImage(String path, String name) {
    final fallback = Icon(
      Icons.catching_pokemon_rounded,
      size: width * 0.44,
      color: Colors.white,
    );

    final image = (kIsWeb && (path.startsWith('http://') || path.startsWith('https://')))
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

    return HeroMode(
      enabled: false,
      child: image,
    );
  }

  _BattlePalette _paletteForType(String type) {
    final primaryType = type.split('/').first.trim().toLowerCase();

    switch (primaryType) {
      case 'fire':
        return const _BattlePalette(
          primary: Color(0xFFFF8A4C),
          secondary: Color(0xFF8E3D1F),
          highlight: Color(0xFFFFD37A),
        );
      case 'water':
        return const _BattlePalette(
          primary: Color(0xFF59B7FF),
          secondary: Color(0xFF1F5698),
          highlight: Color(0xFFB2ECFF),
        );
      case 'grass':
        return const _BattlePalette(
          primary: Color(0xFF69D97A),
          secondary: Color(0xFF2B7A41),
          highlight: Color(0xFFCFFFF0),
        );
      case 'electric':
        return const _BattlePalette(
          primary: Color(0xFFFFD84D),
          secondary: Color(0xFF947418),
          highlight: Color(0xFFFFFFBF),
        );
      case 'psychic':
        return const _BattlePalette(
          primary: Color(0xFFFF77BC),
          secondary: Color(0xFF8A2E76),
          highlight: Color(0xFFFFDAF0),
        );
      case 'ghost':
        return const _BattlePalette(
          primary: Color(0xFF8B84FF),
          secondary: Color(0xFF463C98),
          highlight: Color(0xFFD9D5FF),
        );
      default:
        return const _BattlePalette(
          primary: Color(0xFF69A8FF),
          secondary: Color(0xFF2B4E90),
          highlight: Color(0xFFD3E3FF),
        );
    }
  }
}

class _BattleHealthCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final int currentHp;
  final int maxHp;
  final double hpRatio;
  final _BattlePalette palette;
  final bool alignRight;

  const _BattleHealthCard({
    required this.name,
    required this.subtitle,
    required this.currentHp,
    required this.maxHp,
    required this.hpRatio,
    required this.palette,
    required this.alignRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.secondary.withOpacity(0.96),
            palette.primary.withOpacity(0.86),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
        boxShadow: [
          BoxShadow(
            color: palette.secondary.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.button.copyWith(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              fontSize: 10,
              color: palette.highlight,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: hpRatio,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(0.18),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _hpColor(hpRatio),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$currentHp/$maxHp',
                style: AppTextStyles.body.copyWith(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _hpColor(double ratio) {
    if (ratio <= 0.25) {
      return const Color(0xFFFF6B5E);
    }
    if (ratio <= 0.55) {
      return const Color(0xFFFFC857);
    }
    return const Color(0xFF58D68D);
  }
}

class _BattlePalette {
  final Color primary;
  final Color secondary;
  final Color highlight;

  const _BattlePalette({
    required this.primary,
    required this.secondary,
    required this.highlight,
  });
}
