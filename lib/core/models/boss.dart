import 'ability.dart';
import 'user.dart'; 

class Boss {
  final String id;
  final String name;
  final String type;
  
  // Bosses have much higher HP than regular Pokemon
  final int maxHp;
  final int baseAttack;
  final int baseDefense;
  
  final String imagePath;
  final String description;

  /// Abilities the boss can use during the quiz battle
  final List<Ability> abilities;

  /// Items the player gets for winning
  final List<InventoryItem> rewards;
  final int xpReward;
  final int coinReward;

  const Boss({
    required this.id,
    required this.name,
    required this.type,
    required this.maxHp,
    required this.baseAttack,
    required this.baseDefense,
    required this.imagePath,
    required this.description,
    this.abilities = const [],
    this.rewards = const [],
    required this.xpReward,
    required this.coinReward,
  });
}