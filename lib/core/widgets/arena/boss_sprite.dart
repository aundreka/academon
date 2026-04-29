//boss_sprite.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/boss.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';

class BossBattleSprite extends StatelessWidget {
  final Boss boss;
  final int currentHp;
  final int maxHp;
  final double width;
  final double height;
  final Widget? badge;

  const BossBattleSprite({
    super.key,
    required this.boss,
    required this.currentHp,
    required this.maxHp,
    this.width = 220,
    this.height = 260,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final hpRatio = maxHp <= 0 ? 0.0 : (currentHp / maxHp).clamp(0.0, 1.0);

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
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF5A1032),
                    Color(0xFFA61E4D),
                    Color(0xFFFF7A59),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF671539).withOpacity(0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    boss.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.button.copyWith(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    boss.type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 10,
                      color: const Color(0xFFFFD6C7),
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
                            minHeight: 9,
                            backgroundColor: Colors.white.withOpacity(0.16),
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
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: height - 54,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned(
                    bottom: 6,
                    child: Container(
                      width: width * 0.62,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.24),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6E76).withOpacity(0.18),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildBossImage(
                        _normalizedAssetPath(boss.imagePath),
                        boss.name,
                      ),
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      right: 0,
                      bottom: 8,
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

    if (path.startsWith('images/')) {
      return path;
    }

    if (path.startsWith('image/')) {
      return path.replaceFirst('image/', 'images/');
    }

    return path;
  }

  Widget _buildBossImage(String path, String name) {
    final fallback = Icon(
      Icons.whatshot_rounded,
      size: width * 0.42,
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
