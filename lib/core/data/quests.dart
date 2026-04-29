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
];
