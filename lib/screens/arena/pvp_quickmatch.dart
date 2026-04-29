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

class PvpQuickmatchScreen extends StatefulWidget {
  const PvpQuickmatchScreen({super.key});

  @override
  State<PvpQuickmatchScreen> createState() => _PvpScreenState();
}

class PvpScreen extends PvpQuickmatchScreen {
  const PvpScreen({super.key});
}

class _PvpScreenState extends State<PvpQuickmatchScreen> {
  late final SupabaseClient _supabase;
  late final StudyTopicService _topicService;
  late final ItemInventoryService _inventoryService;
  late Future<_QuickmatchLobbyData> _lobbyFuture;

  _QuickmatchBattleState? _battle;
  int _playerHp = 0;
  int _opponentHp = 0;
  int _playerCorrect = 0;
  int _opponentCorrect = 0;
  bool _battleResolved = false;
  bool _rewarding = false;
  bool _rewardGranted = false;
  bool? _wonBattle;
  Reward? _earnedReward;
  String _battleLog = 'Choose a module or topic to enter quickmatch.';

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _topicService = StudyTopicService(_supabase);
    _inventoryService = ItemInventoryService(_supabase);
    _lockLandscape();
    _lobbyFuture = _loadLobby();
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

  Future<_QuickmatchLobbyData> _loadLobby() async {
    final results = await Future.wait<dynamic>([
      _topicService.fetchUserModules(),
      _topicService.fetchAvailableTopics(),
    ]);

    final modules = List<StudyTopic>.from(results[0] as List<StudyTopic>);
    final topics = List<StudyTopic>.from(results[1] as List<StudyTopic>);

    modules.sort((a, b) => b.popularityCount.compareTo(a.popularityCount));
    topics.sort((a, b) => b.popularityCount.compareTo(a.popularityCount));

    return _QuickmatchLobbyData(modules: modules, topics: topics);
  }

  Future<void> _refreshLobby() async {
    final future = _loadLobby();
    setState(() => _lobbyFuture = future);
    await future;
  }

