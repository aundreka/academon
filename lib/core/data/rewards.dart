import 'dart:math';

import '../models/item.dart';
import '../models/reward.dart';

final InventoryItem commonQuestEgg = InventoryItem.egg(
  id: 'reward_egg_common',
  name: 'Campus Egg',
  imagePath: 'assets/items/common_egg.png',
  rarity: EggRarity.common,
  eggProgress: const EggProgress(
    subjectId: 'General Knowledge',
    hatchBattleRequirement: 3,
  ),
);

final InventoryItem uncommonQuestEgg = InventoryItem.egg(
  id: 'reward_egg_uncommon',
  name: 'Quiz Egg',
  imagePath: 'assets/items/common_egg.png',
  rarity: EggRarity.uncommon,
  coinValue: 900,
  diamondValue: 10,
  eggProgress: const EggProgress(
    subjectId: 'Literature',
    hatchBattleRequirement: 4,
  ),
);

final InventoryItem rareQuestEgg = InventoryItem.egg(
  id: 'reward_egg_rare',
  name: 'Scholar Egg',
  imagePath: 'assets/items/rare_egg.png',
  rarity: EggRarity.rare,
  coinValue: 1200,
  diamondValue: 12,
  eggProgress: const EggProgress(
    subjectId: 'Science',
    hatchBattleRequirement: 5,
  ),
);

final InventoryItem ultraRareQuestEgg = InventoryItem.egg(
  id: 'reward_egg_ultra_rare',
  name: 'Prism Egg',
  imagePath: 'assets/items/ultra_rare_egg.png',
  rarity: EggRarity.ultraRare,
  coinValue: 1800,
  diamondValue: 18,
  eggProgress: const EggProgress(
    subjectId: 'Botany',
    hatchBattleRequirement: 6,
  ),
);

final InventoryItem legendaryQuestEgg = InventoryItem.egg(
  id: 'reward_egg_legendary',
  name: 'Mythic Egg',
  imagePath: 'assets/items/legendary_egg.png',
  rarity: EggRarity.legendary,
  coinValue: 2400,
  diamondValue: 24,
  eggProgress: const EggProgress(
    subjectId: 'History',
    hatchBattleRequirement: 8,
  ),
);

final InventoryItem rewardXpBoostChip = InventoryItem.xpBoostChip(
  id: 'reward_xp_boost_chip',
  imagePath: 'assets/items/xp_boost_chip.png',
);

final InventoryItem rewardEnergyRefill = InventoryItem.energyRefill(
  id: 'reward_energy_refill',
  imagePath: 'assets/items/energy_refill.png',
);

final InventoryItem rewardBattleTicket = InventoryItem.battleTicket(
  id: 'reward_battle_ticket',
  imagePath: 'assets/items/battle_ticket.png',
);

final InventoryItem rewardEvolutionCore = InventoryItem.evolutionCore(
  id: 'reward_evolution_core',
  imagePath: 'assets/items/evolution_core.png',
);

final List<RewardScenario> pveRewardScenarios = [
  RewardScenario(
    id: 'pve_barely_cleared',
    label: 'Barely Cleared',
    xp: const RewardRange(min: 20, max: 80),
    coins: const RewardRange(min: 100, max: 300),
    diamonds: const RewardRange(min: 0, max: 2),
    drops: [
      RewardDrop(item: rewardEnergyRefill, chance: 0.08),
      RewardDrop(item: commonQuestEgg, chance: 0.02),
    ],
  ),
  RewardScenario(
    id: 'pve_steady_run',
    label: 'Steady Run',
    xp: const RewardRange(min: 70, max: 180),
    coins: const RewardRange(min: 250, max: 700),
    diamonds: const RewardRange(min: 0, max: 8),
    drops: [
      RewardDrop(item: rewardEnergyRefill, chance: 0.14),
      RewardDrop(item: rewardBattleTicket, chance: 0.08),
      RewardDrop(item: commonQuestEgg, chance: 0.04),
    ],
  ),
  RewardScenario(
    id: 'pve_strong_finish',
    label: 'Strong Finish',
    xp: const RewardRange(min: 150, max: 320),
    coins: const RewardRange(min: 700, max: 1400),
    diamonds: const RewardRange(min: 3, max: 18),
    drops: [
      RewardDrop(item: rewardXpBoostChip, chance: 0.18),
      RewardDrop(item: rewardBattleTicket, chance: 0.12),
      RewardDrop(item: uncommonQuestEgg, chance: 0.06),
      RewardDrop(item: rareQuestEgg, chance: 0.025),
    ],
  ),
  RewardScenario(
    id: 'pve_perfect_sweep',
    label: 'Perfect Sweep',
    xp: const RewardRange(min: 280, max: 500),
    coins: const RewardRange(min: 1200, max: 2000),
    diamonds: const RewardRange(min: 10, max: 30),
    drops: [
      RewardDrop(item: rewardXpBoostChip, chance: 0.25, minQuantity: 1, maxQuantity: 2),
      RewardDrop(item: rewardEnergyRefill, chance: 0.2),
      RewardDrop(item: rewardEvolutionCore, chance: 0.08),
      RewardDrop(item: uncommonQuestEgg, chance: 0.1),
      RewardDrop(item: rareQuestEgg, chance: 0.05),
      RewardDrop(item: ultraRareQuestEgg, chance: 0.015),
    ],
  ),
];

RewardScenario pveScenarioForPerformance(double performance) {
  final normalized = performance.clamp(0.0, 1.0);
  if (normalized >= 0.9) {
    return pveRewardScenarios[3];
  }
  if (normalized >= 0.65) {
    return pveRewardScenarios[2];
  }
  if (normalized >= 0.35) {
    return pveRewardScenarios[1];
  }
  return pveRewardScenarios[0];
}

Reward rollPveReward({
  required double performance,
  Random? random,
}) {
  final resolvedRandom = random ?? Random();
  return pveScenarioForPerformance(performance).roll(resolvedRandom);
}

Reward rewardForLevelUp(int level) {
  final safeLevel = level < 1 ? 1 : level;

  InventoryItem egg;
  if (safeLevel >= 40) {
    egg = legendaryQuestEgg;
  } else if (safeLevel >= 25) {
    egg = ultraRareQuestEgg;
  } else if (safeLevel >= 10) {
    egg = rareQuestEgg;
  } else if (safeLevel >= 5) {
    egg = uncommonQuestEgg;
  } else {
    egg = commonQuestEgg;
  }

  return Reward(
    xp: 50 + (safeLevel * 10),
    coins: 250 + (safeLevel * 60),
    diamonds: 2 + (safeLevel ~/ 4),
    items: [
      egg,
      if (safeLevel % 5 == 0) rewardXpBoostChip,
      if (safeLevel % 10 == 0) rewardEvolutionCore,
    ],
  );
}

final List<Reward> weeklyDailyClaimRewards = [
  const Reward(coins: 150, xp: 25),
  Reward(coins: 220, xp: 35, items: [rewardEnergyRefill]),
  const Reward(coins: 300, xp: 45, diamonds: 2),
  Reward(coins: 380, xp: 55, items: [rewardBattleTicket]),
  const Reward(coins: 450, xp: 70, diamonds: 4),
  Reward(coins: 600, xp: 90, items: [commonQuestEgg]),
  Reward(coins: 900, xp: 120, diamonds: 8, items: [legendaryQuestEgg]),
];
