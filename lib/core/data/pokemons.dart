import '../models/pokemon.dart';
import '../data/abilities.dart';

const starterCreatures = [
  Pokemon(
    id: 'geofox small',
    name: 'Geofox',
    type: 'Core',
    rarity: 'Common',
    baseHp: 100,
    baseAttack: 25,
    baseDefense: 20,
    evolution: 1,
    baseSpeed: 30,
    imagePath: 'assets/pokemons/geofox.png',
    description: 'A curious fox born from basic knowledge energy.',
    abilitiesByEvolution: {
    1: [shield],                 // base
    2: [shield, timeRewind],     // evolved
    3: [shield, timeRewind],     // max
  },
  ),
   Pokemon(
    id: 'geofox medium',
    name: 'Geofox',
    type: 'Core',
    rarity: 'Common',
    baseHp: 100,
    baseAttack: 25,
    baseDefense: 20,
    evolution: 1,
    baseSpeed: 30,
    imagePath: 'assets/pokemons/geofox.png',
    description: 'A curious fox born from basic knowledge energy.',
  ),
   Pokemon(
    id: 'geofox large',
    name: 'Geofox',
    type: 'Core',
    rarity: 'Common',
    baseHp: 100,
    baseAttack: 25,
    baseDefense: 20,
    evolution: 1,
    baseSpeed: 30,
    imagePath: 'assets/pokemons/geofox.png',
    description: 'A curious fox born from basic knowledge energy.',
  ),
];