  Future<void> _startMatch(StudyTopic selectedTopic) async {
    final userBattleTopic = await _ensureBattleModule(selectedTopic);
    await _ensureQuestionsForModule(userBattleTopic);

    final player = await _loadPlayerPokemon();
    final lobby = await _loadLobby();
    final opponentTopic = _pickOpponentTopic(
      userTopicId: userBattleTopic.id,
      lobby: lobby,
    );
    final opponentPokemon = _pickOpponentPokemon(player.pokemon);
    final opponentName = _pickOpponentName(opponentPokemon.name, opponentTopic.title);

    final playerMaxHp = _scaledPlayerHp(player);
    final opponentMaxHp = _scaledOpponentHp(opponentPokemon, opponentTopic);

    if (!mounted) return;
    setState(() {
      _battle = _QuickmatchBattleState(
        playerTopic: userBattleTopic,
        opponentTopic: opponentTopic,
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
          '$opponentName selected ${opponentTopic.title}. Answer correctly to outscore them.';
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
      level: 8,
      xp: 0,
      nickname: null,
      storedHp: pokemon.baseHp,
    );
  }

  StudyTopic _pickOpponentTopic({
    required String userTopicId,
    required _QuickmatchLobbyData lobby,
  }) {
    final pool = <StudyTopic>[
      ...lobby.modules.where((topic) => topic.id != userTopicId),
      ...lobby.topics.where((topic) => topic.id != userTopicId),
    ];

    if (pool.isEmpty) {
      return StudyTopic(
        id: 'fallback-opponent-topic',
        ownerId: null,
        linkedTopicId: null,
        title: 'Quickmatch Review',
        topic: 'Arena Basics',
        category: 'Arena',
        difficulty: 'normal',
        summary: 'Fast-paced review topics for battle practice.',
        status: 'ready',
        sourceType: 'curated',
        imageUrl: '',
        fileUrl: null,
        popularityCount: 0,
        isOwnedByUser: false,
      );
    }

    return pool.first;
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
      'Trainer Nova',
      'Ace Mira',
      'Rival Kian',
      'Scout Lyra',
    ];
    final seed = (pokemonName.length + topicTitle.length) % pool.length;
    return pool[seed];
  }

  int _scaledPlayerHp(_PlayerBattlePokemon player) {
    return math.max(
      player.storedHp,
      player.pokemon.baseHp + (player.level * 12) + (player.pokemon.evolution * 18),
    );
  }

  int _scaledOpponentHp(Pokemon pokemon, StudyTopic topic) {
    final difficultyBonus = switch (topic.difficulty.toLowerCase()) {
      'easy' => 0,
      'normal' => 18,
      'hard' => 30,
      'exam' => 40,
      _ => 18,
    };
    return pokemon.baseHp + 90 + (pokemon.evolution * 28) + difficultyBonus;
  }

  ArenaQuestionTurnDecision _handleAnswerResolved(ArenaAnswerResolution resolution) {
    final battle = _battle;
    if (battle == null || _battleResolved) {
      return ArenaQuestionTurnDecision.finishAttempt;
    }

    final playerCorrect = resolution.isCorrect;
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

    if (playerCorrect) {
      nextPlayerCorrect += 1;
      final damage = _playerDamage(
        player: battle.player,
        opponent: battle.opponentPokemon,
        typeMultiplier: playerMultiplier,
      );
      nextOpponentHp = math.max(0, nextOpponentHp - damage);
      nextLog =
          '${battle.player.displayName} answered correctly and dealt $damage damage.';
    } else {
      nextLog = '${battle.player.displayName} missed the question and lost the turn.';
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
          topic: battle.opponentTopic,
          typeMultiplier: opponentMultiplier,
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
    required _QuickmatchBattleState battle,
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
            xp: baseReward.xp + (battle.player.level * 12),
            coins: baseReward.coins + (battle.player.level * 18),
          )
        : const Reward();

    setState(() {
      _earnedReward = reward;
      _battleLog = won
          ? '${battle.player.displayName} won the quickmatch $_playerCorrect to $_opponentCorrect.'
          : '${battle.opponentName} won the quickmatch $_opponentCorrect to $_playerCorrect.';
    });

    await _persistOutcome(
      won: won,
      battle: battle,
      reward: reward,
    );
  }

  Future<void> _persistOutcome({
    required bool won,
    required _QuickmatchBattleState battle,
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
        'battle_type': 'pvp',
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
  }) {
    final raw = ((player.pokemon.baseAttack + (player.level * 4)) -
            (opponent.baseDefense * 0.3)) *
        typeMultiplier;
    return math.max(26, raw.round());
  }

  int _opponentDamage({
    required _PlayerBattlePokemon player,
    required Pokemon opponent,
    required StudyTopic topic,
    required double typeMultiplier,
  }) {
    final topicBonus = switch (topic.difficulty.toLowerCase()) {
      'easy' => 0.95,
      'normal' => 1.0,
      'hard' => 1.08,
      'exam' => 1.14,
      _ => 1.0,
    };
    final raw = ((opponent.baseAttack + (opponent.baseSpeed * 0.3)) -
            (player.pokemon.baseDefense * 0.24)) *
        typeMultiplier *
        topicBonus;
    return math.max(24, raw.round());
  }

  bool _simulateOpponentCorrectAnswer({
    required _QuickmatchBattleState battle,
    required int roundIndex,
  }) {
    final baseChance = switch (battle.opponentTopic.difficulty.toLowerCase()) {
      'easy' => 0.72,
      'normal' => 0.64,
      'hard' => 0.55,
      'exam' => 0.48,
      _ => 0.6,
    };
    final statBonus = (battle.opponentPokemon.baseSpeed + battle.opponentPokemon.baseAttack) / 400;
    final wobble = ((roundIndex % 3) - 1) * 0.05;
    final finalChance = (baseChance + statBonus + wobble).clamp(0.2, 0.9);
    final deterministic = ((battle.opponentName.length + roundIndex + battle.opponentPokemon.id.length) %
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
        child: _battle == null ? _buildSelectionView() : _buildBattleView(),
      ),
    );
  }

