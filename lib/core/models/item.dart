enum ItemCategory {
  progression,
  consumable,
  access,
  special,
  support,
  potion,
  boost,
  ticket,
}

ItemCategory itemCategoryFromString(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'progression':
      return ItemCategory.progression;
    case 'access':
      return ItemCategory.access;
    case 'special':
      return ItemCategory.special;
    case 'support':
      return ItemCategory.support;
    case 'potion':
      return ItemCategory.potion;
    case 'boost':
      return ItemCategory.boost;
    case 'ticket':
      return ItemCategory.ticket;
    case 'consumable':
    default:
      return ItemCategory.consumable;
  }
}

enum InventoryItemType {
  generic,
  evolutionCore,
  xpBoostChip,
  egg,
  energyRefill,
  battleTicket,
}

InventoryItemType inventoryItemTypeFromString(String? value) {
  switch ((value ?? '').trim()) {
    case 'evolutionCore':
      return InventoryItemType.evolutionCore;
    case 'xpBoostChip':
      return InventoryItemType.xpBoostChip;
    case 'egg':
      return InventoryItemType.egg;
    case 'energyRefill':
      return InventoryItemType.energyRefill;
    case 'battleTicket':
      return InventoryItemType.battleTicket;
    case 'generic':
    default:
      return InventoryItemType.generic;
  }
}

enum EggRarity {
  common(Duration(minutes: 30)),
  uncommon(Duration(hours: 1)),
  rare(Duration(hours: 2)),
  ultraRare(Duration(hours: 4)),
  legendary(Duration(hours: 8));

  const EggRarity(this.hatchDuration);

  final Duration hatchDuration;
}

EggRarity eggRarityFromString(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'common':
      return EggRarity.common;
    case 'uncommon':
      return EggRarity.uncommon;
    case 'rare':
      return EggRarity.rare;
    case 'ultrarare':
    case 'ultra_rare':
    case 'ultra rare':
      return EggRarity.ultraRare;
    case 'legendary':
      return EggRarity.legendary;
    default:
      return EggRarity.common;
  }
}

extension EggRarityX on EggRarity {
  String get storageValue {
    switch (this) {
      case EggRarity.common:
        return 'common';
      case EggRarity.uncommon:
        return 'uncommon';
      case EggRarity.rare:
        return 'rare';
      case EggRarity.ultraRare:
        return 'ultra_rare';
      case EggRarity.legendary:
        return 'legendary';
    }
  }

  String get label {
    switch (this) {
      case EggRarity.common:
        return 'Common';
      case EggRarity.uncommon:
        return 'Uncommon';
      case EggRarity.rare:
        return 'Rare';
      case EggRarity.ultraRare:
        return 'Ultra Rare';
      case EggRarity.legendary:
        return 'Legendary';
    }
  }
}

enum BattleTicketMode {
  pvp,
  ranked,
  both,
}

BattleTicketMode battleTicketModeFromString(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'pvp':
      return BattleTicketMode.pvp;
    case 'ranked':
      return BattleTicketMode.ranked;
    case 'both':
    default:
      return BattleTicketMode.both;
  }
}

class XpBoostEffect {
  final double multiplier;
  final int battleCount;

  const XpBoostEffect({
    required this.multiplier,
    required this.battleCount,
  });
}

class EggProgress {
  final String? subjectId;
  final int hatchBattleRequirement;
  final Duration? hatchDuration;

  const EggProgress({
    this.subjectId,
    this.hatchBattleRequirement = 0,
    this.hatchDuration,
  });

  EggProgress copyWith({
    String? subjectId,
    int? hatchBattleRequirement,
    Duration? hatchDuration,
  }) {
    return EggProgress(
      subjectId: subjectId ?? this.subjectId,
      hatchBattleRequirement:
          hatchBattleRequirement ?? this.hatchBattleRequirement,
      hatchDuration: hatchDuration ?? this.hatchDuration,
    );
  }
}

class EnergyRefillEffect {
  final int restoreAmount;
  final bool restoresToFull;
  final bool pveOnly;

  const EnergyRefillEffect({
    this.restoreAmount = 0,
    this.restoresToFull = false,
    this.pveOnly = true,
  });
}

