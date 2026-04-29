import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/boss.dart';

class BossBattleSprite extends StatelessWidget {
  final Boss boss;
  final int currentHp;
  final int maxHp;
  final double width;
  final double height;
  final Widget? badge;
  final bool showHpBar;

  const BossBattleSprite({
    super.key,
    required this.boss,
    required this.currentHp,
    required this.maxHp,
    this.width = 220,
    this.height = 260,
    this.badge,
    this.showHpBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildBossImage(
              _normalizedAssetPath(boss.imagePath),
              boss.name,
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
    );
  }

  String _normalizedAssetPath(String path) {
    if (path.startsWith('assets/')) return path;
    if (path.startsWith('images/')) return path;
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

    final image = (kIsWeb &&
            (path.startsWith('http://') || path.startsWith('https://')))
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
}