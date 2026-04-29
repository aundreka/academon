import 'dart:math';

import '../models/quest.dart';
import '../models/reward.dart';
import 'rewards.dart';

final List<Quest> dailyQuestCatalog = [
  Quest(
    id: 'quest_first_review',
    title: 'First Review',
    description: 'Complete 1 study review session.',
    reward: const Reward(
      xp: 40,
      coins: 180,
    ),
    rarity: QuestRarity.common,
  ),
  Quest(
    id: 'quest_focus_sprint',
    title: 'Focus Sprint',
    description: 'Finish a 15-minute focus timer without leaving the session.',
    reward: Reward(
      xp: 60,
      coins: 240,
      items: [rewardEnergyRefill],
    ),
    rarity: QuestRarity.common,
  ),
  Quest(
    id: 'quest_flashcard_chain',
    title: 'Flashcard Chain',
    description: 'Answer 20 flashcards in a single streak.',
    reward: const Reward(
      xp: 85,
      coins: 320,
      diamonds: 2,
    ),
    rarity: QuestRarity.uncommon,
  ),
  Quest(
    id: 'quest_two_victories',
    title: 'Double Victory',
    description: 'Win 2 PvE battles in one day.',
    reward: Reward(
      xp: 110,
      coins: 420,
      items: [rewardBattleTicket],
    ),
    rarity: QuestRarity.uncommon,
  ),
  Quest(
    id: 'quest_perfect_quiz',
    title: 'Perfect Quiz',
    description: 'Score 100% on a study activity with at least 10 prompts.',
    reward: Reward(
      xp: 140,
      coins: 520,
      diamonds: 4,
      items: [rewardXpBoostChip],
    ),
    rarity: QuestRarity.rare,
  ),
  Quest(
    id: 'quest_boss_warmup',
    title: 'Boss Warm-Up',
    description: 'Defeat 3 standard PvE opponents without losing a round.',
    reward: Reward(
      xp: 160,
      coins: 650,
      items: [commonQuestEgg],
    ),
    rarity: QuestRarity.rare,
  ),
  Quest(
    id: 'quest_study_marathon',
    title: 'Study Marathon',
    description: 'Accumulate 60 minutes of total focus time in one day.',
    reward: Reward(
      xp: 220,
      coins: 900,
      diamonds: 8,
      items: [uncommonQuestEgg],
    ),
    rarity: QuestRarity.epic,
  ),
  Quest(
    id: 'quest_clean_sweep',
    title: 'Clean Sweep',
    description: 'Win 5 battles in a row across any game mode.',
    reward: Reward(
      xp: 260,
      coins: 1100,
      diamonds: 10,
      items: [rareQuestEgg],
    ),
    rarity: QuestRarity.epic,
  ),
  Quest(
    id: 'quest_rank_climber',
    title: 'Rank Climber',
    description: 'Complete 3 PvP matches and win at least 2 of them.',
    reward: Reward(
      xp: 320,
      coins: 1400,
      diamonds: 12,
      items: [rewardEvolutionCore],
    ),
    rarity: QuestRarity.legendary,
  ),
  Quest(
    id: 'quest_master_scholar',
    title: 'Master Scholar',
    description: 'Finish a study session, a focus session, and a battle streak all in the same day.',
    reward: Reward(
      xp: 450,
      coins: 1800,
      diamonds: 20,
      items: [legendaryQuestEgg, rewardXpBoostChip],
    ),
    rarity: QuestRarity.legendary,
  ),
  // 🟢 COMMON
Quest(
  id: 'quest_quick_start',
  title: 'Quick Start',
  description: 'Answer 5 questions correctly.',
  reward: const Reward(
    xp: 30,
    coins: 120,
  ),
  rarity: QuestRarity.common,
),
Quest(
  id: 'quest_timer_touch',
  title: 'Timer Touch',
  description: 'Start a focus session of any length.',
  reward: const Reward(
    xp: 35,
    coins: 140,
  ),
  rarity: QuestRarity.common,
),
Quest(
  id: 'quest_light_battle',
  title: 'Light Battle',
  description: 'Win 1 PvE battle.',
  reward: Reward(
    xp: 50,
    coins: 200,
    items: [rewardEnergyRefill],
  ),
  rarity: QuestRarity.common,
),

// 🔵 UNCOMMON
Quest(
  id: 'quest_streak_builder',
  title: 'Streak Builder',
  description: 'Answer 10 questions in a row correctly.',
  reward: const Reward(
    xp: 90,
    coins: 350,
    diamonds: 2,
  ),
  rarity: QuestRarity.uncommon,
),
Quest(
  id: 'quest_double_focus',
  title: 'Double Focus',
  description: 'Complete 2 focus sessions in one day.',
  reward: Reward(
    xp: 110,
    coins: 420,
    items: [rewardXpBoostChip],
  ),
  rarity: QuestRarity.uncommon,
),
Quest(
  id: 'quest_battle_student',
  title: 'Battle Student',
  description: 'Win 3 PvE battles.',
  reward: Reward(
    xp: 120,
    coins: 480,
    items: [rewardBattleTicket],
  ),
  rarity: QuestRarity.uncommon,
),

// 🟣 RARE
Quest(
  id: 'quest_accuracy_master',
  title: 'Accuracy Master',
  description: 'Maintain 90% accuracy over 15 questions.',
  reward: Reward(
    xp: 150,
    coins: 600,
    diamonds: 4,
    items: [rewardXpBoostChip],
  ),
  rarity: QuestRarity.rare,
),
Quest(
  id: 'quest_combo_warrior',
  title: 'Combo Warrior',
  description: 'Achieve a 25-question combo streak.',
  reward: Reward(
    xp: 170,
    coins: 700,
    items: [commonQuestEgg],
  ),
  rarity: QuestRarity.rare,
),
Quest(
  id: 'quest_fast_thinker',
  title: 'Fast Thinker',
  description: 'Answer 10 questions under time pressure.',
  reward: const Reward(
    xp: 160,
    coins: 650,
    diamonds: 5,
  ),
  rarity: QuestRarity.rare,
),

// 🟠 EPIC
Quest(
  id: 'quest_battle_chain',
  title: 'Battle Chain',
  description: 'Win 7 battles without losing.',
  reward: Reward(
    xp: 250,
    coins: 1100,
    diamonds: 10,
    items: [rareQuestEgg],
  ),
  rarity: QuestRarity.epic,
),
Quest(
  id: 'quest_focus_master',
  title: 'Focus Master',
  description: 'Complete 3 long focus sessions (20+ minutes each).',
  reward: Reward(
    xp: 280,
    coins: 1200,
    diamonds: 12,
    items: [uncommonQuestEgg],
  ),
  rarity: QuestRarity.epic,
),
Quest(
  id: 'quest_knowledge_grind',
  title: 'Knowledge Grind',
  description: 'Answer 50 questions in a single day.',
  reward: Reward(
    xp: 300,
    coins: 1300,
    diamonds: 14,
    items: [rewardXpBoostChip],
  ),
  rarity: QuestRarity.epic,
),

// 🔴 LEGENDARY
Quest(
  id: 'quest_perfectionist',
  title: 'Perfectionist',
  description: 'Get 100% accuracy on 3 different sessions.',
  reward: Reward(
    xp: 400,
    coins: 1600,
    diamonds: 18,
    items: [rewardEvolutionCore],
  ),
  rarity: QuestRarity.legendary,
),
Quest(
  id: 'quest_unstoppable',
  title: 'Unstoppable',
  description: 'Win 10 battles in one day.',
  reward: Reward(
    xp: 450,
    coins: 1800,
    diamonds: 20,
    items: [legendaryQuestEgg],
  ),
  rarity: QuestRarity.legendary,
),
Quest(
  id: 'quest_grand_master',
  title: 'Grand Master',
  description: 'Complete 3 quests and 3 battles in one day.',
  reward: Reward(
    xp: 500,
    coins: 2000,
    diamonds: 25,
    items: [legendaryQuestEgg, rewardXpBoostChip],
  ),
  rarity: QuestRarity.legendary,
),
];

List<Quest> pickRandomDailyQuests({
  int count = 3,
  Random? random,
  Iterable<String> excludeIds = const [],
}) {
  final resolvedRandom = random ?? Random();
  final excluded = excludeIds.toSet();
  final available = dailyQuestCatalog
      .where((quest) => !excluded.contains(quest.id))
      .toList();

  if (available.length <= count) {
    available.shuffle(resolvedRandom);
    return available;
  }

  available.shuffle(resolvedRandom);
  return available.take(count).toList();
}
