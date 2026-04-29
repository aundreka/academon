import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app_shell.dart';
import '../../core/constants/pokemon_avatars.dart';
import '../../core/data/current_user_profile.dart';
import '../../core/data/pokemons.dart';
import '../../core/models/pokemon.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/textstyles.dart';
import 'settings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final SupabaseClient _supabase;
  late Future<_ProfileViewData?> _profileFuture;
  bool _loggingOut = false;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _profileFuture = _loadProfile();
  }

  Future<void> logout(BuildContext context) async {
    setState(() => _loggingOut = true);

    try {
      await _supabase.auth.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppRoot()),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() => _loggingOut = false);
      }
    }
  }

  Future<void> _openSettings(_ProfileViewData data) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(initialAvatarPath: data.avatarPath),
      ),
    );

    if (!mounted) return;
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  Future<_ProfileViewData?> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final ensuredProfile = await CurrentUserProfileService(_supabase)
        .ensureCurrentUserProfile();
    if (ensuredProfile == null) return null;

    final weekStart = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );

    final results = await Future.wait<dynamic>([
      _supabase
          .from('profiles')
          .select('id, username, email, avatar_path')
          .eq('id', user.id)
          .maybeSingle(),
      _supabase
          .from('user_stats')
          .select('xp, level, coins, diamonds, streak')
          .eq('user_id', user.id)
          .maybeSingle(),
      _supabase
          .from('battle_history')
          .select(
            'opponent_name, battle_type, won, xp_earned, coins_earned, battled_at',
          )
          .eq('user_id', user.id)
          .order('battled_at', ascending: false)
          .limit(10),
      _supabase
          .from('battle_history')
          .select('id')
          .eq('user_id', user.id)
          .count(CountOption.exact),
      _supabase
          .from('battle_history')
          .select('id')
          .eq('user_id', user.id)
          .eq('won', true)
          .count(CountOption.exact),
      _supabase
          .from('battle_history')
          .select('id')
          .eq('user_id', user.id)
          .gte('battled_at', weekStart.toUtc().toIso8601String())
          .count(CountOption.exact),
      _supabase
          .from('owned_pokemons')
          .select('pokemon_id, level, xp, current_hp, nickname')
          .eq('user_id', user.id)
          .order('level', ascending: false)
          .order('xp', ascending: false)
          .limit(1)
          .maybeSingle(),
    ]);

    final profile = results[0] as Map<String, dynamic>?;
    final stats = results[1] as Map<String, dynamic>?;
    final historyRows = (results[2] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(_BattleHistoryEntry.fromMap)
        .toList();
    final totalBattlesResponse = results[3] as PostgrestResponse<dynamic>;
    final winsResponse = results[4] as PostgrestResponse<dynamic>;
    final weekResponse = results[5] as PostgrestResponse<dynamic>;
    final strongestRow = results[6] as Map<String, dynamic>?;

    final resolvedProfile = profile ??
        {
          'id': ensuredProfile.id,
          'username': ensuredProfile.username,
          'email': ensuredProfile.email,
          'avatar_path': ensuredProfile.avatarPath,
        };

    final totalBattles = totalBattlesResponse.count;
    final totalWins = winsResponse.count;
    final weeklyBattles = weekResponse.count;
    final strongestPokemon = _resolveStrongestPokemon(strongestRow);

    return _ProfileViewData(
      userId: (resolvedProfile['id'] as String?) ?? user.id,
      username: (resolvedProfile['username'] as String?) ?? 'Unknown Trainer',
      email: (resolvedProfile['email'] as String?) ?? user.email ?? 'No email',
      avatarPath:
          ((resolvedProfile['avatar_path'] as String?)?.isNotEmpty ?? false)
          ? resolvedProfile['avatar_path'] as String
          : defaultPokemonAvatar,
      xp: (stats?['xp'] as int?) ?? 0,
      level: (stats?['level'] as int?) ?? 1,
      coins: (stats?['coins'] as int?) ?? 0,
      diamonds: (stats?['diamonds'] as int?) ?? 0,
      streak: (stats?['streak'] as int?) ?? 0,
      totalBattles: totalBattles,
      totalWins: totalWins,
      weeklyBattles: weeklyBattles,
      strongestPokemon: strongestPokemon,
      history: historyRows,
    );
  }

  _StrongestPokemonViewData? _resolveStrongestPokemon(
    Map<String, dynamic>? strongestRow,
  ) {
    if (strongestRow == null) return null;

    final pokemonId = (strongestRow['pokemon_id'] as String?)?.trim();
    if (pokemonId == null || pokemonId.isEmpty) return null;

    Pokemon? pokemon;
    for (final entry in starterCreatures) {
      if (entry.id == pokemonId) {
        pokemon = entry;
        break;
      }
    }
    if (pokemon == null) return null;

    return _StrongestPokemonViewData(
      pokemon: pokemon,
      level: (strongestRow['level'] as int?) ?? 1,
      xp: (strongestRow['xp'] as int?) ?? 0,
      currentHp: (strongestRow['current_hp'] as int?) ?? pokemon.baseHp,
      nickname: (strongestRow['nickname'] as String?)?.trim(),
    );
  }

  String _formatBattleDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      final minutes = math.max(1, difference.inMinutes);
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    }
    if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<_ProfileViewData?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Failed to load your profile. Please try again.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                ),
              );
            }

            final data = snapshot.data;
            if (data == null) return const SizedBox.shrink();

            final stats = _BattleStats.from(data);

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _ProfileHeader(
                          onBack: () => Navigator.of(context).maybePop(),
                          trailing: const SizedBox(width: 40, height: 40),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ProfileHero(
                          data: data,
                          onEditProfile: () => _openSettings(data),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _RankProgressCard(data: data),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _CurrencyCard(
                                label: 'COINS',
                                value: _formatCompact(data.coins),
                                icon: Icons.monetization_on_rounded,
                                accent: const Color(0xFFFFC74A),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _CurrencyCard(
                                label: 'DIAMONDS',
                                value: _formatCompact(data.diamonds),
                                icon: Icons.diamond_rounded,
                                accent: const Color(0xFF4FD7FF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionTitle(
                          title: 'Battle Stats',
                          trailing: Text(
                            '${stats.totalBattles} total',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.55),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.22,
                          children: [
                            _BattleStatCard(
                              value: '${stats.winRate}%',
                              label: 'WIN RATE',
                              subtitle: '${stats.totalWins} victories',
                              accent: const Color(0xFF3DFFB5),
                            ),
                            _BattleStatCard(
                              value: '${stats.totalBattles}',
                              label: 'TOTAL BATTLES',
                              subtitle: '+${stats.weeklyBattles} this week',
                              accent: const Color(0xFF58C7FF),
                            ),
                            _BattleStatCard(
                              value: '${stats.totalWins} / ${stats.totalLosses}',
                              label: 'WINS / LOSSES',
                              subtitle: 'All-time record',
                              accent: const Color(0xFFCB71FF),
                            ),
                            _BattleStatCard(
                              value: '${data.streak}',
                              label: 'DAY STREAK',
                              subtitle: 'Keep it going',
                              accent: const Color(0xFFFF8E45),
                              icon: Icons.local_fire_department_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionTitle(
                          title: 'Strongest Pokemon',
                          trailing: TextButton(
                            onPressed: () => _openSettings(data),
                            child: Text(
                              'Edit profile',
                              style: AppTextStyles.body.copyWith(
                                color: const Color(0xFF78D4FF),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _StrongestPokemonCard(data: data.strongestPokemon),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionTitle(
                          title: 'Battle History',
                          trailing: Text(
                            'Recent',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textPrimary.withOpacity(0.55),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (data.history.isEmpty)
                          _EmptyBattleHistoryCard(onEditProfile: () => _openSettings(data))
                        else
                          ...data.history.map(
                            (battle) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: _BattleHistoryCard(
                                battle: battle,
                                relativeDate: _formatBattleDate(battle.battledAt),
                              ),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _loggingOut ? null : () => logout(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFF7A2F4D)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              backgroundColor: const Color(0xFF2A1220),
                            ),
                            child: _loggingOut
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Text(
                                    'Log out',
                                    style: AppTextStyles.button.copyWith(
                                      color: const Color(0xFFFF8CA8),
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final VoidCallback onBack;
  final Widget trailing;

  const _ProfileHeader({
    required this.onBack,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconChromeButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: onBack,
        ),
        const Expanded(
          child: Center(
            child: Text('Profile', style: AppTextStyles.title),
          ),
        ),
        trailing,
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final _ProfileViewData data;
  final VoidCallback onEditProfile;

  const _ProfileHero({
    required this.data,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final shortId = data.userId.replaceAll('-', '');
    final handleId = shortId.length >= 4
        ? shortId.substring(shortId.length - 4).toUpperCase()
        : shortId.toUpperCase();

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              28,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF101B35),
                  const Color(0xFF0E1530),
                  const Color(0xFF0A1228),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF283A69)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withOpacity(0.22),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 94,
                      height: 94,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8532FF), Color(0xFF4FD7FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF803BFF).withOpacity(0.35),
                            blurRadius: 22,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF101728),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: ClipOval(
                            child: Image.asset(
                              data.avatarPath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.person,
                                color: AppColors.accent,
                                size: 42,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF19DD77),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0E1530),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  data.username,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  '@${data.username.toLowerCase()}  #$handleId',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFF96A8D6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _TagPill(label: _rankTitleForLevel(data.level)),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: onEditProfile,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB7EBFF),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    backgroundColor: Colors.white.withOpacity(0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                      side: BorderSide(color: Colors.white.withOpacity(0.08)),
                    ),
                  ),
                  child: Text(
                    'Edit profile',
                    style: AppTextStyles.body.copyWith(
                      color: const Color(0xFFB7EBFF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HeroTexturePainter(),
              ),
            ),
          ),
          Positioned(
            top: -36,
            right: -24,
            child: Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF5FD3FF).withOpacity(0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -42,
            left: -24,
            child: Container(
              width: 122,
              height: 122,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF8B38FF).withOpacity(0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankProgressCard extends StatelessWidget {
  final _ProfileViewData data;

  const _RankProgressCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final currentLevel = data.level < 1 ? 1 : data.level;
    final xpTarget = currentLevel * 100;
    final progress = xpTarget == 0 ? 0.0 : (data.xp / xpTarget).clamp(0.0, 1.0);
    final xpToGo = math.max(0, xpTarget - data.xp);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8329FF), Color(0xFFB06BFF)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$currentLevel\nLVL',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_rankTitleForLevel(data.level)} Rank',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatCompact(data.xp)} / ${_formatCompact(xpTarget)} XP to LV ${currentLevel + 1}',
                      style: AppTextStyles.body.copyWith(
                        color: const Color(0xFF8FA2D0),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFFC67DFF),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFF24304D),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD87DFF)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _FootLabel('LV $currentLevel'),
              Expanded(
                child: Center(
                  child: Text(
                    '$xpToGo XP to go',
                    style: AppTextStyles.body.copyWith(
                      color: const Color(0xFF8FA2D0),
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              _FootLabel('LV ${currentLevel + 1}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrencyCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _CurrencyCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 20,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFF8EA2D3),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleStatCard extends StatelessWidget {
  final String value;
  final String label;
  final String subtitle;
  final Color accent;
  final IconData? icon;

  const _BattleStatCard({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.accent,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: accent, size: 18),
            const SizedBox(height: 8),
          ],
          Text(
            value,
            style: AppTextStyles.title.copyWith(fontSize: 26, color: accent),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFF88A0D7),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            subtitle,
            style: AppTextStyles.body.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StrongestPokemonCard extends StatelessWidget {
  final _StrongestPokemonViewData? data;

  const _StrongestPokemonCard({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: _panelDecoration(),
        child: Text(
          'No owned Pokemon found yet. Catch or add one and your top companion will appear here.',
          style: AppTextStyles.body.copyWith(color: Colors.white70),
        ),
      );
    }

    final pokemon = data!.pokemon;
    final displayName = (data!.nickname?.isNotEmpty ?? false)
        ? '${data!.nickname} (${pokemon.name})'
        : pokemon.name;

    return Container(
      decoration: _panelDecoration(),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C2DFF).withOpacity(0.22),
                  const Color(0xFF45D7FF).withOpacity(0.18),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Image.asset(
                _normalizedPokemonImagePath(pokemon.imagePath),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.catching_pokemon_rounded,
                  color: AppColors.accent,
                  size: 42,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTextStyles.title.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pokemon.type} / ${pokemon.rarity}',
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFF8EA6D8),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniChip(label: 'LV ${data!.level}'),
                    _MiniChip(label: '${data!.xp} XP'),
                    _MiniChip(label: '${data!.currentHp} HP'),
                    _MiniChip(label: 'Stage ${pokemon.evolution}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BattleHistoryCard extends StatelessWidget {
  final _BattleHistoryEntry battle;
  final String relativeDate;

  const _BattleHistoryCard({
    required this.battle,
    required this.relativeDate,
  });

  @override
  Widget build(BuildContext context) {
    final won = battle.won;
    final accent = won ? const Color(0xFF3CFFB5) : const Color(0xFFFF7D98);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withOpacity(0.14),
            ),
            child: Icon(
              won ? Icons.emoji_events_rounded : Icons.shield_outlined,
              color: accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs. ${battle.opponentName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$relativeDate / ${battle.battleType.toUpperCase()}',
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFF8598C7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  won ? 'WIN' : 'LOSS',
                  style: AppTextStyles.body.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '+${battle.xpEarned} XP',
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFF5AE2FF),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyBattleHistoryCard extends StatelessWidget {
  final VoidCallback onEditProfile;

  const _EmptyBattleHistoryCard({required this.onEditProfile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No battles recorded yet.',
            style: AppTextStyles.title.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Once you jump into the arena, recent matches and rewards will show up here.',
            style: AppTextStyles.body.copyWith(color: const Color(0xFF90A4D2)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget trailing;

  const _SectionTitle({
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFF647CB3),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        trailing,
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  final String label;

  const _TagPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [Color(0xFF5423AB), Color(0xFF321B66)],
        ),
        border: Border.all(color: const Color(0xFF7E46EA)),
      ),
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: const Color(0xFFFFC86A),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;

  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _IconChromeButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _IconChromeButton({
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF111C35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF243A69)),
        ),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 18, color: const Color(0xFFBBD8FF)),
        ),
      ),
    );
  }
}

class _FootLabel extends StatelessWidget {
  final String value;

  const _FootLabel(this.value);

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: AppTextStyles.body.copyWith(
        color: const Color(0xFF6E84B6),
        fontWeight: FontWeight.w800,
        fontSize: 10,
      ),
    );
  }
}

class _HeroTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.045)
      ..strokeWidth = 1;

    const spacing = 26.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final dotPaint = Paint()..color = const Color(0xFF6A8DDA).withOpacity(0.18);
    for (double x = 14; x <= size.width; x += 52) {
      for (double y = 14; y <= size.height; y += 52) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ProfileViewData {
  final String userId;
  final String username;
  final String email;
  final String avatarPath;
  final int xp;
  final int level;
  final int coins;
  final int diamonds;
  final int streak;
  final int totalBattles;
  final int totalWins;
  final int weeklyBattles;
  final _StrongestPokemonViewData? strongestPokemon;
  final List<_BattleHistoryEntry> history;

  const _ProfileViewData({
    required this.userId,
    required this.username,
    required this.email,
    required this.avatarPath,
    required this.xp,
    required this.level,
    required this.coins,
    required this.diamonds,
    required this.streak,
    required this.totalBattles,
    required this.totalWins,
    required this.weeklyBattles,
    required this.strongestPokemon,
    required this.history,
  });
}

class _StrongestPokemonViewData {
  final Pokemon pokemon;
  final int level;
  final int xp;
  final int currentHp;
  final String? nickname;

  const _StrongestPokemonViewData({
    required this.pokemon,
    required this.level,
    required this.xp,
    required this.currentHp,
    required this.nickname,
  });
}

class _BattleHistoryEntry {
  final String opponentName;
  final String battleType;
  final bool won;
  final int xpEarned;
  final int coinsEarned;
  final DateTime battledAt;

  const _BattleHistoryEntry({
    required this.opponentName,
    required this.battleType,
    required this.won,
    required this.xpEarned,
    required this.coinsEarned,
    required this.battledAt,
  });

  factory _BattleHistoryEntry.fromMap(Map<String, dynamic> map) {
    return _BattleHistoryEntry(
      opponentName: (map['opponent_name'] as String?) ?? 'Unknown Opponent',
      battleType: (map['battle_type'] as String?) ?? 'pve',
      won: (map['won'] as bool?) ?? false,
      xpEarned: (map['xp_earned'] as int?) ?? 0,
      coinsEarned: (map['coins_earned'] as int?) ?? 0,
      battledAt:
          DateTime.tryParse((map['battled_at'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}

class _BattleStats {
  final int totalBattles;
  final int totalWins;
  final int totalLosses;
  final int weeklyBattles;
  final int winRate;

  const _BattleStats({
    required this.totalBattles,
    required this.totalWins,
    required this.totalLosses,
    required this.weeklyBattles,
    required this.winRate,
  });

  factory _BattleStats.from(_ProfileViewData data) {
    final totalLosses = math.max(0, data.totalBattles - data.totalWins);
    final winRate = data.totalBattles == 0
        ? 0
        : ((data.totalWins / data.totalBattles) * 100).round();

    return _BattleStats(
      totalBattles: data.totalBattles,
      totalWins: data.totalWins,
      totalLosses: totalLosses,
      weeklyBattles: data.weeklyBattles,
      winRate: winRate,
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: const Color(0xFF121D36),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xFF21365D)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.16),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

String _rankTitleForLevel(int level) {
  if (level >= 25) return 'Champion';
  if (level >= 18) return 'Dragon Master';
  if (level >= 12) return 'Elite Trainer';
  if (level >= 6) return 'Gym Challenger';
  return 'Rookie Trainer';
}

String _formatCompact(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
  }
  return value.toString();
}

String _normalizedPokemonImagePath(String imagePath) {
  return imagePath.startsWith('assets/') ? imagePath : 'assets/$imagePath';
}
