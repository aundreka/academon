import 'reward.dart';

enum QuestRarity {
  common(0.55),
  uncommon(0.3),
  rare(0.11),
  epic(0.035),
  legendary(0.005);

  const QuestRarity(this.dailyAppearChance);

  final double dailyAppearChance;
}

extension QuestRarityX on QuestRarity {
  String get label {
    switch (this) {
      case QuestRarity.common:
        return 'Common';
      case QuestRarity.uncommon:
        return 'Uncommon';
      case QuestRarity.rare:
        return 'Rare';
      case QuestRarity.epic:
        return 'Epic';
      case QuestRarity.legendary:
        return 'Legendary';
    }
  }
}

class Quest {
  final String id;
  final String title;
  final String description;
  final Reward reward;
  final QuestRarity rarity;

  const Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.reward,
    this.rarity = QuestRarity.common,
  });

  double get appearanceChance => rarity.dailyAppearChance;
}
