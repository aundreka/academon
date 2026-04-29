import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/data/item_inventory_service.dart';
import '../core/data/quests.dart';
import '../core/data/rewards.dart';
import '../core/models/quest.dart';
import '../core/models/reward.dart' as reward_model;
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/textstyles.dart';
import '../core/widgets/item/egg.dart';
import '../core/widgets/item/hatch.dart';
import '../core/widgets/rewards/dailyrewards.dart';
import '../core/widgets/rewards/quests.dart';
import '../core/widgets/rewards/reward.dart';
import '../core/widgets/ui/topnav.dart';
import 'study.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ItemInventoryService _itemInventoryService;
  late final SupabaseClient _supabase;
  StreamSubscription<void>? _eggPurchaseSubscription;
  Timer? _eggCountdownTimer;
  bool _loading = true;
  List<HatcheryEggEntry> _eggs = const [];
  List<Quest> _activeQuests = const [];
  int _daysPlayed = 1;
  int _claimedDailyIndex = -1;
  final Set<String> _claimedQuestIds = <String>{};
  _ActiveModuleCardData? _activeModule;
  DateTime _countdownNow = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _itemInventoryService = ItemInventoryService(_supabase);
    _eggPurchaseSubscription = ItemInventoryService.eggPurchaseStream.listen((_) {
      if (!mounted) {
        return;
      }
      _loadHomeData();
    });
    _loadHomeData();
  }

  @override
  void dispose() {
    _eggPurchaseSubscription?.cancel();
    _eggCountdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _loading = true;
    });

    try {
      final userId = _supabase.auth.currentUser?.id;
      final results = await Future.wait<dynamic>([
        _itemInventoryService.fetchActiveEggs(),
        if (userId != null)
          _supabase
              .from('user_stats')
              .select('streak')
              .eq('user_id', userId)
              .maybeSingle()
        else
          Future<Map<String, dynamic>?>.value(null),
        _loadActiveModule(userId),
        _loadQuestState(userId),
        _loadClaimedDailyIndex(userId),
      ]);

      if (!mounted) {
        return;
      }

      final eggs = results[0] as List<HatcheryEggEntry>;
      final stats = results[1] as Map<String, dynamic>?;
      final questState = results[3] as _QuestState;
      final claimedDailyIndex = results[4] as int;
      final streak = (stats?['streak'] as int?) ?? 0;

      setState(() {
        _eggs = eggs;
        _countdownNow = DateTime.now().toUtc();
        _activeQuests = questState.quests;
        _claimedQuestIds
          ..clear()
          ..addAll(questState.claimedQuestIds);
        _daysPlayed = math.max(streak, 1);
        _claimedDailyIndex = claimedDailyIndex;
        _activeModule = results[2] as _ActiveModuleCardData?;
        _loading = false;
      });
      _syncEggCountdownTicker();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load your home screen right now.'),
        ),
      );
    }
  }

  void _syncEggCountdownTicker() {
    final hasActiveCountdown = _eggs.any((egg) => !_isEggReady(egg) && egg.hatchDuration != null);

    if (hasActiveCountdown) {
      _eggCountdownTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _countdownNow = DateTime.now().toUtc();
        });
        _syncEggCountdownTicker();
      });
      return;
    }

    _eggCountdownTimer?.cancel();
    _eggCountdownTimer = null;
  }

  bool _isEggReady(HatcheryEggEntry entry) {
    final duration = entry.hatchDuration;
    if (duration == null || duration.inSeconds <= 0) {
      return true;
    }
    return !_countdownNow.isBefore(entry.createdAt.add(duration));
  }

  Future<_ActiveModuleCardData?> _loadActiveModule(String? userId) async {
    if (userId == null) {
      return null;
    }

    Map<String, dynamic>? row;
    try {
      final dynamic result = await _supabase
          .from('modules')
          .select('id, title, topic, summary, status, created_at, updated_at, last_used_at')
          .eq('user_id', userId)
          .order('last_used_at', ascending: false, nullsFirst: false)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      row = result as Map<String, dynamic>?;
    } catch (_) {
      final dynamic fallbackResult = await _supabase
          .from('modules')
          .select('id, title, topic, summary, status, created_at, updated_at')
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      row = fallbackResult as Map<String, dynamic>?;
    }

    if (row == null) {
      return null;
    }

    double progress = 0;
    try {
      final attempts = await _supabase
          .from('module_attempts')
          .select('accuracy, completed_at, started_at')
          .eq('module_id', row['id'] as String)
          .order('started_at', ascending: false)
          .limit(1);

      if (attempts.isNotEmpty) {
        final attempt = attempts.first;
        final accuracy = ((attempt['accuracy'] as num?) ?? 0).toDouble();
        progress = accuracy > 1 ? accuracy / 100 : accuracy;
      }
    } catch (_) {
      progress = 0;
    }

    final title = (row['title'] as String?)?.trim();
    final topic = (row['topic'] as String?)?.trim();

    return _ActiveModuleCardData(
      id: row['id'] as String,
      title: title?.isNotEmpty == true ? title! : 'Untitled Module',
      topic: topic?.isNotEmpty == true ? topic! : 'Study Module',
      summary: (row['summary'] as String?)?.trim(),
      progress: progress.clamp(0.0, 1.0),
      status: (row['status'] as String?) ?? 'ready',
    );
  }

  int get _availableDailyIndex {
    final unlockedCount = math.min(_daysPlayed, weeklyDailyClaimRewards.length);
    return unlockedCount - 1;
  }

  bool get _canRefreshQuests =>
      _activeQuests.isNotEmpty &&
      _activeQuests.every((quest) => _claimedQuestIds.contains(quest.id));

  Future<_QuestState> _loadQuestState(String? userId) async {
    if (userId == null) {
      return const _QuestState(
        quests: <Quest>[],
        claimedQuestIds: <String>{},
      );
    }

    try {
      final row = await _supabase
          .from('user_quest_state')
          .select('quest_ids, claimed_quest_ids')
          .eq('user_id', userId)
          .maybeSingle();

      final questIds = (row?['quest_ids'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList();
      final claimedQuestIds =
          (row?['claimed_quest_ids'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toSet();

      final resolvedQuests = questIds
          .map((id) => _questById(id))
          .whereType<Quest>()
          .toList();

      if (resolvedQuests.isEmpty) {
        return _refreshQuestState(userId: userId, reopenDialog: false);
      }

      return _QuestState(
        quests: resolvedQuests,
        claimedQuestIds: claimedQuestIds.intersection(
          resolvedQuests.map((quest) => quest.id).toSet(),
        ),
      );
    } catch (_) {
      return _QuestState(
        quests: pickRandomDailyQuests(
          count: math.min(3, dailyQuestCatalog.length),
        ),
        claimedQuestIds: const <String>{},
      );
    }
  }

  Future<int> _loadClaimedDailyIndex(String? userId) async {
    if (userId == null) {
      return -1;
    }

    try {
      final row = await _supabase
          .from('user_daily_reward_progress')
          .select('claimed_day_index')
          .eq('user_id', userId)
          .maybeSingle();

      return (row?['claimed_day_index'] as int?) ?? -1;
    } catch (_) {
      return -1;
    }
  }

  Quest? _questById(String id) {
    for (final quest in dailyQuestCatalog) {
      if (quest.id == id) {
        return quest;
      }
    }
    return null;
  }

  Future<void> _handleEggTap(HatcheryEggEntry entry) async {
    if (!_isEggReady(entry)) {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.card,
            title: Text(
              'Still Hatching',
              style: AppTextStyles.title.copyWith(fontSize: 22),
            ),
            content: Text(
              'Pokeball has not hatched yet.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    try {
      final result = await _itemInventoryService.hatchEgg(entry);
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return HatchDialog(
            item: result.item,
            pokemon: result.pokemon,
          );
        },
      );

      await _loadHomeData();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.pokemon.name} joined your inventory.'),
          backgroundColor: const Color(0xFF1E8E5A),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not hatch egg: $error'),
          backgroundColor: const Color(0xFFB53C2D),
        ),
      );
    }
  }

  Future<void> _claimQuest(Quest quest) async {
    if (_claimedQuestIds.contains(quest.id)) {
      return;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    final nextClaimedQuestIds = {..._claimedQuestIds, quest.id}.toList();
    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await _itemInventoryService.grantReward(quest.reward);
      await _supabase.from('user_quest_state').upsert({
        'user_id': userId,
        'quest_ids': _activeQuests.map((entry) => entry.id).toList(),
        'claimed_quest_ids': nextClaimedQuestIds,
        'updated_at': now,
      }, onConflict: 'user_id');

      if (!mounted) {
        return;
      }

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      await showDialog<void>(
        context: context,
        builder: (context) => RewardDialog(
          title: quest.title,
          subtitle: 'Quest complete. Your team earned these goodies.',
          reward: quest.reward,
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadHomeData();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not claim quest reward: $error'),
          backgroundColor: const Color(0xFFB53C2D),
        ),
      );
    }
  }

  Future<void> _claimDailyReward(int dayIndex, reward_model.Reward reward) async {
    if (dayIndex != _availableDailyIndex || dayIndex <= _claimedDailyIndex) {
      return;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return;
    }

    final now = DateTime.now().toUtc().toIso8601String();

    try {
      await _itemInventoryService.grantReward(reward);
      await _supabase.from('user_daily_reward_progress').upsert({
        'user_id': userId,
        'claimed_day_index': dayIndex,
        'updated_at': now,
      }, onConflict: 'user_id');

      if (!mounted) {
        return;
      }

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      await showDialog<void>(
        context: context,
        builder: (context) => RewardDialog(
          title: 'Day ${dayIndex + 1} Claimed',
          subtitle: 'Your daily login stash is ready.',
          reward: reward,
        ),
      );

      if (!mounted) {
        return;
      }

      await _loadHomeData();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not claim daily reward: $error'),
          backgroundColor: const Color(0xFFB53C2D),
        ),
      );
    }
  }

  Future<_QuestState> _refreshQuestState({
    String? userId,
    bool reopenDialog = true,
  }) async {
    final resolvedUserId = userId ?? _supabase.auth.currentUser?.id;
    if (resolvedUserId == null) {
      return const _QuestState(
        quests: <Quest>[],
        claimedQuestIds: <String>{},
      );
    }

    final selectedQuests = pickRandomDailyQuests(
      count: math.min(3, dailyQuestCatalog.length),
      excludeIds: dailyQuestCatalog.length > 3
          ? _activeQuests.map((quest) => quest.id)
          : const <String>[],
    );
    final now = DateTime.now().toUtc().toIso8601String();

    await _supabase.from('user_quest_state').upsert({
      'user_id': resolvedUserId,
      'quest_ids': selectedQuests.map((quest) => quest.id).toList(),
      'claimed_quest_ids': const <String>[],
      'refreshed_at': now,
      'updated_at': now,
    }, onConflict: 'user_id');

    final nextState = _QuestState(
      quests: selectedQuests,
      claimedQuestIds: const <String>{},
    );

    if (mounted) {
      setState(() {
        _activeQuests = nextState.quests;
        _claimedQuestIds.clear();
      });
    }

    if (reopenDialog && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New quests are ready.'),
        ),
      );
    }

    return nextState;
  }

  Future<void> _openDailyClaims() async {
    await showDialog<void>(
      context: context,
      builder: (context) => DailyRewardsDialog(
        daysPlayed: _daysPlayed,
        claimedDayIndex: _claimedDailyIndex,
        rewards: weeklyDailyClaimRewards,
        onClaim: _claimDailyReward,
      ),
    );
  }

  Future<void> _openQuests() async {
    await showDialog<void>(
      context: context,
      builder: (context) => QuestsDialog(
        quests: _activeQuests,
        claimedQuestIds: _claimedQuestIds,
        onClaim: _claimQuest,
        onRefresh: _canRefreshQuests
            ? () async {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
                await _refreshQuestState();
                if (!mounted) {
                  return;
                }
                await _openQuests();
              }
            : null,
      ),
    );
  }

  Future<void> _continueStudy() async {
    final module = _activeModule;
    if (module != null) {
      try {
        await _supabase
            .from('modules')
            .update({'last_used_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', module.id);
      } catch (_) {
        // Allow navigation even if the database has not been migrated yet.
      }
    }

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const StudyScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadHomeData();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _PlayfulBackground()),
        Column(
          children: [
            const AppTopNav(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadHomeData,
                color: const Color(0xFF0C5468),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _ActiveModuleCard(
                              module: _activeModule,
                              loading: _loading,
                              onContinue: _continueStudy,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            children: [
                              _IconLauncher(
                                icon: Icons.calendar_month_rounded,
                                tooltip: 'Daily claims',
                                accent: const Color(0xFFFFD76A),
                                onTap: _openDailyClaims,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _IconLauncher(
                                icon: Icons.assignment_turned_in_rounded,
                                tooltip: 'Daily quests',
                                accent: const Color(0xFF7FE7FF),
                                onTap: _openQuests,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _HomeHatcheryPanel(
                        eggs: _eggs,
                        now: _countdownNow,
                        loading: _loading,
                        onEggTap: _handleEggTap,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActiveModuleCardData {
  final String id;
  final String title;
  final String topic;
  final String? summary;
  final double progress;
  final String status;

  const _ActiveModuleCardData({
    required this.id,
    required this.title,
    required this.topic,
    required this.summary,
    required this.progress,
    required this.status,
  });
}

class _QuestState {
  final List<Quest> quests;
  final Set<String> claimedQuestIds;

  const _QuestState({
    required this.quests,
    required this.claimedQuestIds,
  });
}

class _ActiveModuleCard extends StatelessWidget {
  final _ActiveModuleCardData? module;
  final bool loading;
  final VoidCallback onContinue;

  const _ActiveModuleCard({
    required this.module,
    required this.loading,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final progress = module?.progress ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B4A7C),
            Color(0xFF0E71B5),
            Color(0xFF14A8E2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D65A1).withOpacity(0.32),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: loading
          ? const SizedBox(
              height: 118,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A75B0).withOpacity(0.38),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'ACTIVE MODULE',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 9,
                            color: const Color(0xFF8DEBFF),
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        module?.topic ?? 'No module yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.button.copyWith(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        module?.title ?? 'Open Study to create or continue a module.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.title.copyWith(
                          fontSize: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        module == null
                            ? 'No recent study session yet.'
                            : module!.summary?.isNotEmpty == true
                                ? module!.summary!
                                : '${_statusLabel(module!.status)} ready for your next session.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          color: const Color(0xFFD7F6FF),
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SizedBox(
                        width: 140,
                        child: FilledButton.icon(
                          onPressed: onContinue,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF163E72),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 16),
                          label: Text(
                            'Continue Study',
                            style: AppTextStyles.button.copyWith(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Chapter Progress',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 10,
                          color: const Color(0xFFD7F6FF),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: Colors.white.withOpacity(0.18),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF23D7FF),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${(progress * 100).round()}%',
                            style: AppTextStyles.body.copyWith(
                              color: const Color(0xFF69EBFF),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF23CBFF),
                        Color(0xFF1677FF),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1CC7FF).withOpacity(0.35),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    color: Color(0xFFFFCE63),
                    size: 34,
                  ),
                ),
              ],
            ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completed module';
      case 'processing':
        return 'Generating module';
      case 'failed':
        return 'Module';
      case 'ready':
      default:
        return 'Module';
    }
  }
}

class _IconLauncher extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color accent;
  final VoidCallback onTap;

  const _IconLauncher({
    required this.icon,
    required this.tooltip,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: const Color(0xFF102039).withOpacity(0.86),
              border: Border.all(color: accent.withOpacity(0.32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHatcheryPanel extends StatelessWidget {
  final List<HatcheryEggEntry> eggs;
  final DateTime now;
  final bool loading;
  final ValueChanged<HatcheryEggEntry> onEggTap;

  const _HomeHatcheryPanel({
    required this.eggs,
    required this.now,
    required this.loading,
    required this.onEggTap,
  });

  @override
  Widget build(BuildContext context) {
    final slots = List<HatcheryEggEntry?>.generate(
      3,
      (index) => index < eggs.length ? eggs[index] : null,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF156A7A),
            Color(0xFF2FA39B),
            Color(0xFF88E1BE),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF19515B).withOpacity(0.24),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.egg_alt_rounded,
                color: Color(0xFFFFF3CF),
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Hatchery',
                style: AppTextStyles.button.copyWith(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${eggs.length}/3 Active',
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFFEFFDF8),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'All three hatch slots stay visible here, so you can track every egg at a glance.',
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFFEFFFF8),
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final gap = AppSpacing.sm;
                final slotWidth = (constraints.maxWidth - (gap * 2)) / 3;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < slots.length; i++) ...[
                      Expanded(
                        child: _HatcherySlot(
                          entry: slots[i],
                          now: now,
                          width: slotWidth,
                          onTap: slots[i] == null ? null : () => onEggTap(slots[i]!),
                        ),
                      ),
                      if (i != slots.length - 1) const SizedBox(width: AppSpacing.sm),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HatcherySlot extends StatelessWidget {
  final HatcheryEggEntry? entry;
  final DateTime now;
  final double width;
  final VoidCallback? onTap;

  const _HatcherySlot({
    required this.entry,
    required this.now,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = width < 150;
    final eggWidth = math.max(76.0, width - (isCompact ? 16 : 24));
    final eggHeight = isCompact ? 118.0 : 144.0;

    if (entry == null) {
      return Container(
        constraints: BoxConstraints(minHeight: isCompact ? 220 : 260),
        padding: EdgeInsets.all(isCompact ? AppSpacing.sm : AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.14),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.egg_alt_outlined,
              size: isCompact ? 36 : 48,
              color: Colors.white.withOpacity(0.58),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Open Slot',
              textAlign: TextAlign.center,
              style: AppTextStyles.button.copyWith(
                color: AppColors.textPrimary,
                fontSize: isCompact ? 13 : 15,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Buy an egg in the shop to start hatching.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: const Color(0xFFFFF1D9),
                fontSize: isCompact ? 10 : 12,
              ),
            ),
          ],
        ),
      );
    }

    final readyToHatch = _isReadyToHatch(entry!, now);
    final progress = _progressForEntry(entry!, now);
    final label = _labelForEntry(entry!, now);

    return Container(
      constraints: BoxConstraints(minHeight: isCompact ? 220 : 260),
      padding: EdgeInsets.all(isCompact ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.center,
            child: EggCard(
              item: entry!.item,
              width: eggWidth,
              height: eggHeight,
              onTap: onTap,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            entry!.item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.button.copyWith(
              fontSize: isCompact ? 12 : 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              fontSize: isCompact ? 10 : 12,
              color: const Color(0xFFFFEED0),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (readyToHatch)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: isCompact ? 8 : AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1C1).withOpacity(0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Tap To Hatch',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  fontSize: isCompact ? 10 : 12,
                  color: const Color(0xFFFFF3C8),
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: isCompact ? 8 : 10,
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.14),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFFFE08A),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _isReadyToHatch(HatcheryEggEntry entry, DateTime now) {
    final duration = entry.hatchDuration;
    if (duration == null || duration.inSeconds <= 0) {
      return true;
    }
    return !now.isBefore(entry.createdAt.add(duration));
  }

  double _progressForEntry(HatcheryEggEntry entry, DateTime now) {
    final duration = entry.hatchDuration;
    if (duration == null || duration.inSeconds <= 0) {
      return 1.0;
    }
    final elapsedSeconds = now.difference(entry.createdAt).inSeconds;
    return (elapsedSeconds / duration.inSeconds).clamp(0.0, 1.0);
  }

  String _labelForEntry(HatcheryEggEntry entry, DateTime now) {
    if (_isReadyToHatch(entry, now)) {
      return 'Ready to hatch';
    }

    final duration = entry.hatchDuration;
    if (duration == null || duration.inSeconds <= 0) {
      return 'Ready to hatch';
    }

    final remaining = entry.createdAt.add(duration).difference(now);
    final clamped = remaining.isNegative ? Duration.zero : remaining;
    return 'Wait ${_formatCountdown(clamped)}';
  }

  String _formatCountdown(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

class _PlayfulBackground extends StatelessWidget {
  const _PlayfulBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF081322),
            Color(0xFF10284A),
            Color(0xFF153C58),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -30,
            child: _GlowBlob(
              size: 220,
              colors: const [Color(0x66FFF08A), Color(0x00FFF08A)],
            ),
          ),
          Positioned(
            top: 140,
            left: -50,
            child: _GlowBlob(
              size: 180,
              colors: const [Color(0x5557DCCB), Color(0x0057DCCB)],
            ),
          ),
          Positioned(
            bottom: -80,
            right: 20,
            child: _GlowBlob(
              size: 240,
              colors: const [Color(0x55FF8D6C), Color(0x00FF8D6C)],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TexturePainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _GlowBlob({
    required this.size,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class _TexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.05);
    final strokePaint = Paint()
      ..color = const Color(0xFF8EE8FF).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (double x = 18; x < size.width; x += 34) {
      for (double y = 28; y < size.height; y += 42) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }

    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.23),
      54,
      strokePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.62),
      72,
      strokePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.84),
      48,
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
