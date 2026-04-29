import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/pokemons.dart';
import '../../core/models/pokemon.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/textstyles.dart';
import '../../core/widgets/pokemon/card.dart';
import '../../core/widgets/pokemon/card_detail.dart';
import '../../core/widgets/ui/topnav.dart';
import 'inventory.dart';

class PokemonsScreen extends StatefulWidget {
  const PokemonsScreen({super.key});

  @override
  State<PokemonsScreen> createState() => _PokemonsScreenState();
}

enum _SortMode { rarity, name }
enum _InventorySection { pokemons, items }

class _PokemonsScreenState extends State<PokemonsScreen> {
  static const String _allFilter = 'All';
  static const int _teamSize = 5;

  late final SupabaseClient _supabase;
  final Map<String, Pokemon> _pokemonById = {
    for (final pokemon in starterCreatures) pokemon.id: pokemon,
  };

  bool _loading = true;
  bool _savingTeam = false;
  String? _errorMessage;

  List<_OwnedPokemonEntry> _entries = const [];
  List<_PokemonTeamView> _teams = const [];
  String? _selectedTeamId;
  List<String> _typeFilters = const [_allFilter];

  String _selectedTypeFilter = _allFilter;
  _SortMode _sortMode = _SortMode.rarity;
  _InventorySection _section = _InventorySection.pokemons;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('You need to be logged in to view your Pokemon inventory.');
      }

      final ownedRows = await _supabase
          .from('owned_pokemons')
          .select('id, pokemon_id, level, xp, current_hp, nickname, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final entries = ownedRows
          .map((row) => _parseOwnedPokemon(Map<String, dynamic>.from(row)))
          .whereType<_OwnedPokemonEntry>()
          .toList();

      final teamRows = await _supabase
          .from('pokemon_teams')
          .select('id, name, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: true);

      final teams = <_PokemonTeamView>[];
      final teamIds = teamRows.map((row) => row['id'] as String).toList();

      Map<String, List<_TeamMemberSlot>> membersByTeam = {};
      if (teamIds.isNotEmpty) {
        final memberRows = await _supabase
            .from('pokemon_team_members')
            .select('team_id, owned_pokemon_id, slot_number')
            .inFilter('team_id', teamIds)
            .order('slot_number', ascending: true);

        membersByTeam = {};
        for (final row in memberRows) {
          final map = Map<String, dynamic>.from(row);
          final teamId = map['team_id'] as String?;
          if (teamId == null) continue;
          membersByTeam.putIfAbsent(teamId, () => <_TeamMemberSlot>[]).add(
                _TeamMemberSlot(
                  slotNumber: (map['slot_number'] as int?) ?? 1,
                  ownedPokemonId: map['owned_pokemon_id'] as String?,
                ),
              );
        }
      }

      for (final row in teamRows) {
        final map = Map<String, dynamic>.from(row);
        final teamId = map['id'] as String;
        final members = List<_TeamMemberSlot>.from(membersByTeam[teamId] ?? const []);
        members.sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
        teams.add(
          _PokemonTeamView(
            id: teamId,
            name: ((map['name'] as String?) ?? 'Battle Deck').trim(),
            members: members,
          ),
        );
      }

      var resolvedTeams = teams;
      if (resolvedTeams.isEmpty) {
        final createdTeam = await _createDefaultTeam(entries);
        resolvedTeams = createdTeam == null ? const [] : [createdTeam];
      }

      final selectedTeamId = _resolveSelectedTeamId(resolvedTeams);
      final typeFilters = [
        _allFilter,
        ...{
          for (final entry in entries) _primaryType(entry.pokemon.type),
        },
      ];

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _teams = resolvedTeams;
        _selectedTeamId = selectedTeamId;
        _typeFilters = typeFilters;
        if (!_typeFilters.contains(_selectedTypeFilter)) {
          _selectedTypeFilter = _allFilter;
        }
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  _OwnedPokemonEntry? _parseOwnedPokemon(Map<String, dynamic> row) {
    final pokemonId = (row['pokemon_id'] as String?)?.trim();
    final pokemon = pokemonId == null ? null : _pokemonById[pokemonId];
    if (pokemon == null) return null;

    final level = (row['level'] as int?) ?? 1;
    final xp = (row['xp'] as int?) ?? 0;

    return _OwnedPokemonEntry(
      ownedPokemonId: (row['id'] as String?) ?? '',
      pokemon: pokemon,
      level: level,
      xp: xp,
      xpGoal: _xpGoalForLevel(level),
      nickname: (row['nickname'] as String?)?.trim(),
      currentHp: (row['current_hp'] as int?) ?? pokemon.baseHp,
    );
  }

  Future<_PokemonTeamView?> _createDefaultTeam(List<_OwnedPokemonEntry> entries) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final team = await _supabase
        .from('pokemon_teams')
        .insert({
          'user_id': user.id,
          'name': 'Battle Deck',
        })
        .select('id, name')
        .single();

    final teamId = team['id'] as String;
    final initialMembers = entries.take(_teamSize).toList();

    if (initialMembers.isNotEmpty) {
      await _supabase.from('pokemon_team_members').insert(
            initialMembers
                .asMap()
                .entries
                .map(
                  (entry) => {
                    'team_id': teamId,
                    'owned_pokemon_id': entry.value.ownedPokemonId,
                    'slot_number': entry.key + 1,
                  },
                )
                .toList(),
          );
    }

    return _PokemonTeamView(
      id: teamId,
      name: ((team['name'] as String?) ?? 'Battle Deck').trim(),
      members: initialMembers
          .asMap()
          .entries
          .map(
            (entry) => _TeamMemberSlot(
              slotNumber: entry.key + 1,
              ownedPokemonId: entry.value.ownedPokemonId,
            ),
          )
          .toList(),
    );
  }

  String? _resolveSelectedTeamId(List<_PokemonTeamView> teams) {
    if (teams.isEmpty) return null;
    final existing = _selectedTeamId;
    if (existing != null && teams.any((team) => team.id == existing)) {
      return existing;
    }
    return teams.first.id;
  }

  _PokemonTeamView? get _selectedTeam {
    final id = _selectedTeamId;
    if (id == null) return _teams.isEmpty ? null : _teams.first;
    for (final team in _teams) {
      if (team.id == id) return team;
    }
    return _teams.isEmpty ? null : _teams.first;
  }

  List<_OwnedPokemonEntry> get _battleDeckEntries {
    final team = _selectedTeam;
    if (team == null) return const [];

    final byOwnedId = {
      for (final entry in _entries) entry.ownedPokemonId: entry,
    };

    final deck = <_OwnedPokemonEntry>[];
    final sortedMembers = List<_TeamMemberSlot>.from(team.members)
      ..sort((a, b) => a.slotNumber.compareTo(b.slotNumber));
    for (final slot in sortedMembers) {
      final ownedId = slot.ownedPokemonId;
      if (ownedId == null) continue;
      final entry = byOwnedId[ownedId];
      if (entry != null) deck.add(entry);
    }
    return deck;
  }

  Set<String> get _selectedTeamOwnedIds {
    final team = _selectedTeam;
    if (team == null) return const {};
    return team.members
        .map((member) => member.ownedPokemonId)
        .whereType<String>()
        .toSet();
  }

  List<_OwnedPokemonEntry> _filteredEntries() {
    final teamOwnedIds = _selectedTeamOwnedIds;
    final filtered = _entries.where((entry) {
      final matchesType = _selectedTypeFilter == _allFilter ||
          _primaryType(entry.pokemon.type) == _selectedTypeFilter;
      return matchesType;
    }).map((entry) {
      return entry.copyWith(inDeck: teamOwnedIds.contains(entry.ownedPokemonId));
    }).toList();

    filtered.sort((a, b) {
      if (_sortMode == _SortMode.rarity) {
        final rarityCompare = _rarityWeight(b.pokemon.rarity).compareTo(
          _rarityWeight(a.pokemon.rarity),
        );
        if (rarityCompare != 0) return rarityCompare;
      }
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

    return filtered;
  }

  Future<void> _openTeamEditor() async {
    final team = _selectedTeam;
    if (team == null || _savingTeam) return;

    final initialSlots = List<String?>.filled(_teamSize, null);
    for (final member in team.members) {
      final index = member.slotNumber - 1;
      if (index >= 0 && index < _teamSize) {
        initialSlots[index] = member.ownedPokemonId;
      }
    }

    final result = await showModalBottomSheet<List<String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _TeamEditorSheet(
          teamName: team.name,
          entries: _entries,
          initialSlots: initialSlots,
        );
      },
    );

    if (result == null) return;
    await _saveTeamMembers(team, result);
  }

  Future<void> _saveTeamMembers(_PokemonTeamView team, List<String?> slots) async {
    setState(() => _savingTeam = true);
    try {
      await _supabase.from('pokemon_team_members').delete().eq('team_id', team.id);

      final payload = <Map<String, dynamic>>[];
      for (var i = 0; i < slots.length; i++) {
        final ownedPokemonId = slots[i];
        if (ownedPokemonId == null || ownedPokemonId.isEmpty) continue;
        payload.add({
          'team_id': team.id,
          'owned_pokemon_id': ownedPokemonId,
          'slot_number': i + 1,
        });
      }

      if (payload.isNotEmpty) {
        await _supabase.from('pokemon_team_members').insert(payload);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Battle deck updated.')),
      );
      await _loadInventory();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingTeam = false);
      }
    }
  }

  void _showPokemonDetails(_OwnedPokemonEntry entry) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.76),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(AppSpacing.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
            child: Stack(
              children: [
                PokemonCardDetail(
                  pokemon: entry.pokemon,
                  margin: EdgeInsets.zero,
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: 72,
                  bottom: AppSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.38),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      children: [
                        _DetailMeta(label: 'Name', value: entry.displayName),
                        _DetailMeta(label: 'Level', value: '${entry.level}'),
                        _DetailMeta(label: 'XP', value: '${entry.xp}/${entry.xpGoal}'),
                        _DetailMeta(
                          label: 'HP',
                          value: '${entry.currentHp}/${entry.pokemon.baseHp}',
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.md,
                  right: AppSpacing.md,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.28),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = _filteredEntries();

    return Column(
      children: [
        const AppTopNav(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                _InventorySwitcher(
                  value: _section,
                  onChanged: (value) {
                    setState(() => _section = value);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: _section == _InventorySection.pokemons
                      ? _buildPokemonBody(filteredEntries)
                      : const InventoryScreen(embedded: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPokemonBody(List<_OwnedPokemonEntry> filteredEntries) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _loadInventory,
                child: Text(
                  'Retry',
                  style: AppTextStyles.button.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInventory,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBattleDeckSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildCollectionSection(filteredEntries),
          ],
        ),
      ),
    );
  }

  Widget _buildBattleDeckSection() {
    final battleDeck = _battleDeckEntries;
    final selectedTeam = _selectedTeam;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            const Color(0xFF2D8BE0),
            const Color(0xFF1B5FA5),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.34),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              top: -36,
              left: -28,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -18,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.08),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.08),
                      Colors.transparent,
                      Colors.black.withOpacity(0.08),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _DeckTexturePainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Battle Deck',
                              style: AppTextStyles.title.copyWith(fontSize: 18),
                            ),
                            if (_teams.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 220,
                                child: _TeamDropdown(
                                  teams: _teams,
                                  selectedTeamId: _selectedTeamId,
                                  onChanged: (value) {
                                    setState(() => _selectedTeamId = value);
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: selectedTeam == null || _savingTeam ? null : _openTeamEditor,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.sm,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _savingTeam ? 'Saving...' : 'Edit Team',
                                  style: AppTextStyles.button.copyWith(
                                    fontSize: 14,
                                    color: AppColors.accent,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Icon(
                                  Icons.edit_rounded,
                                  color: AppColors.accent,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (battleDeck.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        _entries.isEmpty
                            ? 'You do not have any Pokemon in your database yet.'
                            : 'This team is empty. Tap Edit Team to assign up to 5 Pokemon.',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = AppSpacing.sm;
                        final visibleCards = battleDeck.length > 5 ? 5 : battleDeck.length;
                        final cardWidth =
                            (constraints.maxWidth - (spacing * (visibleCards - 1))) /
                                visibleCards;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: battleDeck
                              .map(
                                (entry) => PokemonCard(
                                  pokemon: entry.pokemon,
                                  level: entry.level,
                                  xp: entry.xp,
                                  xpGoal: entry.xpGoal,
                                  width: cardWidth,
                                  height: cardWidth * 1.68,
                                  onTap: () => _showPokemonDetails(entry),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionSection(List<_OwnedPokemonEntry> filteredEntries) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pokedex Collection',
                  style: AppTextStyles.title.copyWith(fontSize: 18),
                ),
              ),
              Text(
                '${filteredEntries.length}/${_entries.length}',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 40,
            child: Row(
              children: [
                SizedBox(
                  width: 144,
                  child: _SortDropdown(
                    value: _sortMode,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _sortMode = value);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _typeFilters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final filter = _typeFilters[index];
                      final isSelected = filter == _selectedTypeFilter;
                      final filterColor = _filterColor(filter);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            setState(() => _selectedTypeFilter = filter);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? filterColor.withOpacity(0.22)
                                  : AppColors.background.withOpacity(0.28),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: filterColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  filter,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_entries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'No Pokemon found in your account yet.',
                style: AppTextStyles.body.copyWith(fontSize: 13),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = AppSpacing.sm;
                var columns = (constraints.maxWidth / 110).floor();
                if (columns < 2) columns = 2;
                if (columns > 4) columns = 4;

                final cardWidth =
                    (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: filteredEntries
                      .map(
                        (entry) => SizedBox(
                          width: cardWidth,
                          child: Stack(
                            children: [
                              _HoverLiftCard(
                                child: PokemonCard(
                                  pokemon: entry.pokemon,
                                  level: entry.level,
                                  xp: entry.xp,
                                  xpGoal: entry.xpGoal,
                                  width: cardWidth,
                                  height: cardWidth * 1.5,
                                  onTap: () => _showPokemonDetails(entry),
                                ),
                              ),
                              if (entry.inDeck)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.22),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      'In Deck',
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  String _primaryType(String type) => type.split('/').first.trim();

  int _xpGoalForLevel(int level) => level * 150;

  int _rarityWeight(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return 5;
      case 'ultra rare':
        return 4;
      case 'rare':
        return 3;
      case 'uncommon':
        return 2;
      case 'common':
        return 1;
      default:
        return 0;
    }
  }

  Color _filterColor(String filter) {
    switch (filter.toLowerCase()) {
      case 'fire':
        return const Color(0xFFFF7A45);
      case 'water':
        return const Color(0xFF4DA8FF);
      case 'grass':
        return const Color(0xFF65D66E);
      case 'electric':
        return const Color(0xFFFFD84D);
      case 'psychic':
        return const Color(0xFFFF6FAE);
      case 'ghost':
        return const Color(0xFF8D7BFF);
      case 'fighting':
        return const Color(0xFFE07A45);
      case 'all':
      default:
        return AppColors.accent;
    }
  }
}

class _SortDropdown extends StatelessWidget {
  final _SortMode value;
  final ValueChanged<_SortMode?> onChanged;

  const _SortDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_SortMode>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.card,
          iconEnabledColor: AppColors.textPrimary,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          onChanged: onChanged,
          items: const [
            DropdownMenuItem(
              value: _SortMode.rarity,
              child: Text('By Rarity'),
            ),
            DropdownMenuItem(
              value: _SortMode.name,
              child: Text('By Name'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventorySwitcher extends StatelessWidget {
  final _InventorySection value;
  final ValueChanged<_InventorySection> onChanged;

  const _InventorySwitcher({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SwitcherChip(
              label: 'Pokemons',
              selected: value == _InventorySection.pokemons,
              onTap: () => onChanged(_InventorySection.pokemons),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: _SwitcherChip(
              label: 'Inventory',
              selected: value == _InventorySection.items,
              onTap: () => onChanged(_InventorySection.items),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitcherChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SwitcherChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withOpacity(0.35)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.button.copyWith(
              fontSize: 14,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamDropdown extends StatelessWidget {
  final List<_PokemonTeamView> teams;
  final String? selectedTeamId;
  final ValueChanged<String?> onChanged;

  const _TeamDropdown({
    required this.teams,
    required this.selectedTeamId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedValue = teams.any((team) => team.id == selectedTeamId)
        ? selectedTeamId
        : teams.first.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: resolvedValue,
          isExpanded: true,
          dropdownColor: AppColors.card,
          iconEnabledColor: AppColors.textPrimary,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
          onChanged: onChanged,
          items: teams
              .map(
                (team) => DropdownMenuItem<String>(
                  value: team.id,
                  child: Text(team.name),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _DeckTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1;

    const gap = 18.0;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HoverLiftCard extends StatefulWidget {
  final Widget child;

  const _HoverLiftCard({
    required this.child,
  });

  @override
  State<_HoverLiftCard> createState() => _HoverLiftCardState();
}

class _HoverLiftCardState extends State<_HoverLiftCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..translate(0.0, _hovered ? -8.0 : 0.0),
        child: widget.child,
      ),
    );
  }
}

class _TeamEditorSheet extends StatefulWidget {
  final String teamName;
  final List<_OwnedPokemonEntry> entries;
  final List<String?> initialSlots;

  const _TeamEditorSheet({
    required this.teamName,
    required this.entries,
    required this.initialSlots,
  });

  @override
  State<_TeamEditorSheet> createState() => _TeamEditorSheetState();
}

class _TeamEditorSheetState extends State<_TeamEditorSheet> {
  late final List<String?> _slots;

  @override
  void initState() {
    super.initState();
    _slots = List<String?>.from(widget.initialSlots);
  }

  @override
  Widget build(BuildContext context) {
    final entryByOwnedId = {
      for (final entry in widget.entries) entry.ownedPokemonId: entry,
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit ${widget.teamName}',
                  style: AppTextStyles.title.copyWith(fontSize: 18),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Assign up to 5 Pokemon. A Pokemon can only occupy one slot in the team.',
                  style: AppTextStyles.body.copyWith(fontSize: 12),
                ),
                const SizedBox(height: AppSpacing.md),
                for (var i = 0; i < _slots.length; i++) ...[
                  _TeamSlotDropdown(
                    label: 'Slot ${i + 1}',
                    value: _slots[i],
                    entries: widget.entries,
                    selectedIds: _slots,
                    onChanged: (value) {
                      setState(() => _slots[i] = value);
                    },
                  ),
                  if (_slots[i] != null && entryByOwnedId[_slots[i]] != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      entryByOwnedId[_slots[i]]!.displayName,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: AppTextStyles.button.copyWith(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(_slots),
                        child: Text(
                          'Save Team',
                          style: AppTextStyles.button.copyWith(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TeamSlotDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<_OwnedPokemonEntry> entries;
  final List<String?> selectedIds;
  final ValueChanged<String?> onChanged;

  const _TeamSlotDropdown({
    required this.label,
    required this.value,
    required this.entries,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentValue = value;
    final availableEntries = entries.where((entry) {
      return entry.ownedPokemonId == currentValue ||
          !selectedIds.whereType<String>().contains(entry.ownedPokemonId);
    }).toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.28),
        borderRadius: BorderRadius.circular(18),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: currentValue,
          isExpanded: true,
          dropdownColor: AppColors.card,
          iconEnabledColor: AppColors.textPrimary,
          hint: Text(
            label,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          onChanged: onChanged,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text('Empty - $label'),
            ),
            ...availableEntries.map(
              (entry) => DropdownMenuItem<String?>(
                value: entry.ownedPokemonId,
                child: Text('${entry.displayName} Lv.${entry.level}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailMeta extends StatelessWidget {
  final String label;
  final String value;

  const _DetailMeta({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: value,
            style: AppTextStyles.body.copyWith(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnedPokemonEntry {
  final String ownedPokemonId;
  final Pokemon pokemon;
  final int level;
  final int xp;
  final int xpGoal;
  final String? nickname;
  final int currentHp;
  final bool inDeck;

  const _OwnedPokemonEntry({
    required this.ownedPokemonId,
    required this.pokemon,
    required this.level,
    required this.xp,
    required this.xpGoal,
    required this.nickname,
    required this.currentHp,
    this.inDeck = false,
  });

  String get displayName => nickname?.isNotEmpty == true ? nickname! : pokemon.name;

  _OwnedPokemonEntry copyWith({
    bool? inDeck,
  }) {
    return _OwnedPokemonEntry(
      ownedPokemonId: ownedPokemonId,
      pokemon: pokemon,
      level: level,
      xp: xp,
      xpGoal: xpGoal,
      nickname: nickname,
      currentHp: currentHp,
      inDeck: inDeck ?? this.inDeck,
    );
  }
}

class _PokemonTeamView {
  final String id;
  final String name;
  final List<_TeamMemberSlot> members;

  const _PokemonTeamView({
    required this.id,
    required this.name,
    required this.members,
  });
}

class _TeamMemberSlot {
  final int slotNumber;
  final String? ownedPokemonId;

  const _TeamMemberSlot({
    required this.slotNumber,
    required this.ownedPokemonId,
  });
}
