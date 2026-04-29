import 'dart:math';
import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/item.dart';
import '../models/pokemon.dart';
import '../models/reward.dart';
import 'pokemons.dart';
import 'shop_catalog.dart';

enum PurchaseCurrency {
  coins,
  diamonds,
}

class PurchaseResult {
  final bool success;
  final String message;

  const PurchaseResult({
    required this.success,
    required this.message,
  });
}

class InventoryActionResult {
  final bool success;
  final String message;

  const InventoryActionResult({
    required this.success,
    required this.message,
  });
}

class OwnedInventoryItem {
  final InventoryItem item;
  final int quantity;

  const OwnedInventoryItem({
    required this.item,
    required this.quantity,
  });

  int get sellPrice => item.coinValue <= 0 ? 0 : max(1, item.coinValue ~/ 2);
  bool get canSell => quantity > 0 && sellPrice > 0;
  bool get canUse =>
      quantity > 0 &&
      item.isConsumable &&
      const {
        InventoryItemType.energyRefill,
        InventoryItemType.xpBoostChip,
        InventoryItemType.evolutionCore,
      }.contains(item.itemType);
}

class HatchResult {
  final InventoryItem item;
  final Pokemon pokemon;

  const HatchResult({
    required this.item,
    required this.pokemon,
  });
}

class HatcheryEggEntry {
  final String eggInstanceId;
  final InventoryItem item;
  final DateTime createdAt;
  final Duration? hatchDuration;

  const HatcheryEggEntry({
    required this.eggInstanceId,
    required this.item,
    required this.createdAt,
    required this.hatchDuration,
  });
}

class ItemInventoryService {
  static final StreamController<void> _eggPurchaseController =
      StreamController<void>.broadcast();

  final SupabaseClient _supabase;

  const ItemInventoryService(this._supabase);

  static Stream<void> get eggPurchaseStream => _eggPurchaseController.stream;

