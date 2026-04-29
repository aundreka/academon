class Pokemon {
  final String id;
  final String name;
  final String type;
  final String rarity;
  final int baseHp;
  final int baseAttack;
  final int baseDefense;
  final int baseSpeed;
  final int evolution;
  final String imagePath;
  final String description;

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
  });
}