import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../core/data/item_inventory_service.dart';
import '../../core/data/pokemons.dart';
import '../../core/data/rewards.dart';
import '../../core/data/bosses.dart';
import '../../core/models/boss.dart';
import '../../core/models/pokemon.dart';
import '../../core/models/reward.dart';
import '../../core/models/study_topic.dart';
import '../../core/services/qwen_question_service.dart';
import '../../core/services/study_topic_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/textstyles.dart';
import '../../core/widgets/arena/boss_sprite.dart';
import '../../core/widgets/arena/pokemon_sprite.dart';
import '../../core/widgets/arena/question.dart';

class PveBattleScreen extends StatefulWidget {
  final StudyTopic topic;

  const PveBattleScreen({
    super.key,
    required this.topic,
  });

  @override
  State<PveBattleScreen> createState() => _PveBattleScreenState();
}

class _PveBattleScreenState extends State<PveBattleScreen> {
  late final SupabaseClient _supabase;
  late final StudyTopicService _topicService;
  late final QwenQuestionService _qwenQuestionService;
  late final ItemInventoryService _inventoryService;
  late Future<_BattleBootstrap> _bootstrapFuture;
  late final AudioPlayer _bgmPlayer;
bool _playerAttacking = false;
bool _bossAttacking = false;
bool _playerHit = false;
bool _bossHit = false;
  _BattleBootstrap? _battle;
  int _playerHp = 0;
  int _bossHp = 0;
  bool _battleResolved = false;
  bool _rewardGranted = false;
  bool _rewarding = false;
  String _battleLog = 'The boss is waiting. Answer correctly to strike first.';
  Reward? _earnedReward;
  bool? _wonBattle;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _topicService = StudyTopicService(_supabase);
    _qwenQuestionService = const QwenQuestionService();
    _inventoryService = ItemInventoryService(_supabase);
    _lockLandscape();
    _bootstrapFuture = _prepareBattle();
    _bgmPlayer = AudioPlayer();
    _playBgm();
  }

  @override
  void dispose() {
     _bgmPlayer.stop();
    _bgmPlayer.dispose();

    _restoreOrientations();
    super.dispose();
  }

  Future<void> _lockLandscape() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  Future<void> _playBgm() async {
    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setVolume(0.35);
    await _bgmPlayer.play(AssetSource('audio/battle_bgm.mp3'));
  }
  Future<void> _restoreOrientations() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
