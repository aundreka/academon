import 'dart:math';

import 'item.dart';

class Reward {
  final int xp;
  final int coins;
  final int diamonds;
  final List<InventoryItem> items;

  const Reward({
    this.xp = 0,
    this.coins = 0,
    this.diamonds = 0,
    this.items = const [],
  });

  bool get hasItems => items.isNotEmpty;

  bool get isEmpty =>
      xp <= 0 && coins <= 0 && diamonds <= 0 && items.isEmpty;

  Reward copyWith({
    int? xp,
    int? coins,
    int? diamonds,
    List<InventoryItem>? items,
  }) {
    return Reward(
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      diamonds: diamonds ?? this.diamonds,
      items: items ?? this.items,
    );
  }

  Reward operator +(Reward other) {
    return Reward(
      xp: xp + other.xp,
      coins: coins + other.coins,
      diamonds: diamonds + other.diamonds,
      items: [...items, ...other.items],
    );
  }
}

class RewardRange {
  final int min;
  final int max;

  const RewardRange({
    required this.min,
    required this.max,
  }) : assert(min <= max, 'min must be less than or equal to max');

  int roll(Random random) {
    if (min == max) {
      return min;
    }

    return min + random.nextInt((max - min) + 1);
  }
}

class RewardDrop {
  final InventoryItem item;
  final double chance;
  final int minQuantity;
  final int maxQuantity;

  const RewardDrop({
    required this.item,
    required this.chance,
    this.minQuantity = 1,
    this.maxQuantity = 1,
  }) : assert(chance >= 0 && chance <= 1, 'chance must be between 0 and 1');

  InventoryItem? roll(Random random) {
    if (random.nextDouble() > chance) {
      return null;
    }

    final quantity = minQuantity == maxQuantity
        ? minQuantity
        : minQuantity + random.nextInt((maxQuantity - minQuantity) + 1);
    return item.copyWith(quantity: quantity);
  }
}

class RewardScenario {
  final String id;
  final String label;
  final RewardRange xp;
  final RewardRange coins;
  final RewardRange diamonds;
  final List<RewardDrop> drops;

  const RewardScenario({
    required this.id,
    required this.label,
    this.xp = const RewardRange(min: 0, max: 0),
    this.coins = const RewardRange(min: 0, max: 0),
    this.diamonds = const RewardRange(min: 0, max: 0),
    this.drops = const [],
  });

  Reward roll(Random random) {
    final rolledItems = <InventoryItem>[];
    for (final drop in drops) {
      final item = drop.roll(random);
      if (item != null) {
        rolledItems.add(item);
      }
    }

    return Reward(
      xp: xp.roll(random),
      coins: coins.roll(random),
      diamonds: diamonds.roll(random),
      items: rolledItems,
    );
  }
}
