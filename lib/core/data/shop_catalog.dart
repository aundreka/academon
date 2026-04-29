import '../models/item.dart';

final List<InventoryItem> shopEggCatalog = [
  InventoryItem.egg(
    id: 'egg_common_general',
    name: 'Starter Egg',
    imagePath: 'assets/items/common_egg.png',
    rarity: EggRarity.common,
    coinValue: 750,
    diamondValue: 8,
    eggProgress: const EggProgress(
      subjectId: 'General Knowledge',
      hatchBattleRequirement: 3,
    ),
  ),
  InventoryItem.egg(
    id: 'egg_rare_science',
    name: 'Scholar Egg',
    imagePath: 'assets/items/rare_egg.png',
    rarity: EggRarity.rare,
    coinValue: 1200,
    diamondValue: 12,
    eggProgress: const EggProgress(
      subjectId: 'Science',
      hatchBattleRequirement: 5,
    ),
  ),
  InventoryItem.egg(
    id: 'egg_ultra_rare_botany',
    name: 'Prism Egg',
    imagePath: 'assets/items/ultra_rare_egg.png',
    rarity: EggRarity.ultraRare,
    coinValue: 1800,
    diamondValue: 18,
    eggProgress: const EggProgress(
      subjectId: 'Botany',
      hatchBattleRequirement: 6,
    ),
  ),
  InventoryItem.egg(
    id: 'egg_legendary_history',
    name: 'Mythic Egg',
    imagePath: 'assets/items/legendary_egg.png',
    rarity: EggRarity.legendary,
    coinValue: 2400,
    diamondValue: 24,
    eggProgress: const EggProgress(
      subjectId: 'History',
      hatchBattleRequirement: 8,
    ),
  ),
];

final List<InventoryItem> shopItemCatalog = [
  InventoryItem.evolutionCore(
    id: 'evolution_core',
    imagePath: 'assets/items/evolution_core.png',
  ),
  InventoryItem.xpBoostChip(
    id: 'xp_boost_chip',
    imagePath: 'assets/items/xp_boost_chip.png',
  ),
  InventoryItem.energyRefill(
    id: 'energy_refill',
    imagePath: 'assets/items/energy_refill.png',
  ),
  InventoryItem.battleTicket(
    id: 'battle_ticket',
    imagePath: 'assets/items/battle_ticket.png',
  ),
];

final List<InventoryItem> shopCatalog = [
  ...shopEggCatalog,
  ...shopItemCatalog,
];

final Map<String, InventoryItem> shopCatalogById = {
  for (final item in shopCatalog) item.id: item,
};