Future<void> _playAttackAnimation({required bool playerAttacks}) async {
  if (!mounted) return;

  setState(() {
    _playerAttacking = playerAttacks;
    _bossAttacking = !playerAttacks;
  });

  await Future.delayed(const Duration(milliseconds: 220));

  if (!mounted) return;

  setState(() {
    _bossHit = playerAttacks;
    _playerHit = !playerAttacks;
  });

  await Future.delayed(const Duration(milliseconds: 140));

  if (!mounted) return;

  setState(() {
    _playerAttacking = false;
    _bossAttacking = false;
    _playerHit = false;
    _bossHit = false;
  });
}
  Future<_BattleBootstrap> _prepareBattle() async {
    final topic = await _loadBattleModule(widget.topic);
    await _ensureQuestionsForModule(topic);
    final player = await _loadPlayerPokemon();
    final boss = _selectBoss(topic, player.pokemon);
    final playerMaxHp = _playerMaxHp(player);
    final bossMaxHp = _bossMaxHp(boss, topic);

    try {
      await _supabase
          .from('modules')
          .update({
            'last_used_at': DateTime.now().toUtc().toIso8601String(),
            'popularity_count': topic.popularityCount + 1,
          })
          .eq('id', topic.id);
    } catch (_) {
      // Allow battle even if popularity tracking is not fully migrated.
    }

    if (topic.linkedTopicId != null) {
      try {
        final topicRow = await _supabase
            .from('topics')
            .select('popularity_count')
            .eq('id', topic.linkedTopicId!)
            .maybeSingle();
        final currentPopularity = (topicRow?['popularity_count'] as int?) ?? 0;
        await _supabase
            .from('topics')
            .update({'popularity_count': currentPopularity + 1})
            .eq('id', topic.linkedTopicId!);
      } catch (_) {
        // Popularity syncing should not block battle start.
      }
    }

    final bootstrap = _BattleBootstrap(
      topic: topic,
      player: player,
      boss: boss,
      playerMaxHp: playerMaxHp,
      bossMaxHp: bossMaxHp,
    );

    if (mounted) {
      _battle = bootstrap;
      _playerHp = playerMaxHp;
      _bossHp = bossMaxHp;
      _battleLog =
          '${boss.name} challenges your ${topic.topic} knowledge. Land correct answers to attack.';
    }

    return bootstrap;
  }

  Future<void> _ensureQuestionsForModule(StudyTopic topic) async {
    final existing = await _supabase
        .from('questions')
        .select('id')
        .eq('module_id', topic.id)
        .eq('question_type', 'mcq')
        .limit(1);
    if (existing.isNotEmpty) {
      return;
    }

    final generatedQuestions = await _qwenQuestionService.generateQuestions(
      moduleTitle: topic.title,
      moduleTopic: topic.topic,
      moduleSummary: topic.summary,
      moduleDifficulty: _normalizedQuestionDifficulty(topic.difficulty),
      count: 20,
    );

    final payload = generatedQuestions.asMap().entries.map((entry) {
      final question = entry.value;
      return {
        'module_id': topic.id,
        'question_text': question.questionText,
        'question_type': 'mcq',
        'choices': question.choices,
        'correct_answer': question.correctAnswer,
        'explanation': question.explanation,
        'difficulty': _normalizedQuestionDifficulty(question.difficulty),
        'order_index': entry.key,
      };
    }).toList();

    if (payload.isNotEmpty) {
      await _supabase.from('questions').insert(payload);
    }
  }

  Future<StudyTopic> _loadBattleModule(StudyTopic topic) async {
    if (!topic.isOwnedByUser) {
      throw Exception('Only modules can be used in PvE. Convert this topic into a module first.');
    }
    return _topicService.fetchModuleDetail(topic.id);
  }

  Future<_PlayerBattlePokemon> _loadPlayerPokemon() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return _fallbackPlayerPokemon();
    }

    final row = await _supabase
        .from('owned_pokemons')
        .select('id, pokemon_id, level, xp, current_hp, nickname')
        .eq('user_id', user.id)
        .order('level', ascending: false)
        .order('xp', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) {
      return _fallbackPlayerPokemon();
    }

    final pokemonId = (row['pokemon_id'] as String?)?.trim();
    final pokemon = starterCreatures.where((entry) => entry.id == pokemonId).firstOrNull;
    if (pokemon == null) {
      return _fallbackPlayerPokemon();
    }

    return _PlayerBattlePokemon(
      ownedPokemonId: row['id'] as String?,
      pokemon: pokemon,
      level: (row['level'] as int?) ?? 1,
      xp: (row['xp'] as int?) ?? 0,
      nickname: (row['nickname'] as String?)?.trim(),
      storedHp: (row['current_hp'] as int?) ?? pokemon.baseHp,
    );
  }

  _PlayerBattlePokemon _fallbackPlayerPokemon() {
    final fallback = starterCreatures.firstWhere(
      (entry) => entry.id == 'pichu2',
      orElse: () => starterCreatures.first,
    );
    return _PlayerBattlePokemon(
      ownedPokemonId: null,
      pokemon: fallback,
      level: 8,
      xp: 0,
      nickname: null,
      storedHp: fallback.baseHp,
    );
  }

  Boss _selectBoss(StudyTopic topic, Pokemon playerPokemon) {
    final normalizedDifficulty = topic.difficulty.toLowerCase();
    return switch (normalizedDifficulty) {
      'easy' => worldBosses.firstWhere((boss) => boss.id == 'boss_celebi'),
      'normal' => worldBosses.firstWhere((boss) => boss.id == 'boss_kyogre'),
      'hard' => worldBosses.firstWhere((boss) => boss.id == 'boss_rayquaza'),
      'exam' => worldBosses.firstWhere((boss) => boss.id == 'boss_groudon'),
      _ => worldBosses.firstWhere(
          (boss) => boss.type.split('/').first.toLowerCase() !=
              playerPokemon.type.split('/').first.toLowerCase(),
          orElse: () => worldBosses.first,
        ),
    };
  }

  int _playerMaxHp(_PlayerBattlePokemon player) {
    final scaled = player.pokemon.baseHp + (player.level * 14) + (player.pokemon.evolution * 20);
    return math.max(scaled, player.storedHp);
  }

  int _bossMaxHp(Boss boss, StudyTopic topic) {
    final multiplier = switch (topic.difficulty.toLowerCase()) {
      'easy' => 0.35,
      'normal' => 0.48,
      'hard' => 0.62,
      'exam' => 0.75,
      _ => 0.48,
    };
    return math.max(320, (boss.maxHp * multiplier).round());
  }

