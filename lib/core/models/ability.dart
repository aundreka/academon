class Ability {
  final String id;
  final String name;
  final String type; // attack, defense, support
  final String description;

  const Ability({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
  });
}