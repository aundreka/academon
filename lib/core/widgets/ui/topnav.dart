import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/current_user_profile.dart';
import '../../../screens/profile/profile.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';

class AppTopNav extends StatefulWidget {
  final bool profileTapEnabled;

  const AppTopNav({
    super.key,
    this.profileTapEnabled = true,
  });

  @override
  State<AppTopNav> createState() => _AppTopNavState();
}

class _AppTopNavState extends State<AppTopNav> {
  late final SupabaseClient _supabase;
  late Future<_TopNavData> _topNavFuture;
  static _TopNavData? _cachedTopNavData;
  static String? _cachedUserId;
  static DateTime? _cachedAt;
  static const Duration _cacheLifetime = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _topNavFuture = _loadTopNavData();
  }

  void _refresh() {
    if (!mounted) return;
    _cachedTopNavData = null;
    _cachedUserId = null;
    _cachedAt = null;
    setState(() {
      _topNavFuture = _loadTopNavData();
    });
  }

  Future<_TopNavData> _loadTopNavData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _cachedTopNavData = const _TopNavData.guest();
      _cachedUserId = null;
      _cachedAt = DateTime.now();
      return const _TopNavData.guest();
    }

    final cacheIsFresh =
        _cachedTopNavData != null &&
        _cachedUserId == user.id &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheLifetime;
    if (cacheIsFresh) {
      return _cachedTopNavData!;
    }

    final ensuredProfile = await CurrentUserProfileService(_supabase)
        .ensureCurrentUserProfile();

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

    final resolvedData = _TopNavData(
      username:
          (profile?['username'] as String?) ?? ensuredProfile?.username ?? 'Trainer',
      avatarPath:
          (profile?['avatar_path'] as String?) ?? ensuredProfile?.avatarPath ?? '',
      xp: (stats?['xp'] as int?) ?? 0,
      level: (stats?['level'] as int?) ?? 1,
      coins: (stats?['coins'] as int?) ?? 0,
      streak: (stats?['streak'] as int?) ?? 0,
    );

    _cachedTopNavData = resolvedData;
    _cachedUserId = user.id;
    _cachedAt = DateTime.now();

    return resolvedData;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_TopNavData>(
      future: _topNavFuture,
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            _cachedTopNavData ??
            const _TopNavData.guest();
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final hasError = snapshot.hasError;

        return SafeArea(
          bottom: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF151E31),
              borderRadius: BorderRadius.circular(24),
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
                  profileTapEnabled: widget.profileTapEnabled,
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
                const SizedBox(width: 104),
                _StatPill(
                  icon: PhosphorIcons.coins(),
                  value: data.coins.toString(),
                  iconColor: const Color(0xFFF4C542),
                ),
                const SizedBox(width: AppSpacing.md),
                _StatPill(
                  icon: PhosphorIcons.sparkle(),
                  value: data.xp.toString(),
                  iconColor: const Color(0xFF59D8FF),
                ),
                const SizedBox(width: AppSpacing.md),
                _StatPill(
                  icon: PhosphorIcons.fire(),
                  value: data.streak.toString(),
                  iconColor: const Color(0xFFFF6B5E),
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
  final bool profileTapEnabled;

  const _ProfileBadge({
    required this.avatarPath,
    required this.isLoading,
    required this.profileTapEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarPath.trim().isNotEmpty;
    final isNetworkAvatar =
        avatarPath.startsWith('http://') || avatarPath.startsWith('https://');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: profileTapEnabled
            ? () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
                if (!context.mounted) return;
                final state = context.findAncestorStateOfType<_AppTopNavState>();
                state?._refresh();
              }
            : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF202D46),
            boxShadow: [
              BoxShadow(
                color: AppColors.background.withOpacity(0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: hasAvatar
                ? isNetworkAvatar
                    ? Image.network(
                        avatarPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _ProfileIcon(),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const _ProfileIcon();
                        },
                      )
                    : Image.asset(
                        avatarPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const _ProfileIcon(),
                      )
                : isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                      )
                    : const _ProfileIcon(),
          ),
        ),
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
        color: const Color(0xFFC6D4F8),
        size: 24,
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
                style: AppTextStyles.button.copyWith(fontSize: 13),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Lv $level',
              style: AppTextStyles.body.copyWith(
                fontSize: 12,
                color: const Color(0xFF7FE0FF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: isLoading ? null : progress,
            minHeight: 8,
            backgroundColor: const Color(0xFF22314A),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF61D7FF)),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          hasError
              ? 'Unable to load player stats'
              : '$xp / $xpTarget XP',
          style: AppTextStyles.body.copyWith(fontSize: 10),
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
  final Color iconColor;

  const _StatPill({
    required this.icon,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
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
