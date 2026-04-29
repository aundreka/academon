import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/item_inventory_service.dart';
import '../../core/data/pokemons.dart';
import '../../core/data/rewards.dart';
import '../../core/models/pokemon.dart';
import '../../core/models/reward.dart';
import '../../core/models/study_topic.dart';
import '../../core/services/study_topic_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/textstyles.dart';
import '../../core/widgets/arena/pokemon_sprite.dart';
import '../../core/widgets/arena/question.dart';
import '../../core/widgets/topics/topic_views.dart';

class PvpRankedScreen extends StatefulWidget {
  const PvpRankedScreen({super.key});

  @override
  State<PvpRankedScreen> createState() => _PvpRankedScreenState();
}

class _PvpRankedScreenState extends State<PvpRankedScreen> {
  late final SupabaseClient _supabase;
  late final StudyTopicService _topicService;
  late final ItemInventoryService _inventoryService;
  late Future<_RankedLobbyState> _lobbyFuture;

  _RankedBattleState? _battle;
  int _playerHp = 0;
  int _opponentHp = 0;
  int _playerCorrect = 0;
  int _opponentCorrect = 0;
  bool _battleResolved = false;
  bool _rewarding = false;
  bool _rewardGranted = false;
  bool? _wonBattle;
  Reward? _earnedReward;
  String _battleLog = 'Rolling a ranked topic from the arena database.';

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _topicService = StudyTopicService(_supabase);
    _inventoryService = ItemInventoryService(_supabase);
    _lockLandscape();
    _lobbyFuture = _loadRankedLobby();
  }

  @override
  void dispose() {
    _restoreOrientations();
    super.dispose();
  }

  Future<void> _lockLandscape() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restoreOrientations() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<_RankedLobbyState> _loadRankedLobby() async {
    final topics = List<StudyTopic>.from(
      await _topicService.fetchAvailableTopics(),
    );
    topics.sort((a, b) {
      final popularity = b.popularityCount.compareTo(a.popularityCount);
      if (popularity != 0) return popularity;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    final rankedTopic = _pickRankedTopic(topics);
    return _RankedLobbyState(
      rankedTopic: rankedTopic,
      totalTopics: topics.length,
    );
  }

  StudyTopic _pickRankedTopic(List<StudyTopic> topics) {
    if (topics.isEmpty) {
      return StudyTopic(
        id: 'fallback-ranked-topic',
        ownerId: null,
        linkedTopicId: null,
        title: 'Ranked Review Circuit',
        topic: 'Arena Fundamentals',
        category: 'Arena',
        difficulty: 'normal',
        summary: 'A rotating ranked topic for players who want a fair duel.',
        status: 'ready',
        sourceType: 'curated',
        imageUrl: '',
        fileUrl: null,
        popularityCount: 0,
        isOwnedByUser: false,
      );
    }

    final now = DateTime.now().toUtc();
    final seed = (now.year * 10000) + (now.month * 100) + now.day;
    final index = seed % topics.length;
    return topics[index];
  }

  Future<void> _refreshLobby() async {
    final future = _loadRankedLobby();
    setState(() {
      _lobbyFuture = future;
    });
    await future;
  }

  Future<void> _startRankedMatch(StudyTopic rankedTopic) async {
    final playerTopic = await _ensureBattleModule(rankedTopic);
    await _ensureQuestionsForModule(playerTopic);

    final player = await _loadPlayerPokemon();
    final opponentPokemon = _pickOpponentPokemon(player.pokemon);
    final opponentName = _pickOpponentName(opponentPokemon.name, rankedTopic.title);

    final playerMaxHp = _scaledPlayerHp(player);
    final opponentMaxHp = _scaledOpponentHp(opponentPokemon, rankedTopic, ranked: true);

    if (!mounted) return;
    setState(() {
      _battle = _RankedBattleState(
        rankedTopic: rankedTopic,
        playerTopic: playerTopic,
        player: player,
        opponentPokemon: opponentPokemon,
        opponentName: opponentName,
        playerMaxHp: playerMaxHp,
        opponentMaxHp: opponentMaxHp,
      );
      _playerHp = playerMaxHp;
      _opponentHp = opponentMaxHp;
      _playerCorrect = 0;
      _opponentCorrect = 0;
      _battleResolved = false;
      _rewarding = false;
      _rewardGranted = false;
      _wonBattle = null;
      _earnedReward = null;
      _battleLog =
          'Ranked topic locked: ${rankedTopic.title}. $opponentName is battling on the same subject.';
    });
  }

  Future<StudyTopic> _ensureBattleModule(StudyTopic topic) async {
    if (topic.isOwnedByUser) {
      return _topicService.fetchModuleDetail(topic.id);
    }

    return _topicService.createModule(
      title: topic.title,
      topic: topic.topic,
      summary: topic.summary,
      difficulty: topic.difficulty,
      category: topic.category,
      lessons: topic.lessons,
      sourceType: 'topic',
      linkedTopicId: topic.id,
    );
  }

  Future<void> _ensureQuestionsForModule(StudyTopic topic) async {
    try {
      final existing = await _supabase
          .from('questions')
          .select('id')
          .eq('module_id', topic.id)
          .limit(1);
      if (existing.isNotEmpty) return;

      final lessonTitles = topic.lessons
          .map((lesson) => lesson.title.trim())
          .where((title) => title.isNotEmpty)
          .toList();
      final source = lessonTitles.isNotEmpty
          ? lessonTitles
          : <String>[
              topic.title,
              '${topic.topic} Basics',
              '${topic.category} Review',
              'General Practice',
            ];

      final payload = <Map<String, dynamic>>[];
      for (var index = 0; index < source.length && index < 6; index++) {
        final correct = source[index];
        final distractors = source.where((entry) => entry != correct).take(3).toList();
        while (distractors.length < 3) {
          distractors.add('Extra Review ${distractors.length + 1}');
        }
        payload.add({
          'module_id': topic.id,
          'question_text': 'Which lesson belongs to ${topic.title}?',
          'question_type': 'mcq',
          'choices': {correct, ...distractors}.take(4).toList(),
          'correct_answer': correct,
          'explanation': 'This lesson is part of the selected training module.',
          'difficulty': _normalizedDifficulty(topic.difficulty),
          'order_index': index,
        });
      }

      if (payload.isNotEmpty) {
        await _supabase.from('questions').insert(payload);
      }
    } catch (_) {
      // Let the question widget surface the true issue if seeding fails.
    }
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

    final pokemon = starterCreatures
        .where((entry) => entry.id == (row['pokemon_id'] as String?))
        .firstOrNull;
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
    final pokemon = starterCreatures.firstWhere(
      (entry) => entry.id == 'charmander2',
      orElse: () => starterCreatures.first,
    );
    return _PlayerBattlePokemon(
      ownedPokemonId: null,
      pokemon: pokemon,
      level: 10,
      xp: 0,
      nickname: null,
      storedHp: pokemon.baseHp,
    );
  }

  Pokemon _pickOpponentPokemon(Pokemon playerPokemon) {
    final differentType = starterCreatures.where(
      (pokemon) =>
          pokemon.id != playerPokemon.id &&
          pokemon.type.split('/').first.toLowerCase() !=
              playerPokemon.type.split('/').first.toLowerCase() &&
          pokemon.evolution >= 2,
    );
    return differentType.firstOrNull ?? starterCreatures.last;
  }

  String _pickOpponentName(String pokemonName, String topicTitle) {
    final pool = [
      'Elite Kael',
      'Captain Veya',
      'Ranger Sol',
      'Ace Juno',
    ];
    final seed = (pokemonName.length + topicTitle.length) % pool.length;
    return pool[seed];
  }

  int _scaledPlayerHp(_PlayerBattlePokemon player) {
    return math.max(
      player.storedHp,
      player.pokemon.baseHp + (player.level * 14) + (player.pokemon.evolution * 20),
    );
  }

  int _scaledOpponentHp(
    Pokemon pokemon,
    StudyTopic topic, {
    bool ranked = false,
  }) {
    final difficultyBonus = switch (topic.difficulty.toLowerCase()) {
      'easy' => 10,
      'normal' => 24,
      'hard' => 38,
      'exam' => 50,
      _ => 24,
    };
    final rankedBonus = ranked ? 28 : 0;
    return pokemon.baseHp + 110 + (pokemon.evolution * 30) + difficultyBonus + rankedBonus;
  }

  ArenaQuestionTurnDecision _handleAnswerResolved(ArenaAnswerResolution resolution) {
    final battle = _battle;
    if (battle == null || _battleResolved) {
      return ArenaQuestionTurnDecision.finishAttempt;
    }

    final playerMultiplier = _typeEffectiveness(
      battle.player.pokemon.type,
      battle.opponentPokemon.type,
    );
    final opponentMultiplier = _typeEffectiveness(
      battle.opponentPokemon.type,
      battle.player.pokemon.type,
    );

    var nextPlayerHp = _playerHp;
    var nextOpponentHp = _opponentHp;
    var nextPlayerCorrect = _playerCorrect;
    var nextOpponentCorrect = _opponentCorrect;
    var nextLog = '';

    if (resolution.isCorrect) {
      nextPlayerCorrect += 1;
      final damage = _playerDamage(
        player: battle.player,
        opponent: battle.opponentPokemon,
        typeMultiplier: playerMultiplier,
        rankedTopic: battle.rankedTopic,
      );
      nextOpponentHp = math.max(0, nextOpponentHp - damage);
      nextLog =
          '${battle.player.displayName} answered correctly and dealt $damage ranked damage.';
    } else {
      nextLog = '${battle.player.displayName} missed the ranked question and lost the turn.';
    }

    if (nextOpponentHp > 0) {
      final opponentAnswersCorrectly = _simulateOpponentCorrectAnswer(
        battle: battle,
        roundIndex: resolution.questionIndex,
      );

      if (opponentAnswersCorrectly) {
        nextOpponentCorrect += 1;
        final damage = _opponentDamage(
          player: battle.player,
          opponent: battle.opponentPokemon,
          topic: battle.rankedTopic,
          typeMultiplier: opponentMultiplier,
          ranked: true,
        );
        nextPlayerHp = math.max(0, nextPlayerHp - damage);
        nextLog =
            '$nextLog ${battle.opponentName} answered back and dealt $damage damage.';
      } else {
        nextLog = '$nextLog ${battle.opponentName} missed their response turn.';
      }
    }

    setState(() {
      _playerHp = nextPlayerHp;
      _opponentHp = nextOpponentHp;
      _playerCorrect = nextPlayerCorrect;
      _opponentCorrect = nextOpponentCorrect;
      _battleLog = nextLog;
    });

    if (_playerHp <= 0 || _opponentHp <= 0) {
      _finalizeBattleFromBoard();
      return ArenaQuestionTurnDecision.finishAttempt;
    }

    return ArenaQuestionTurnDecision.continueQuiz;
  }

  Future<void> _handleQuestionCompleted(ArenaQuestionResult result) async {
    if (_battleResolved) return;
    _finalizeBattleFromBoard(fallbackAccuracy: result.accuracy);
  }

  void _finalizeBattleFromBoard({double? fallbackAccuracy}) {
    final battle = _battle;
    if (battle == null || _battleResolved) return;

    final won = _opponentHp <= 0
        ? true
        : _playerHp <= 0
            ? false
            : _playerCorrect >= _opponentCorrect;

    final performance = fallbackAccuracy ??
        (_playerCorrect + _opponentCorrect == 0
            ? 0.5
            : _playerCorrect / (_playerCorrect + _opponentCorrect));

    _resolveBattle(
      won: won,
      battle: battle,
      performance: performance,
    );
  }

  Future<void> _resolveBattle({
    required bool won,
    required _RankedBattleState battle,
    required double performance,
  }) async {
    if (_battleResolved) return;

    setState(() {
      _battleResolved = true;
      _wonBattle = won;
    });

    final baseReward = won ? rollPveReward(performance: performance) : const Reward();
    final reward = won
        ? baseReward.copyWith(
            xp: baseReward.xp + (battle.player.level * 18),
            coins: baseReward.coins + (battle.player.level * 24),
            diamonds: baseReward.diamonds + 1,
          )
        : const Reward();

    setState(() {
      _earnedReward = reward;
      _battleLog = won
          ? '${battle.player.displayName} won the ranked match $_playerCorrect to $_opponentCorrect.'
          : '${battle.opponentName} won the ranked match $_opponentCorrect to $_playerCorrect.';
    });

    await _persistOutcome(
      won: won,
      battle: battle,
      reward: reward,
    );
  }

  Future<void> _persistOutcome({
    required bool won,
    required _RankedBattleState battle,
    required Reward reward,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (won && !_rewardGranted) {
      setState(() => _rewarding = true);
      try {
        await _inventoryService.grantReward(reward);
        _rewardGranted = true;
      } catch (_) {
        // Keep match results visible even if reward grant fails.
      } finally {
        if (mounted) {
          setState(() => _rewarding = false);
        }
      }
    }

    try {
      await _supabase.from('battle_history').insert({
        'user_id': user.id,
        'opponent_name': battle.opponentName,
        'battle_type': 'pvp_ranked',
        'won': won,
        'xp_earned': reward.xp,
        'coins_earned': reward.coins,
      });
    } catch (_) {
      // Non-blocking history write.
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

  int _playerDamage({
    required _PlayerBattlePokemon player,
    required Pokemon opponent,
    required double typeMultiplier,
    required StudyTopic rankedTopic,
  }) {
    final rankedBonus = switch (rankedTopic.difficulty.toLowerCase()) {
      'easy' => 1.0,
      'normal' => 1.08,
      'hard' => 1.15,
      'exam' => 1.22,
      _ => 1.08,
    };
    final raw = ((player.pokemon.baseAttack + (player.level * 4.5)) -
            (opponent.baseDefense * 0.28)) *
        typeMultiplier *
        rankedBonus;
    return math.max(30, raw.round());
  }

  int _opponentDamage({
    required _PlayerBattlePokemon player,
    required Pokemon opponent,
    required StudyTopic topic,
    required double typeMultiplier,
    required bool ranked,
  }) {
    final topicBonus = switch (topic.difficulty.toLowerCase()) {
      'easy' => 1.0,
      'normal' => 1.06,
      'hard' => 1.12,
      'exam' => 1.2,
      _ => 1.06,
    };
    final rankedBonus = ranked ? 1.08 : 1.0;
    final raw = ((opponent.baseAttack + (opponent.baseSpeed * 0.34)) -
            (player.pokemon.baseDefense * 0.22)) *
        typeMultiplier *
        topicBonus *
        rankedBonus;
    return math.max(28, raw.round());
  }

  bool _simulateOpponentCorrectAnswer({
    required _RankedBattleState battle,
    required int roundIndex,
  }) {
    final baseChance = switch (battle.rankedTopic.difficulty.toLowerCase()) {
      'easy' => 0.74,
      'normal' => 0.67,
      'hard' => 0.58,
      'exam' => 0.51,
      _ => 0.64,
    };
    final statBonus = (battle.opponentPokemon.baseSpeed + battle.opponentPokemon.baseAttack) / 380;
    final wobble = ((roundIndex % 4) - 1) * 0.04;
    final finalChance = (baseChance + statBonus + wobble).clamp(0.25, 0.92);
    final deterministic = ((battle.opponentName.length +
                roundIndex +
                battle.opponentPokemon.id.length +
                battle.rankedTopic.title.length) %
            10) /
        10;
    return deterministic < finalChance;
  }

  String _normalizedDifficulty(String difficulty) {
    final value = difficulty.trim().toLowerCase();
    if (const {'easy', 'normal', 'hard', 'exam'}.contains(value)) return value;
    return 'normal';
  }

  double _typeEffectiveness(String attackType, String targetType) {
    final attack = attackType.split('/').first.trim().toLowerCase();
    final targets =
        targetType.split('/').map((part) => part.trim().toLowerCase()).toList();
    double multiplier = 1.0;

    for (final target in targets) {
      if (attack == 'fire' && target == 'grass') multiplier *= 1.4;
      if (attack == 'water' && (target == 'fire' || target == 'ground')) {
        multiplier *= 1.35;
      }
      if (attack == 'electric' && (target == 'water' || target == 'flying')) {
        multiplier *= 1.45;
      }
      if (attack == 'grass' && (target == 'water' || target == 'ground')) {
        multiplier *= 1.35;
      }
      if (attack == 'psychic' && (target == 'fighting' || target == 'poison')) {
        multiplier *= 1.3;
      }
      if (attack == 'ghost' && (target == 'psychic' || target == 'ghost')) {
        multiplier *= 1.35;
      }
      if (attack == 'dragon' && target == 'dragon') multiplier *= 1.4;
      if (attack == 'fire' && (target == 'water' || target == 'fire')) multiplier *= 0.78;
      if (attack == 'water' && (target == 'grass' || target == 'electric')) {
        multiplier *= 0.82;
      }
      if (attack == 'electric' && target == 'ground') multiplier *= 0.65;
      if (attack == 'grass' && (target == 'fire' || target == 'flying')) {
        multiplier *= 0.8;
      }
    }

    return multiplier.clamp(0.65, 1.75);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _battle == null ? _buildLobbyView() : _buildBattleView(),
      ),
    );
  }

  Widget _buildLobbyView() {
    return FutureBuilder<_RankedLobbyState>(
      future: _lobbyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                snapshot.error.toString().replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
            ),
          );
        }

        final lobby = snapshot.data!;
        return Stack(
          children: [
            const Positioned.fill(child: _RankedBackground()),
            RefreshIndicator(
              onRefresh: _refreshLobby,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _RankedHeader(
                    totalTopics: lobby.totalTopics,
                    rankedTopic: lobby.rankedTopic,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  StudyTopicCard(
                    topic: lobby.rankedTopic,
                    badgeLabel: 'Ranked Topic - ${lobby.rankedTopic.category}',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _RankedRuleCard(topic: lobby.rankedTopic),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () => _startRankedMatch(lobby.rankedTopic),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC95B),
                      foregroundColor: const Color(0xFF141A22),
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: Text(
                      'Start Ranked Match',
                      style: AppTextStyles.button.copyWith(
                        color: const Color(0xFF141A22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBattleView() {
    final battle = _battle!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: _RankedBattlefield(
              battle: battle,
              playerHp: _playerHp,
              opponentHp: _opponentHp,
              playerCorrect: _playerCorrect,
              opponentCorrect: _opponentCorrect,
              battleLog: _battleLog,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 10,
            child: _battleResolved
                ? _RankedResultPanel(
                    won: _wonBattle ?? false,
                    reward: _earnedReward,
                    rewarding: _rewarding,
                    playerCorrect: _playerCorrect,
                    opponentCorrect: _opponentCorrect,
                    onBack: () => Navigator.of(context).pop(),
                  )
                : ArenaQuestionWidget(
                    moduleId: battle.playerTopic.id,
                    supabase: _supabase,
                    onAnswerResolved: _handleAnswerResolved,
                    onCompleted: _handleQuestionCompleted,
                  ),
          ),
        ],
      ),
    );
  }
}

class _RankedHeader extends StatelessWidget {
  final int totalTopics;
  final StudyTopic rankedTopic;

  const _RankedHeader({
    required this.totalTopics,
    required this.rankedTopic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.primary.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ranked Queue',
            style: AppTextStyles.title.copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Today\'s ranked topic is pulled at random from the arena database and both trainers fight on the same subject.',
            style: AppTextStyles.body.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$totalTopics topics in rotation | ${rankedTopic.difficulty.toUpperCase()}',
            style: AppTextStyles.button.copyWith(fontSize: 13, color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

class _RankedRuleCard extends StatelessWidget {
  final StudyTopic topic;

  const _RankedRuleCard({
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ranked Rules',
            style: AppTextStyles.button.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Topic shown on load: ${topic.title}',
            style: AppTextStyles.body.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            'Both trainers answer questions from this same topic. Higher pressure, stronger rewards, and no topic picking.',
            style: AppTextStyles.body.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RankedBattlefield extends StatelessWidget {
  final _RankedBattleState battle;
  final int playerHp;
  final int opponentHp;
  final int playerCorrect;
  final int opponentCorrect;
  final String battleLog;

  const _RankedBattlefield({
    required this.battle,
    required this.playerHp,
    required this.opponentHp,
    required this.playerCorrect,
    required this.opponentCorrect,
    required this.battleLog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6FC7F1),
            Color(0xFF9EE6FF),
            Color(0xFFFFD86F),
            Color(0xFF714C21),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              top: 28,
              right: 40,
              child: Container(
                width: 168,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Positioned(
              left: 70,
              right: 70,
              top: 150,
              child: Container(
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A84A).withOpacity(0.84),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Positioned(
              left: 30,
              right: 30,
              bottom: 132,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: PokemonBattleSprite(
                      pokemon: battle.player.pokemon,
                      displayName:
                          '${battle.player.displayName} Lv.${battle.player.level}',
                      currentHp: playerHp,
                      maxHp: battle.playerMaxHp,
                      side: BattleSpriteSide.left,
                      width: 248,
                      height: 280,
                      badge: _RankedMiniBadge(
                        label: '${battle.rankedTopic.topic} | $playerCorrect',
                        color: const Color(0xFF1F4B89),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PokemonBattleSprite(
                      pokemon: battle.opponentPokemon,
                      displayName: battle.opponentName,
                      currentHp: opponentHp,
                      maxHp: battle.opponentMaxHp,
                      side: BattleSpriteSide.right,
                      width: 248,
                      height: 280,
                      badge: _RankedMiniBadge(
                        label: '${battle.rankedTopic.topic} | $opponentCorrect',
                        color: const Color(0xFF87451E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              top: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Ranked Topic: ${battle.rankedTopic.title}',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF3B4350), width: 3),
                ),
                child: Text(
                  battleLog,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    color: const Color(0xFF39424F),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankedResultPanel extends StatelessWidget {
  final bool won;
  final Reward? reward;
  final bool rewarding;
  final int playerCorrect;
  final int opponentCorrect;
  final VoidCallback onBack;

  const _RankedResultPanel({
    required this.won,
    required this.reward,
    required this.rewarding,
    required this.playerCorrect,
    required this.opponentCorrect,
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
                  Color(0xFF143225),
                  Color(0xFF1F4F39),
                  Color(0xFF2A6C51),
                ]
              : const [
                  Color(0xFF34151C),
                  Color(0xFF4C2128),
                  Color(0xFF6A2E35),
                ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            won ? 'Ranked Win' : 'Ranked Loss',
            style: AppTextStyles.title.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Final score: $playerCorrect - $opponentCorrect',
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
              child: reward == null || reward!.isEmpty
                  ? Center(
                      child: Text(
                        won ? 'Rewards are being prepared.' : 'No rewards this match.',
                        style: AppTextStyles.body.copyWith(fontSize: 13),
                      ),
                    )
                  : _RankedRewardSummary(reward: reward!),
            ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onBack,
              style: FilledButton.styleFrom(
                backgroundColor: won ? const Color(0xFF49D58A) : const Color(0xFFFF8A80),
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

class _RankedRewardSummary extends StatelessWidget {
  final Reward reward;

  const _RankedRewardSummary({
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RankedRewardRow(label: 'XP', value: '${reward.xp}'),
          _RankedRewardRow(label: 'Coins', value: '${reward.coins}'),
          _RankedRewardRow(label: 'Diamonds', value: '${reward.diamonds}'),
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
                child: _RankedRewardRow(
                  label: item.name,
                  value: 'x${item.quantity}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RankedRewardRow extends StatelessWidget {
  final String label;
  final String value;

  const _RankedRewardRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
    );
  }
}

class _RankedMiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _RankedMiniBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RankedBackground extends StatelessWidget {
  const _RankedBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF221C38),
            Color(0xFF131226),
            Color(0xFF080A13),
          ],
        ),
      ),
    );
  }
}

class _RankedLobbyState {
  final StudyTopic rankedTopic;
  final int totalTopics;

  const _RankedLobbyState({
    required this.rankedTopic,
    required this.totalTopics,
  });
}

class _RankedBattleState {
  final StudyTopic rankedTopic;
  final StudyTopic playerTopic;
  final _PlayerBattlePokemon player;
  final Pokemon opponentPokemon;
  final String opponentName;
  final int playerMaxHp;
  final int opponentMaxHp;

  const _RankedBattleState({
    required this.rankedTopic,
    required this.playerTopic,
    required this.player,
    required this.opponentPokemon,
    required this.opponentName,
    required this.playerMaxHp,
    required this.opponentMaxHp,
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