  Widget _buildSelectionView() {
    return FutureBuilder<_QuickmatchLobbyData>(
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

        final lobby = snapshot.data ?? const _QuickmatchLobbyData();
        final options = [...lobby.modules, ...lobby.topics];

        return Stack(
          children: [
            const Positioned.fill(child: _QuickmatchBackground()),
            RefreshIndicator(
              onRefresh: _refreshLobby,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _QuickmatchHeader(totalOptions: options.length),
                  const SizedBox(height: AppSpacing.md),
                  if (options.isEmpty)
                    const _QuickmatchEmptyCard(
                      message:
                          'No topics are available yet. Create or generate a module first, then return to quickmatch.',
                    )
                  else
                    ...options.map(
                      (topic) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: StudyTopicCard(
                          topic: topic,
                          badgeLabel: topic.isOwnedByUser
                              ? 'Your pick - ${topic.category}'
                              : '${topic.popularityCount} learners',
                          onTap: () => _startMatch(topic),
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
            child: _QuickmatchBattlefield(
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
                ? _QuickmatchResultPanel(
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

class _QuickmatchBattlefield extends StatelessWidget {
  final _QuickmatchBattleState battle;
  final int playerHp;
  final int opponentHp;
  final int playerCorrect;
  final int opponentCorrect;
  final String battleLog;

  const _QuickmatchBattlefield({
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
            Color(0xFF79DCF0),
            Color(0xFFADEBFF),
            Color(0xFF9CE485),
            Color(0xFF2E6431),
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
                width: 160,
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
                  color: const Color(0xFF73C35F).withOpacity(0.92),
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
                      badge: _MiniBattleBadge(
                        label: '${battle.playerTopic.topic} | $playerCorrect',
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
                      badge: _MiniBattleBadge(
                        label: '${battle.opponentTopic.topic} | $opponentCorrect',
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
                  '${battle.playerTopic.title} vs ${battle.opponentTopic.title}',
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

class _QuickmatchResultPanel extends StatelessWidget {
  final bool won;
  final Reward? reward;
  final bool rewarding;
  final int playerCorrect;
  final int opponentCorrect;
  final VoidCallback onBack;

  const _QuickmatchResultPanel({
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
                  Color(0xFF103225),
                  Color(0xFF1A4B38),
                  Color(0xFF266553),
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
            won ? 'Quickmatch Win' : 'Quickmatch Loss',
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
                  : _QuickmatchRewardSummary(reward: reward!),
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

class _QuickmatchRewardSummary extends StatelessWidget {
  final Reward reward;

  const _QuickmatchRewardSummary({
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuickmatchRewardRow(label: 'XP', value: '${reward.xp}'),
          _QuickmatchRewardRow(label: 'Coins', value: '${reward.coins}'),
          _QuickmatchRewardRow(label: 'Diamonds', value: '${reward.diamonds}'),
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
                child: _QuickmatchRewardRow(
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

class _QuickmatchRewardRow extends StatelessWidget {
  final String label;
  final String value;

  const _QuickmatchRewardRow({
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

class _QuickmatchHeader extends StatelessWidget {
  final int totalOptions;

  const _QuickmatchHeader({
    required this.totalOptions,
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
            'Quickmatch Queue',
            style: AppTextStyles.title.copyWith(fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pick a module or topic. Your opponent will queue with their own topic and Pokemon.',
            style: AppTextStyles.body.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$totalOptions battle-ready options',
            style: AppTextStyles.button.copyWith(fontSize: 13, color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

class _QuickmatchEmptyCard extends StatelessWidget {
  final String message;

  const _QuickmatchEmptyCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        message,
        style: AppTextStyles.body.copyWith(fontSize: 13),
      ),
    );
  }
}

class _MiniBattleBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBattleBadge({
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

class _QuickmatchBackground extends StatelessWidget {
  const _QuickmatchBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF17243D),
            Color(0xFF0D1628),
            Color(0xFF060A13),
          ],
        ),
      ),
    );
  }
}

class _QuickmatchLobbyData {
  final List<StudyTopic> modules;
  final List<StudyTopic> topics;

  const _QuickmatchLobbyData({
    this.modules = const <StudyTopic>[],
    this.topics = const <StudyTopic>[],
  });
}

class _QuickmatchBattleState {
  final StudyTopic playerTopic;
  final StudyTopic opponentTopic;
  final _PlayerBattlePokemon player;
  final Pokemon opponentPokemon;
  final String opponentName;
  final int playerMaxHp;
  final int opponentMaxHp;

  const _QuickmatchBattleState({
    required this.playerTopic,
    required this.opponentTopic,
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
