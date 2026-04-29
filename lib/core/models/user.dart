class UserStats {
  final int xp;
  final int level;
  final int coins;
  final int diamonds;
  final int streak;

  const UserStats({
    this.xp = 0,
    this.level = 1,
    this.coins = 0,
    this.diamonds = 0,
    this.streak = 0,
  });
}

class PokemonTeam {
  final String id;
  final String name;

  /// IDs from OwnedPokemon, not base Pokemon.
  final List<String> pokemonIds;

  const PokemonTeam({
    required this.id,
    required this.name,
    this.pokemonIds = const [],
  });
}

class BattleHistory {
  final String id;
  final String opponentName;
  final String battleType; // pve or pvp
  final bool won;
  final int xpEarned;
  final int coinsEarned;
  final DateTime battledAt;

  const BattleHistory({
    required this.id,
    required this.opponentName,
    required this.battleType,
    required this.won,
    this.xpEarned = 0,
    this.coinsEarned = 0,
    required this.battledAt,
  });
}

class Friend {
  final String userId;
  final String username;
  final String avatarPath;
  final bool isOnline;

  const Friend({
    required this.userId,
    required this.username,
    this.avatarPath = '',
    this.isOnline = false,
  });
}

class InventoryItem {
  final String id;
  final String name;
  final String type; // potion, ticket, egg, boost, etc.
  final int quantity;
  final String imagePath;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.type,
    this.quantity = 1,
    this.imagePath = '',
  });
}

class UserData {
  final String id;
  final String username;
  final String email;

  final UserStats stats;

  /// IDs from OwnedPokemon.
  final List<String> ownedPokemonIds;

  /// Predefined teams made by the player.
  final List<PokemonTeam> pokemonTeams;

  final List<BattleHistory> battleHistory;
  final List<Friend> friends;
  final List<InventoryItem> inventory;

  const UserData({
    required this.id,
    required this.username,
    required this.email,
    this.stats = const UserStats(),
    this.ownedPokemonIds = const [],
    this.pokemonTeams = const [],
    this.battleHistory = const [],
    this.friends = const [],
    this.inventory = const [],
  });
}