ArenaQuestionTurnDecision _handleAnswerResolved(ArenaAnswerResolution resolution) {
  final battle = _battle;
  if (battle == null || _battleResolved) {
    return ArenaQuestionTurnDecision.finishAttempt;
  }

  final playerAttackMultiplier = _typeEffectiveness(
    battle.player.pokemon.type,
    battle.boss.type,
  );

  final bossAttackMultiplier = _typeEffectiveness(
    battle.boss.type,
    battle.player.pokemon.type,
  );

  if (resolution.isCorrect) {
    _playAttackAnimation(playerAttacks: true);

    final damage = _playerDamage(
      player: battle.player,
      boss: battle.boss,
      topic: battle.topic,
      typeMultiplier: playerAttackMultiplier,
    );

    setState(() {
      _bossHp = math.max(0, _bossHp - damage);
      _battleLog = _battleMessage(
        actor: battle.player.displayName,
        action: 'used a study strike',
        damage: damage,
        multiplier: playerAttackMultiplier,
        isCorrect: true,
      );
    });
  } else {
    _playAttackAnimation(playerAttacks: false);

    final damage = _bossDamage(
      player: battle.player,
      boss: battle.boss,
      typeMultiplier: bossAttackMultiplier,
    );

    setState(() {
      _playerHp = math.max(0, _playerHp - damage);
      _battleLog = _battleMessage(
        actor: battle.boss.name,
        action: 'punished the mistake',
        damage: damage,
        multiplier: bossAttackMultiplier,
        isCorrect: false,
      );
    });
  }

  if (_bossHp <= 0) {
    _resolveBattle(won: true, partialQuestionResult: null);
    return ArenaQuestionTurnDecision.finishAttempt;
  }

  if (_playerHp <= 0) {
    _resolveBattle(won: false, partialQuestionResult: null);
    return ArenaQuestionTurnDecision.finishAttempt;
  }

  return ArenaQuestionTurnDecision.continueQuiz;
}
  int _playerDamage({
    required _PlayerBattlePokemon player,
    required Boss boss,
    required StudyTopic topic,
    required double typeMultiplier,
  }) {
    final difficultyBonus = switch (topic.difficulty.toLowerCase()) {
      'easy' => 0.95,
      'normal' => 1.0,
      'hard' => 1.12,
      'exam' => 1.2,
      _ => 1.0,
    };
    final raw =
        ((player.pokemon.baseAttack + (player.level * 4)) - (boss.baseDefense * 0.32)) *
            typeMultiplier *
            difficultyBonus;
    return math.max(32, raw.round());
  }

  int _bossDamage({
    required _PlayerBattlePokemon player,
    required Boss boss,
    required double typeMultiplier,
  }) {
    final raw =
        ((boss.baseAttack * 0.42) - (player.pokemon.baseDefense * 0.25) - player.level) *
            typeMultiplier;
    return math.max(24, raw.round());
  }

  String _battleMessage({
    required String actor,
    required String action,
    required int damage,
    required double multiplier,
    required bool isCorrect,
  }) {
    final effectiveness = multiplier >= 1.5
        ? ' It was super effective.'
        : multiplier <= 0.75
            ? ' It was resisted.'
            : '';
    return isCorrect
        ? '$actor $action for $damage damage.$effectiveness'
        : '$actor $action for $damage damage.$effectiveness';
  }

  String _normalizedQuestionDifficulty(String difficulty) {
    final normalized = difficulty.trim().toLowerCase();
    if (const {'easy', 'normal', 'hard', 'exam'}.contains(normalized)) {
      return normalized;
    }
    return 'normal';
  }

  double _typeEffectiveness(String attackType, String targetType) {
    final attack = attackType.split('/').first.trim().toLowerCase();
    final targetParts =
        targetType.split('/').map((part) => part.trim().toLowerCase()).toList();
    double multiplier = 1.0;

    for (final target in targetParts) {
      if (attack == 'fire' && {'grass'}.contains(target)) multiplier *= 1.4;
      if (attack == 'fire' && {'water', 'fire'}.contains(target)) multiplier *= 0.75;
      if (attack == 'water' && {'fire', 'ground'}.contains(target)) multiplier *= 1.4;
      if (attack == 'water' && {'grass', 'electric'}.contains(target)) multiplier *= 0.8;
      if (attack == 'grass' && {'water', 'ground'}.contains(target)) multiplier *= 1.4;
      if (attack == 'grass' && {'fire', 'grass', 'flying'}.contains(target)) {
        multiplier *= 0.75;
      }
      if (attack == 'electric' && {'water', 'flying'}.contains(target)) multiplier *= 1.5;
      if (attack == 'electric' && {'grass', 'dragon', 'ground'}.contains(target)) {
        multiplier *= 0.7;
      }
      if (attack == 'psychic' && {'fighting', 'poison'}.contains(target)) {
        multiplier *= 1.35;
      }
      if (attack == 'ghost' && {'psychic', 'ghost'}.contains(target)) multiplier *= 1.4;
      if (attack == 'dragon' && {'dragon'}.contains(target)) multiplier *= 1.45;
      if (attack == 'ground' && {'fire', 'electric'}.contains(target)) multiplier *= 1.35;
      if (attack == 'flying' && {'grass'}.contains(target)) multiplier *= 1.25;
    }

    return multiplier.clamp(0.6, 1.8);
  }

  Future<void> _handleQuestionCompleted(ArenaQuestionResult result) async {
    if (_battleResolved) return;

    final won = _bossHp <= 0 || (result.accuracy >= 0.6 && _playerHp > 0);
    if (won) {
      setState(() {
        _bossHp = 0;
        _battleLog = '${_battle?.boss.name ?? 'Boss'} was overwhelmed by your final answer chain.';
      });
    } else {
      setState(() {
        _playerHp = 0;
        _battleLog = '${_battle?.boss.name ?? 'Boss'} survived the quiz and knocked your team out.';
      });
    }
    await _resolveBattle(won: won, partialQuestionResult: result);
  }

  Future<void> _resolveBattle({
    required bool won,
    required ArenaQuestionResult? partialQuestionResult,
  }) async {
    if (_battleResolved || _rewarding) return;

    setState(() {
      _battleResolved = true;
      _wonBattle = won;
    });

    final battle = _battle;
    if (battle == null) return;

    final performance = partialQuestionResult?.accuracy ??
        ((_bossHp <= 0 && battle.bossMaxHp > 0)
            ? 1 - (_playerHp / battle.playerMaxHp).clamp(0.0, 1.0) * 0.25
            : 0.2);

    final rolledReward = won
        ? rollPveReward(performance: performance) +
            Reward(
              xp: battle.boss.xpReward,
              coins: battle.boss.coinReward,
              items: battle.boss.rewards,
            )
        : const Reward();

    setState(() {
      _earnedReward = rolledReward;
      _battleLog = won
          ? 'Victory. ${battle.boss.name} is down and your rewards are ready.'
          : '${battle.boss.name} wins this round. Train up and try again.';
    });

    await _persistBattleOutcome(
      won: won,
      reward: rolledReward,
      questionResult: partialQuestionResult,
      battle: battle,
    );
  }

  Future<void> _persistBattleOutcome({
    required bool won,
    required Reward reward,
    required ArenaQuestionResult? questionResult,
    required _BattleBootstrap battle,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (won && !_rewardGranted) {
      setState(() => _rewarding = true);
      try {
        await _inventoryService.grantReward(reward);
        _rewardGranted = true;
      } catch (_) {
        // Keep the battle flow alive even if reward grant fails mid-session.
      } finally {
        if (mounted) {
          setState(() => _rewarding = false);
        }
      }
    }

    try {
      await _supabase.from('battle_history').insert({
        'user_id': user.id,
        'opponent_name': battle.boss.name,
        'battle_type': 'pve',
        'won': won,
        'xp_earned': reward.xp,
        'coins_earned': reward.coins,
      });
    } catch (_) {
      // Non-blocking history logging.
    }

    if (battle.player.ownedPokemonId != null) {
      try {
        await _supabase
            .from('owned_pokemons')
            .update({
              'current_hp': math.max(0, _playerHp),
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', battle.player.ownedPokemonId!);
      } catch (_) {
        // Non-blocking HP sync.
      }
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.background,
    body: FutureBuilder<_BattleBootstrap>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _BattleMessageScaffold(
            title: 'Battle Unavailable',
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
          );
        }

        final battle = snapshot.data!;
        final reward = _earnedReward;

        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/bg/pve.jpg',
                fit: BoxFit.cover,
              ),
            ),

            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.08),
              ),
            ),

            SafeArea(
              child: _battleResolved
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 430,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _BattleResultPanel(
                            won: _wonBattle ?? false,
                            reward: reward,
                            rewarding: _rewarding,
                            topic: battle.topic,
                            onBack: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ),
                    )
                  : _BattlefieldPanel(
                      battle: battle,
                      playerHp: _playerHp,
                      bossHp: _bossHp,
                      battleLog: _battleLog,
                      playerAttacking: _playerAttacking,
                      bossAttacking: _bossAttacking,
                      playerHit: _playerHit,
                      bossHit: _bossHit,
                    ),
            ),

            if (!_battleResolved)
              Positioned(
                top: 12,
                left: 120,
                right: 120,
                child: SafeArea(
                  child: ArenaQuestionWidget(
                    moduleId: battle.topic.id,
                    supabase: _supabase,
                    onAnswerResolved: _handleAnswerResolved,
                    onCompleted: _handleQuestionCompleted,
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}
}

class _BattlefieldPanel extends StatelessWidget {
  final _BattleBootstrap battle;
  final int playerHp;
  final int bossHp;
  final String battleLog;
  final bool playerAttacking;
  final bool bossAttacking;
  final bool playerHit;
  final bool bossHit;

  const _BattlefieldPanel({
    required this.battle,
    required this.playerHp,
    required this.bossHp,
    required this.battleLog,
    required this.playerAttacking,
    required this.bossAttacking,
    required this.playerHit,
    required this.bossHit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 24,
          right: 44,
          child: Container(
            width: 150,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.24),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),

        Positioned(
          left: 32,
          right: 32,
          bottom: 88,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final travelX = constraints.maxWidth * 0.42;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      transform: Matrix4.translationValues(
                        playerAttacking ? travelX : 0,
                        playerAttacking ? -35 : 0,
                        0,
                      ),
                      child: _HitFlash(
                        active: playerHit,
                        child: PokemonBattleSprite(
                          pokemon: battle.player.pokemon,
                          displayName:
                              '${battle.player.displayName} Lv.${battle.player.level}',
                          currentHp: playerHp,
                          maxHp: battle.playerMaxHp,
                          side: BattleSpriteSide.left,
                          width: 250,
                          height: 280,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        transform: Matrix4.translationValues(
                          bossAttacking ? -travelX : 0,
                          bossAttacking ? 35 : 0,
                          0,
                        ),
                        child: _HitFlash(
                          active: bossHit,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.topCenter,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 70),
                                child: BossBattleSprite(
                                  boss: battle.boss,
                                  currentHp: bossHp,
                                  maxHp: battle.bossMaxHp,
                                  width: 520,
                                  height: 600,
                                  showHpBar: false,
                                ),
                              ),

                              Positioned(
                                top: 150,
                                child: _BossHpBar(
                                  bossName: battle.boss.name,
                                  currentHp: bossHp,
                                  maxHp: battle.bossMaxHp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

      
      ],
    );
  }
}
class _BossHpBar extends StatelessWidget {
  final String bossName;
  final int currentHp;
  final int maxHp;

  const _BossHpBar({
    required this.bossName,
    required this.currentHp,
    required this.maxHp,
  });

  @override
  Widget build(BuildContext context) {
    final hpRatio = maxHp <= 0 ? 0.0 : (currentHp / maxHp).clamp(0.0, 1.0);

    return Container(
      width: 420,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8E174E),
            Color(0xFFFF6545),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bossName,
            style: AppTextStyles.button.copyWith(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: hpRatio,
              minHeight: 8,
              backgroundColor: Colors.black.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF4AF08A),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$currentHp/$maxHp',
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HitFlash extends StatelessWidget {
  final bool active;
  final Widget child;

  const _HitFlash({
    required this.active,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: active ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 90),
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(
          active ? Colors.redAccent : Colors.white,
          BlendMode.modulate,
        ),
        child: child,
      ),
    );
  }
}

class _BattleResultPanel extends StatelessWidget {
  final bool won;
  final Reward? reward;
  final bool rewarding;
  final StudyTopic topic;
  final VoidCallback onBack;

  const _BattleResultPanel({
    required this.won,
    required this.reward,
    required this.rewarding,
    required this.topic,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: won
              ? const [
                  Color(0xFF0E2C25),
                  Color(0xFF164238),
                  Color(0xFF21594D),
                ]
              : const [
                  Color(0xFF2C1118),
                  Color(0xFF431E28),
                  Color(0xFF5B2833),
                ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            won ? 'Victory' : 'Defeat',
            style: AppTextStyles.title.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            won
                ? 'You cleared ${topic.topic} training and earned battle rewards.'
                : 'Your Pokemon fainted before the lesson gauntlet was cleared.',
            style: AppTextStyles.body.copyWith(fontSize: 13, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (rewarding)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else
            Expanded(
              child: reward?.isEmpty != false
                  ? Center(
                      child: Text(
                        won ? 'Rewards are being tallied.' : 'No rewards this round.',
                        style: AppTextStyles.body.copyWith(fontSize: 13),
                      ),
                    )
                  : _RewardSummary(reward: reward!),
            ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onBack,
              style: FilledButton.styleFrom(
                backgroundColor: won ? const Color(0xFF4AD58A) : const Color(0xFFFF8A80),
                foregroundColor: const Color(0xFF141A22),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: Text(
                'Return to Arena',
                style: AppTextStyles.button.copyWith(
                  color: const Color(0xFF141A22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardSummary extends StatelessWidget {
  final Reward reward;

  const _RewardSummary({
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RewardRow(label: 'XP', value: '${reward.xp}'),
          _RewardRow(label: 'Coins', value: '${reward.coins}'),
          _RewardRow(label: 'Diamonds', value: '${reward.diamonds}'),
          if (reward.items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Items',
              style: AppTextStyles.button.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...reward.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'x${item.quantity}',
                        style: AppTextStyles.button.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final String label;
  final String value;

  const _RewardRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(fontSize: 13, color: Colors.white),
              ),
            ),
            Text(
              value,
              style: AppTextStyles.button.copyWith(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}



class _BattleMessageScaffold extends StatelessWidget {
  final String title;
  final String message;

  const _BattleMessageScaffold({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTextStyles.title.copyWith(fontSize: 18),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattleBootstrap {
  final StudyTopic topic;
  final _PlayerBattlePokemon player;
  final Boss boss;
  final int playerMaxHp;
  final int bossMaxHp;

  const _BattleBootstrap({
    required this.topic,
    required this.player,
    required this.boss,
    required this.playerMaxHp,
    required this.bossMaxHp,
  });
}

class _PlayerBattlePokemon {
  final String? ownedPokemonId;
  final Pokemon pokemon;
  final int level;
  final int xp;
  final String? nickname;
  final int storedHp;

  const _PlayerBattlePokemon({
    required this.ownedPokemonId,
    required this.pokemon,
    required this.level,
    required this.xp,
    required this.nickname,
    required this.storedHp,
  });

  String get displayName => nickname?.isNotEmpty == true ? nickname! : pokemon.name;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