  Future<void> grantReward(Reward reward) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Please log in before claiming rewards.');
    }

    if (reward.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final stats = await _supabase
        .from('user_stats')
        .select('xp, coins, diamonds')
        .eq('user_id', user.id)
        .maybeSingle();

    final currentXp = _asInt(stats?['xp']);
    final currentCoins = _asInt(stats?['coins']);
    final currentDiamonds = _asInt(stats?['diamonds']);
    final nextStats = <String, dynamic>{
      'updated_at': now,
    };

    if (reward.xp > 0) {
      nextStats['xp'] = currentXp + reward.xp;
    }
    if (reward.coins > 0) {
      nextStats['coins'] = currentCoins + reward.coins;
    }
    if (reward.diamonds > 0) {
      nextStats['diamonds'] = currentDiamonds + reward.diamonds;
    }

    if (stats == null) {
      await _supabase.from('user_stats').insert({
        'user_id': user.id,
        'xp': nextStats['xp'] ?? 0,
        'coins': nextStats['coins'] ?? 0,
        'diamonds': nextStats['diamonds'] ?? 0,
        'updated_at': now,
      });
    } else {
      await _supabase.from('user_stats').update(nextStats).eq('user_id', user.id);
    }

    for (final item in reward.items) {
      await _grantInventoryItem(userId: user.id, item: item, now: now);
    }
  }

  Future<List<OwnedInventoryItem>> fetchOwnedItems() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return const [];
    }

    final rows = await _supabase
        .from('user_inventory')
        .select(
          'quantity, inventory_items!inner ('
          'id, name, type, image_path, description, coin_value, diamond_value, '
          'category, item_type, '
          'is_premium, is_consumable, evolution_stages_granted, xp_multiplier, '
          'xp_boost_battle_count, egg_subject_id, egg_rarity, '
          'egg_hatch_duration_seconds, energy_restore_amount, '
          'energy_restores_to_full, energy_pve_only, battle_ticket_mode, '
          'battle_ticket_required_per_entry'
          ')',
        )
        .eq('user_id', user.id)
        .gt('quantity', 0);

    final items = rows
        .whereType<Map<String, dynamic>>()
        .map<OwnedInventoryItem?>((row) {
          final rawItem = row['inventory_items'];
          final itemMap = rawItem is List && rawItem.isNotEmpty
              ? rawItem.first
              : rawItem;
          if (itemMap is! Map<String, dynamic>) {
            return null;
          }

          return OwnedInventoryItem(
            quantity: (row['quantity'] as int?) ?? 0,
            item: _inventoryItemFromRow(
              itemMap,
              quantity: (row['quantity'] as int?) ?? 0,
            ),
          );
        })
        .whereType<OwnedInventoryItem>()
        .toList();

    items.sort((a, b) => a.item.name.compareTo(b.item.name));
    return items;
  }

  Future<List<HatcheryEggEntry>> fetchActiveEggs() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return const [];
    }

    final rows = await _supabase
        .from('user_egg_instances')
        .select(
          'id, inventory_item_id, subject_id, hatch_duration_seconds, egg_rarity, created_at',
        )
        .eq('user_id', user.id)
        .filter('hatched_at', 'is', null)
        .order('created_at')
        .limit(3);

    final now = DateTime.now().toUtc();
    return rows.whereType<Map<String, dynamic>>().map<HatcheryEggEntry>((map) {
      final itemId = (map['inventory_item_id'] as String?) ?? '';
      final baseItem = shopCatalogById[itemId];
      final rarity = eggRarityFromString(map['egg_rarity'] as String?);
      final hatchDurationSeconds = map['hatch_duration_seconds'] as int?;
      final createdAt = DateTime.tryParse(map['created_at'] as String? ?? '')?.toUtc() ?? now;
      final eggProgress = EggProgress(
        subjectId: map['subject_id'] as String?,
        hatchBattleRequirement: 0,
        hatchDuration: hatchDurationSeconds == null
            ? rarity.hatchDuration
            : Duration(seconds: hatchDurationSeconds),
      );
      final item = baseItem ??
          InventoryItem.egg(
            id: itemId,
            name: '${rarity.label} Egg',
            rarity: rarity,
            eggProgress: eggProgress,
          );

      final duration = eggProgress.hatchDuration;

      return HatcheryEggEntry(
        eggInstanceId: map['id'] as String? ?? '',
        item: InventoryItem.egg(
          id: item.id,
          name: item.name,
          imagePath: item.imagePath,
          description: item.description,
          coinValue: item.coinValue,
          diamondValue: item.diamondValue,
          rarity: rarity,
          eggProgress: eggProgress,
        ),
        createdAt: createdAt,
        hatchDuration: duration,
      );
    }).toList();
  }

  Future<PurchaseResult> purchaseItem({
    required InventoryItem item,
    required PurchaseCurrency currency,
    int? coinPrice,
    int? diamondPrice,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return const PurchaseResult(
        success: false,
        message: 'Please log in before purchasing items.',
      );
    }

    final stats = await _supabase
        .from('user_stats')
        .select('coins, diamonds')
        .eq('user_id', user.id)
        .maybeSingle();

    final coins = (stats?['coins'] as int?) ?? 0;
    final diamonds = (stats?['diamonds'] as int?) ?? 0;
    final resolvedCoinPrice = coinPrice ?? item.coinValue;
    final resolvedDiamondPrice = diamondPrice ?? item.diamondValue;
    final cost = currency == PurchaseCurrency.coins
        ? resolvedCoinPrice
        : resolvedDiamondPrice;

    if (cost <= 0) {
      return const PurchaseResult(
        success: false,
        message: 'This item cannot be purchased with that currency.',
      );
    }

    if (currency == PurchaseCurrency.coins && coins < cost) {
      return const PurchaseResult(
        success: false,
        message: 'Not enough coins for this purchase.',
      );
    }
    if (currency == PurchaseCurrency.diamonds && diamonds < cost) {
      return const PurchaseResult(
        success: false,
        message: 'Not enough diamonds for this purchase.',
      );
    }

    if (item.itemType == InventoryItemType.egg) {
      final activeEggRows = await _supabase
          .from('user_egg_instances')
          .select('id')
          .eq('user_id', user.id)
          .filter('hatched_at', 'is', null);
      if (activeEggRows.length >= 3) {
        return const PurchaseResult(
          success: false,
          message: 'Only 3 eggs can hatch at the same time.',
        );
      }

      await _supabase.from('user_egg_instances').insert({
        'user_id': user.id,
        'inventory_item_id': item.id,
        'subject_id': item.eggProgress?.subjectId,
        'hatch_duration_seconds': item.eggProgress?.hatchDuration?.inSeconds,
        'egg_rarity': (item.eggRarity ?? EggRarity.common).storageValue,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      _eggPurchaseController.add(null);
    } else {
      final existing = await _supabase
          .from('user_inventory')
          .select('quantity')
          .eq('user_id', user.id)
          .eq('item_id', item.id)
          .maybeSingle();
      final nextQuantity = ((existing?['quantity'] as int?) ?? 0) + 1;

      await _supabase.from('user_inventory').upsert({
        'user_id': user.id,
        'item_id': item.id,
        'quantity': nextQuantity,
      }, onConflict: 'user_id,item_id');
    }

    await _supabase.from('user_stats').update({
      'coins': currency == PurchaseCurrency.coins ? coins - cost : coins,
      'diamonds': currency == PurchaseCurrency.diamonds
          ? diamonds - cost
          : diamonds,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('user_id', user.id);

    return PurchaseResult(
      success: true,
      message: item.itemType == InventoryItemType.egg
          ? '${item.name} is now incubating in your hatchery.'
          : '${item.name} added to your inventory.',
    );
  }

  Future<HatchResult> hatchEgg(HatcheryEggEntry entry) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Please log in before hatching eggs.');
    }

    final pokemon = _pokemonForEgg(entry.item);
    final now = DateTime.now().toUtc().toIso8601String();

    await _supabase.from('owned_pokemons').insert({
      'user_id': user.id,
      'pokemon_id': pokemon.id,
      'level': 1,
      'xp': 0,
      'current_hp': pokemon.baseHp,
      'updated_at': now,
    });

    await _supabase.from('user_egg_instances').update({
      'hatched_at': now,
      'updated_at': now,
    }).eq('id', entry.eggInstanceId);

    return HatchResult(
      item: entry.item,
      pokemon: pokemon,
    );
  }

  Future<InventoryActionResult> useItem(OwnedInventoryItem ownedItem) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return const InventoryActionResult(
        success: false,
        message: 'Please log in before using items.',
      );
    }

    if (ownedItem.quantity <= 0) {
      return const InventoryActionResult(
        success: false,
        message: 'You do not have any of this item left.',
      );
    }

    final item = ownedItem.item;
    final now = DateTime.now().toUtc().toIso8601String();

    switch (item.itemType) {
      case InventoryItemType.energyRefill:
        final stats = await _supabase
            .from('user_stats')
            .select('current_energy, max_energy')
            .eq('user_id', user.id)
            .maybeSingle();
        final currentEnergy = (stats?['current_energy'] as int?) ?? 0;
        final maxEnergy = (stats?['max_energy'] as int?) ?? 0;
        final effect = item.energyRefillEffect;
        final nextEnergy = effect?.restoresToFull ?? false
            ? maxEnergy
            : min(maxEnergy, currentEnergy + (effect?.restoreAmount ?? 0));

        if (nextEnergy == currentEnergy) {
          return const InventoryActionResult(
            success: false,
            message: 'Your energy is already full.',
          );
        }

        await _supabase.from('user_stats').update({
          'current_energy': nextEnergy,
          'updated_at': now,
        }).eq('user_id', user.id);
        await _decrementInventoryItem(user.id, item.id, ownedItem.quantity);

        return InventoryActionResult(
          success: true,
          message: '${item.name} used. Energy restored to $nextEnergy.',
        );
      case InventoryItemType.xpBoostChip:
        await _supabase.from('user_item_effects').insert({
          'user_id': user.id,
          'source_item_id': item.id,
          'effect_type': 'xp_boost',
          'multiplier': item.xpBoostEffect?.multiplier ?? 1.0,
          'remaining_battle_count': item.xpBoostEffect?.battleCount ?? 0,
          'started_at': now,
          'created_at': now,
          'updated_at': now,
        });
        await _decrementInventoryItem(user.id, item.id, ownedItem.quantity);

        return InventoryActionResult(
          success: true,
          message:
              '${item.name} activated for the next ${item.xpBoostEffect?.battleCount ?? 0} battles.',
        );
      case InventoryItemType.evolutionCore:
        return const InventoryActionResult(
          success: false,
          message:
              'Evolution Cores need a Pokemon target. Add the target flow from the Pokemon screen next.',
        );
      case InventoryItemType.generic:
      case InventoryItemType.egg:
      case InventoryItemType.battleTicket:
        break;
    }

    return InventoryActionResult(
      success: false,
      message: '${item.name} cannot be used directly from the inventory.',
    );
  }

  Future<void> _grantInventoryItem({
    required String userId,
    required InventoryItem item,
    required String now,
  }) async {
    if (item.itemType == InventoryItemType.egg) {
      final activeEggRows = await _supabase
          .from('user_egg_instances')
          .select('id')
          .eq('user_id', userId)
          .filter('hatched_at', 'is', null);
      if (activeEggRows.length >= 3) {
        throw Exception('Only 3 eggs can hatch at the same time.');
      }

      await _supabase.from('user_egg_instances').insert({
        'user_id': userId,
        'inventory_item_id': item.id,
        'subject_id': item.eggProgress?.subjectId,
        'hatch_duration_seconds': item.eggProgress?.hatchDuration?.inSeconds,
        'egg_rarity': (item.eggRarity ?? EggRarity.common).storageValue,
        'created_at': now,
        'updated_at': now,
      });
      return;
    }

    final existing = await _supabase
        .from('user_inventory')
        .select('quantity')
        .eq('user_id', userId)
        .eq('item_id', item.id)
        .maybeSingle();
    final nextQuantity = ((existing?['quantity'] as int?) ?? 0) + item.quantity;

    await _supabase.from('user_inventory').upsert({
      'user_id': userId,
      'item_id': item.id,
      'quantity': nextQuantity,
    }, onConflict: 'user_id,item_id');
  }

  Future<InventoryActionResult> sellItem(OwnedInventoryItem ownedItem) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return const InventoryActionResult(
        success: false,
        message: 'Please log in before selling items.',
      );
    }

    if (!ownedItem.canSell) {
      return const InventoryActionResult(
        success: false,
        message: 'This item cannot be sold.',
      );
    }

    final stats = await _supabase
        .from('user_stats')
        .select('coins')
        .eq('user_id', user.id)
        .maybeSingle();
    final coins = (stats?['coins'] as int?) ?? 0;
    final now = DateTime.now().toUtc().toIso8601String();

    await _decrementInventoryItem(user.id, ownedItem.item.id, ownedItem.quantity);
    await _supabase.from('user_stats').update({
      'coins': coins + ownedItem.sellPrice,
      'updated_at': now,
    }).eq('user_id', user.id);

    return InventoryActionResult(
      success: true,
      message: '${ownedItem.item.name} sold for ${ownedItem.sellPrice} coins.',
    );
  }

  Pokemon _pokemonForEgg(InventoryItem item) {
    final rarity = item.eggRarity ?? EggRarity.common;
    final stageOne = starterCreatures
        .where((pokemon) => pokemon.evolution == 1)
        .toList(growable: false);
    final roll = Random().nextDouble();
    var threshold = 0.0;
    var selectedPokemonRarity = rarity.hatchChances.first.pokemonRarity;

    for (final chance in rarity.hatchChances) {
      threshold += chance.probability;
      if (roll <= threshold) {
        selectedPokemonRarity = chance.pokemonRarity;
        break;
      }
    }

    final pool = stageOne
        .where(
          (pokemon) =>
              pokemon.rarity.toLowerCase() ==
              selectedPokemonRarity.toLowerCase(),
        )
        .toList(growable: false);

    if (pool.isEmpty) {
      throw StateError('No stage one Pokemon found for $selectedPokemonRarity.');
    }

    return pool[Random().nextInt(pool.length)];
  }

  Future<void> _decrementInventoryItem(
    String userId,
    String itemId,
    int currentQuantity,
  ) async {
    final nextQuantity = currentQuantity - 1;
    if (nextQuantity <= 0) {
      await _supabase
          .from('user_inventory')
          .delete()
          .eq('user_id', userId)
          .eq('item_id', itemId);
      return;
    }

    await _supabase.from('user_inventory').update({
      'quantity': nextQuantity,
    }).eq('user_id', userId).eq('item_id', itemId);
  }

  InventoryItem _inventoryItemFromRow(
    Map<String, dynamic> row, {
    required int quantity,
  }) {
    final itemType = inventoryItemTypeFromString(row['item_type'] as String?);
    final category = itemCategoryFromString(row['category'] as String?);
    final eggRarity = eggRarityFromString(row['egg_rarity'] as String?);
    final hatchDurationSeconds = row['egg_hatch_duration_seconds'] as int?;

    return InventoryItem(
      id: (row['id'] as String?) ?? '',
      name: (row['name'] as String?) ?? 'Unknown Item',
      type: (row['type'] as String?) ?? 'generic',
      quantity: quantity,
      imagePath: (row['image_path'] as String?) ?? '',
      description: (row['description'] as String?) ?? '',
      coinValue: (row['coin_value'] as int?) ?? 0,
      diamondValue: (row['diamond_value'] as int?) ?? 0,
      category: category,
      itemType: itemType,
      isPremium: (row['is_premium'] as bool?) ?? false,
      isConsumable: (row['is_consumable'] as bool?) ?? true,
      evolutionStagesGranted:
          (row['evolution_stages_granted'] as int?) ?? 0,
      xpBoostEffect: itemType == InventoryItemType.xpBoostChip
          ? XpBoostEffect(
              multiplier:
                  ((row['xp_multiplier'] as num?) ?? 1).toDouble(),
              battleCount: (row['xp_boost_battle_count'] as int?) ?? 0,
            )
          : null,
      eggProgress: itemType == InventoryItemType.egg
          ? EggProgress(
              subjectId: row['egg_subject_id'] as String?,
              hatchBattleRequirement: 0,
              hatchDuration: hatchDurationSeconds == null
                  ? null
                  : Duration(seconds: hatchDurationSeconds),
            )
          : null,
      eggRarity: itemType == InventoryItemType.egg ? eggRarity : null,
      energyRefillEffect: itemType == InventoryItemType.energyRefill
          ? EnergyRefillEffect(
              restoreAmount: (row['energy_restore_amount'] as int?) ?? 0,
              restoresToFull:
                  (row['energy_restores_to_full'] as bool?) ?? false,
              pveOnly: (row['energy_pve_only'] as bool?) ?? true,
            )
          : null,
      battleTicketAccess: itemType == InventoryItemType.battleTicket
          ? BattleTicketAccess(
              mode: battleTicketModeFromString(
                row['battle_ticket_mode'] as String?,
              ),
              requiredPerEntry:
                  (row['battle_ticket_required_per_entry'] as int?) ?? 1,
            )
          : null,
    );
  }

  int _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }
}
