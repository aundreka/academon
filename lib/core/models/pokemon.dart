import 'ability.dart';

class Pokemon {
  final String id;
  final String name;
  final String type;
  final String rarity;

  final int baseHp;
  final int baseAttack;
  final int baseDefense;
  final int baseSpeed;

  final int evolution; // current stage (1, 2, 3)

  final String imagePath;
  final String description;

  /// Flat ability list used by older seed data.
  final List<Ability> abilities;

  const Pokemon({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    required this.baseHp,
    required this.baseAttack,
    required this.baseDefense,
    required this.baseSpeed,
    required this.evolution,
    required this.imagePath,
    required this.description,
    this.abilities = const [],
  });
}
