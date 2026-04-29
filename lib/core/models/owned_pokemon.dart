class OwnedPokemon {
  final String id;           // unique instance ID
  final String pokemonId;    // references base Pokemon (geofox small)
  
  int level;
  int xp;

  int currentHp;

  final String? nickname;

  OwnedPokemon({
    required this.id,
    required this.pokemonId,
    this.level = 1,
    this.xp = 0,
    required this.currentHp,
    this.nickname,
  });
}