class BattleTicketAccess {
  final BattleTicketMode mode;
  final int requiredPerEntry;

  const BattleTicketAccess({
    this.mode = BattleTicketMode.both,
    this.requiredPerEntry = 1,
  });
}

class InventoryItem {
  final String id;
  final String name;
  final String type; // Backward-compatible string tag used by existing data.
  final int quantity;
  final String imagePath;
  final String description;
  final int coinValue;
  final int diamondValue;
  final ItemCategory category;
  final InventoryItemType itemType;
  final bool isPremium;
  final bool isConsumable;

  final int evolutionStagesGranted;
  final XpBoostEffect? xpBoostEffect;
  final EggProgress? eggProgress;
  final EggRarity? eggRarity;
  final EnergyRefillEffect? energyRefillEffect;
  final BattleTicketAccess? battleTicketAccess;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.type,
    this.quantity = 1,
    this.imagePath = '',
    this.description = '',
    this.coinValue = 0,
    this.diamondValue = 0,
    this.category = ItemCategory.consumable,
    this.itemType = InventoryItemType.generic,
    this.isPremium = false,
    this.isConsumable = true,
    this.evolutionStagesGranted = 0,
    this.xpBoostEffect,
    this.eggProgress,
    this.eggRarity,
    this.energyRefillEffect,
    this.battleTicketAccess,
  });

  const InventoryItem._eggInternal({
    required this.id,
    required EggProgress this.eggProgress,
    required EggRarity this.eggRarity,
    this.name = 'Egg',
    this.type = 'egg',
    this.quantity = 1,
    this.imagePath = '',
    this.description = 'Hatches over time or after enough battles.',
    this.coinValue = 750,
    this.diamondValue = 8,
    this.category = ItemCategory.progression,
    this.itemType = InventoryItemType.egg,
    this.isPremium = false,
    this.isConsumable = true,
  })  : evolutionStagesGranted = 0,
        xpBoostEffect = null,
        energyRefillEffect = null,
        battleTicketAccess = null;

  const InventoryItem.evolutionCore({
    required this.id,
    this.name = 'Evolution Core',
    this.type = 'progression',
    this.quantity = 1,
    this.imagePath = '',
    this.description = 'Instantly evolves a Pokemon to its next stage.',
    this.coinValue = 2500,
    this.diamondValue = 25,
    this.category = ItemCategory.progression,
    this.itemType = InventoryItemType.evolutionCore,
    this.isPremium = true,
    this.isConsumable = true,
    this.evolutionStagesGranted = 1,
  })  : xpBoostEffect = null,
        eggProgress = null,
        eggRarity = null,
        energyRefillEffect = null,
        battleTicketAccess = null;

  const InventoryItem.xpBoostChip({
    required this.id,
    this.name = 'XP Boost Chip',
    this.type = 'boost',
    this.quantity = 1,
    this.imagePath = '',
    this.description = '+50% XP for the next 3 battles.',
    this.coinValue = 500,
    this.diamondValue = 5,
    this.category = ItemCategory.boost,
    this.itemType = InventoryItemType.xpBoostChip,
    this.isPremium = false,
    this.isConsumable = true,
    this.xpBoostEffect = const XpBoostEffect(multiplier: 1.5, battleCount: 3),
  })  : evolutionStagesGranted = 0,
        eggProgress = null,
        eggRarity = null,
        energyRefillEffect = null,
        battleTicketAccess = null;

  factory InventoryItem.egg({
    required String id,
    required EggProgress eggProgress,
    EggRarity rarity = EggRarity.common,
    String name = 'Egg',
    String type = 'egg',
    int quantity = 1,
    String imagePath = '',
    String description = 'Hatches over time or after enough battles.',
    int coinValue = 750,
    int diamondValue = 8,
    ItemCategory category = ItemCategory.progression,
    InventoryItemType itemType = InventoryItemType.egg,
    bool isPremium = false,
    bool isConsumable = true,
  }) {
    final resolvedEggProgress =
        eggProgress.hatchDuration == null
            ? eggProgress.copyWith(hatchDuration: rarity.hatchDuration)
            : eggProgress;

    return InventoryItem._eggInternal(
      id: id,
      eggProgress: resolvedEggProgress,
      eggRarity: rarity,
      name: name,
      type: type,
      quantity: quantity,
      imagePath: imagePath,
      description: description,
      coinValue: coinValue,
      diamondValue: diamondValue,
      category: category,
      itemType: itemType,
      isPremium: isPremium,
      isConsumable: isConsumable,
    );
  }

  const InventoryItem.energyRefill({
    required this.id,
    this.name = 'Energy Refill',
    this.type = 'potion',
    this.quantity = 1,
    this.imagePath = '',
    this.description = 'Restores stamina used for PvE modules.',
    this.coinValue = 300,
    this.diamondValue = 3,
    this.category = ItemCategory.potion,
    this.itemType = InventoryItemType.energyRefill,
    this.isPremium = false,
    this.isConsumable = true,
    this.energyRefillEffect = const EnergyRefillEffect(
      restoreAmount: 1,
      restoresToFull: true,
      pveOnly: true,
    ),
  })  : evolutionStagesGranted = 0,
        xpBoostEffect = null,
        eggProgress = null,
        eggRarity = null,
        battleTicketAccess = null;

  const InventoryItem.battleTicket({
    required this.id,
    this.name = 'Battle Ticket',
    this.type = 'ticket',
    this.quantity = 1,
    this.imagePath = '',
    this.description = 'Required to enter PvP or ranked battles.',
    this.coinValue = 400,
    this.diamondValue = 4,
    this.category = ItemCategory.ticket,
    this.itemType = InventoryItemType.battleTicket,
    this.isPremium = false,
    this.isConsumable = true,
    this.battleTicketAccess = const BattleTicketAccess(),
  })  : evolutionStagesGranted = 0,
        xpBoostEffect = null,
        eggProgress = null,
        eggRarity = null,
        energyRefillEffect = null;

  InventoryItem copyWith({
    String? id,
    String? name,
    String? type,
    int? quantity,
    String? imagePath,
    String? description,
    int? coinValue,
    int? diamondValue,
    ItemCategory? category,
    InventoryItemType? itemType,
    bool? isPremium,
    bool? isConsumable,
    int? evolutionStagesGranted,
    XpBoostEffect? xpBoostEffect,
    EggProgress? eggProgress,
    EggRarity? eggRarity,
    EnergyRefillEffect? energyRefillEffect,
    BattleTicketAccess? battleTicketAccess,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      imagePath: imagePath ?? this.imagePath,
      description: description ?? this.description,
      coinValue: coinValue ?? this.coinValue,
      diamondValue: diamondValue ?? this.diamondValue,
      category: category ?? this.category,
      itemType: itemType ?? this.itemType,
      isPremium: isPremium ?? this.isPremium,
      isConsumable: isConsumable ?? this.isConsumable,
      evolutionStagesGranted:
          evolutionStagesGranted ?? this.evolutionStagesGranted,
      xpBoostEffect: xpBoostEffect ?? this.xpBoostEffect,
      eggProgress: eggProgress ?? this.eggProgress,
      eggRarity: eggRarity ?? this.eggRarity,
      energyRefillEffect: energyRefillEffect ?? this.energyRefillEffect,
      battleTicketAccess: battleTicketAccess ?? this.battleTicketAccess,
    );
  }
}

extension ItemCategoryX on ItemCategory {
  String get label {
    switch (this) {
      case ItemCategory.progression:
        return 'Progression';
      case ItemCategory.consumable:
        return 'Consumable';
      case ItemCategory.access:
        return 'Access';
      case ItemCategory.special:
        return 'Special';
      case ItemCategory.support:
        return 'Support';
      case ItemCategory.potion:
        return 'Potion';
      case ItemCategory.boost:
        return 'Boost';
      case ItemCategory.ticket:
        return 'Ticket';
    }
  }
}

extension InventoryItemTypeX on InventoryItemType {
  String get label {
    switch (this) {
      case InventoryItemType.generic:
        return 'Generic';
      case InventoryItemType.evolutionCore:
        return 'Evolution Core';
      case InventoryItemType.xpBoostChip:
        return 'XP Boost';
      case InventoryItemType.egg:
        return 'Egg';
      case InventoryItemType.energyRefill:
        return 'Energy Refill';
      case InventoryItemType.battleTicket:
        return 'Battle Ticket';
    }
  }
}
