import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_shell.dart';
import '../core/constants/pokemon_avatars.dart';
import '../core/data/current_user_profile.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/textstyles.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final SupabaseClient _supabase;
  late Future<_ProfileViewData?> _profileFuture;
  bool _loggingOut = false;
  String? _savingAvatarPath;

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

  Future<_ProfileViewData?> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final ensuredProfile = await CurrentUserProfileService(_supabase)
        .ensureCurrentUserProfile();
    if (ensuredProfile == null) return null;

    final results = await Future.wait<dynamic>([
      _supabase
          .from('profiles')
          .select('id, username, email, avatar_path')
          .eq('id', user.id)
          .maybeSingle(),
      _supabase
          .from('user_stats')
          .select('xp, level, coins, diamonds')
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
    ]);

    final profile = results[0] as Map<String, dynamic>?;
    final stats = results[1] as Map<String, dynamic>?;
    final historyRows = (results[2] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(_BattleHistoryEntry.fromMap)
        .toList();

    final resolvedProfile = profile ??
        {
          'id': ensuredProfile.id,
          'username': ensuredProfile.username,
          'email': ensuredProfile.email,
          'avatar_path': ensuredProfile.avatarPath,
        };

    return _ProfileViewData(
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
      history: historyRows,
    );
  }

  Future<void> _updateAvatar(String avatarPath) async {
    final user = _supabase.auth.currentUser;
    if (user == null || _savingAvatarPath != null) return;

    setState(() => _savingAvatarPath = avatarPath);

    try {
      await _supabase.from('profiles').update({
        'avatar_path': avatarPath,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', user.id);

      if (!mounted) return;

      setState(() {
        _profileFuture = _loadProfile();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update avatar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingAvatarPath = null);
      }
    }
  }

  Widget statCard(String label, String value, IconData icon, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor ?? AppColors.accent),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.title.copyWith(fontSize: 16)),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  String _formatBattleDate(DateTime date) {
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
      appBar: AppBar(
        title: Text('Trainer Profile', style: AppTextStyles.title),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: _loggingOut
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
            onPressed: _loggingOut ? null : () => logout(context),
          ),
        ],
      ),
      body: FutureBuilder<_ProfileViewData?>(
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child: ClipOval(
                          child: Image.asset(
                            data.avatarPath,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.person,
                              size: 40,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(data.username, style: AppTextStyles.title),
                      const SizedBox(height: 4),
                      Text(
                        data.email,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Academon Stats',
                  style: AppTextStyles.title.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    statCard('Level', data.level.toString(), Icons.star),
                    statCard('XP', data.xp.toString(), Icons.bolt),
                    statCard(
                      'Coins',
                      data.coins.toString(),
                      Icons.monetization_on,
                    ),
                    statCard(
                      'Diamonds',
                      data.diamonds.toString(),
                      Icons.diamond,
                      iconColor: Colors.cyanAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Choose Avatar',
                  style: AppTextStyles.title.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: pokemonAvatarPaths.map((avatarPath) {
                    final isSelected = data.avatarPath == avatarPath;
                    final isSaving = _savingAvatarPath == avatarPath;

                    return GestureDetector(
                      onTap: isSaving ? null : () => _updateAvatar(avatarPath),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.primary.withOpacity(0.18),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: isSaving
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : Image.asset(avatarPath),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Text(
                  'Battle History',
                  style: AppTextStyles.title.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),
                if (data.history.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withOpacity(0.16)),
                    ),
                    child: Text(
                      'No battles recorded yet. Once the user plays in the arena, their recent matches will appear here.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.75),
                      ),
                    ),
                  )
                else
                  Column(
                    children: data.history.map((battle) {
                      final resultColor =
                          battle.won ? Colors.greenAccent : Colors.redAccent;

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.primary.withOpacity(0.16)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              battle.won
                                  ? Icons.emoji_events
                                  : Icons.shield_outlined,
                              color: resultColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${battle.won ? 'Win' : 'Loss'} vs ${battle.opponentName}',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${battle.battleType.toUpperCase()} - ${_formatBattleDate(battle.battledAt)}',
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: 12,
                                      color: AppColors.textPrimary.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '+${battle.xpEarned} XP',
                                  style: AppTextStyles.body.copyWith(
                                    color: const Color(0xFF59D8FF),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '+${battle.coinsEarned} Coins',
                                  style: AppTextStyles.body.copyWith(
                                    color: const Color(0xFFF4C542),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loggingOut ? null : () => logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _loggingOut
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'LOGOUT',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
}

class _ProfileViewData {
  final String username;
  final String email;
  final String avatarPath;
  final int xp;
  final int level;
  final int coins;
  final int diamonds;
  final List<_BattleHistoryEntry> history;

  const _ProfileViewData({
    required this.username,
    required this.email,
    required this.avatarPath,
    required this.xp,
    required this.level,
    required this.coins,
    required this.diamonds,
    required this.history,
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
