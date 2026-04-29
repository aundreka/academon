import '../models/boss.dart';
import '../models/item.dart';
import 'boss_abilities.dart';

const worldBosses = [
  Boss(
    id: 'boss_mewtwo',
    name: 'Shadow Mewtwo',
    type: 'Psychic',
    maxHp: 2500, // Massive HP compared to Abra's 25
    baseAttack: 150,
    baseDefense: 100,
    imagePath: 'bosses/mewtwo.png',
    description: 'The ultimate psychic lifeform. It challenges your core knowledge.',
    abilities: [pressure, confuse],
    xpReward: 500,
    coinReward: 1000,
    rewards: [
      InventoryItem(id: 'rare_candy', name: 'Rare Candy', type: 'boost', quantity: 3),
      InventoryItem(id: 'diamond_key', name: 'Diamond Key', type: 'ticket', quantity: 1),
    ],
  ),
  
  Boss(
    id: 'boss_groudon',
    name: 'Primal Groudon',
    type: 'Ground/Fire',
    maxHp: 4000,
    baseAttack: 180,
    baseDefense: 200,
    imagePath: 'bosses/groudon.png',
    description: 'A titan of the earth. One wrong answer will trigger a cataclysm.',
    abilities: [earthquake, pressure, recovery],
    xpReward: 1200,
    coinReward: 2500,
    rewards: [
      InventoryItem(id: 'mega_stone', name: 'Charizardite', type: 'special', quantity: 1),
      InventoryItem(id: 'gold_potion', name: 'Max Potion', type: 'potion', quantity: 5),
    ],
  ),

Boss(
    id: 'boss_kyogre',
    name: 'Primal Kyogre',
    type: 'Water',
    maxHp: 3800,
    baseAttack: 170,
    baseDefense: 150,
    imagePath: 'bosses/kyogre.png',
    description: 'The sea basin Pokémon. It floods the battlefield, making it harder to focus.',
    abilities: [stormSurge, pressure],
    xpReward: 1100,
    coinReward: 2200,
    rewards: [
      InventoryItem(id: 'mystic_water', name: 'Mystic Water', type: 'boost', quantity: 1),
      InventoryItem(id: 'blue_orb', name: 'Blue Orb', type: 'special', quantity: 1),
    ],
  ),
  
  Boss(
    id: 'boss_rayquaza',
    name: 'Mega Rayquaza',
    type: 'Dragon/Flying',
    maxHp: 3500,
    baseAttack: 210, // Extremely high attack
    baseDefense: 120,
    imagePath: 'bosses/rayquaza.png',
    description: 'An apex predator from the ozone layer. It strikes with blinding speed.',
    abilities: [pressure, frostBite],
    xpReward: 1500,
    coinReward: 3000,
    rewards: [
      InventoryItem(id: 'dragon_scale', name: 'Dragon Scale', type: 'boost', quantity: 2),
      InventoryItem(id: 'sky_pillar_pass', name: 'Sky Pass', type: 'ticket', quantity: 1),
    ],
  ),

  Boss(
    id: 'boss_celebi',
    name: 'Ancient Celebi',
    type: 'Psychic/Grass',
    maxHp: 3200,
    baseAttack: 130,
    baseDefense: 180,
    imagePath: 'bosses/celebi.png',
    description: 'The guardian of the forest. It manipulates time to heal its wounds.',
    abilities: [photosynthesis, recovery, confuse],
    xpReward: 1000,
    coinReward: 2000,
    rewards: [
      InventoryItem(id: 'time_flute', name: 'Time Flute', type: 'support', quantity: 1),
      InventoryItem(id: 'revive_seed', name: 'Revive Seed', type: 'potion', quantity: 3),
    ],
  ),
];
