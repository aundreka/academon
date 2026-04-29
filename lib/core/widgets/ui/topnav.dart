import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';

class AppTopNav extends StatefulWidget {
  const AppTopNav({super.key});

  @override
  State<AppTopNav> createState() => _AppTopNavState();
}

class _AppTopNavState extends State<AppTopNav> {
  late final SupabaseClient _supabase;
  late Future<_TopNavData> _topNavFuture;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _topNavFuture = _loadTopNavData();
  }

  Future<_TopNavData> _loadTopNavData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return const _TopNavData.guest();
    }

    final results = await Future.wait<dynamic>([
      _supabase
          .from('profiles')
          .select('username, avatar_path')
          .eq('id', user.id)
          .maybeSingle(),
      _supabase
          .from('user_stats')
          .select('xp, level, coins, streak')
          .eq('user_id', user.id)
          .maybeSingle(),
    ]);

    final profile = results[0] as Map<String, dynamic>?;
    final stats = results[1] as Map<String, dynamic>?;

    return _TopNavData(
      username: (profile?['username'] as String?) ?? 'Trainer',
      avatarPath: (profile?['avatar_path'] as String?) ?? '',
      xp: (stats?['xp'] as int?) ?? 0,
      level: (stats?['level'] as int?) ?? 1,
      coins: (stats?['coins'] as int?) ?? 0,
      streak: (stats?['streak'] as int?) ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TopNavData>(
      future: _topNavFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? const _TopNavData.guest();
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final hasError = snapshot.hasError;

        return SafeArea(
          bottom: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.background.withOpacity(0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                _ProfileBadge(
                  avatarPath: data.avatarPath,
                  isLoading: isLoading,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _XpSection(
                    username: data.username,
                    xp: data.xp,
                    level: data.level,
                    isLoading: isLoading,
                    hasError: hasError,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _StatPill(
                  icon: PhosphorIcons.coins(),
                  value: data.coins.toString(),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatPill(
                  icon: PhosphorIcons.sparkle(),
                  value: data.xp.toString(),
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatPill(
                  icon: PhosphorIcons.fire(),
                  value: data.streak.toString(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfileBadge extends StatelessWidget {
  final String avatarPath;
  final bool isLoading;

  const _ProfileBadge({
    required this.avatarPath,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarPath.trim().isNotEmpty;
    final isNetworkAvatar =
        avatarPath.startsWith('http://') || avatarPath.startsWith('https://');

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background,
        border: Border.all(color: AppColors.accent.withOpacity(0.35), width: 1.5),
      ),
      child: ClipOval(
        child: hasAvatar
            ? isNetworkAvatar
                ? Image.network(
                    avatarPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _ProfileIcon(),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const _ProfileIcon();
                    },
                  )
                : Image.asset(
                    avatarPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _ProfileIcon(),
                  )
            : isLoading
                ? const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                  )
                : const _ProfileIcon(),
      ),
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  const _ProfileIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        PhosphorIcons.userCircle(),
        color: AppColors.textPrimary,
        size: 28,
      ),
    );
  }
}

class _XpSection extends StatelessWidget {
  final String username;
  final int xp;
  final int level;
  final bool isLoading;
  final bool hasError;

  const _XpSection({
    required this.username,
    required this.xp,
    required this.level,
    required this.isLoading,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    final xpTarget = _xpTargetForLevel(level);
    final progress = xpTarget == 0 ? 0.0 : (xp / xpTarget).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.button.copyWith(fontSize: 14),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Lv $level',
              style: AppTextStyles.body.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: isLoading ? null : progress,
            minHeight: 10,
            backgroundColor: AppColors.background,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          hasError
              ? 'Unable to load player stats'
              : '$xp / $xpTarget XP',
          style: AppTextStyles.body.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  int _xpTargetForLevel(int level) {
    final normalizedLevel = level < 1 ? 1 : level;
    return normalizedLevel * 100;
  }
}

class _StatPill extends StatelessWidget {
  final PhosphorIconData icon;
  final String value;

  const _StatPill({
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopNavData {
  final String username;
  final String avatarPath;
  final int xp;
  final int level;
  final int coins;
  final int streak;

  const _TopNavData({
    required this.username,
    required this.avatarPath,
    required this.xp,
    required this.level,
    required this.coins,
    required this.streak,
  });

  const _TopNavData.guest()
      : username = 'Trainer',
        avatarPath = '',
        xp = 0,
        level = 1,
        coins = 0,
        streak = 0;
}
