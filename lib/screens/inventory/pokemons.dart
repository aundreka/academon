import 'package:flutter/material.dart';

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

  late final List<_PokemonInventoryEntry> _entries;
  late final List<_PokemonInventoryEntry> _battleDeck;
  late final List<String> _typeFilters;
  String _selectedTypeFilter = _allFilter;
  _SortMode _sortMode = _SortMode.rarity;
  _InventorySection _section = _InventorySection.pokemons;

  @override
  void initState() {
    super.initState();
    _entries = _buildEntries();
    _battleDeck = _buildBattleDeck(_entries);
    _typeFilters = [
      _allFilter,
      ...{
        for (final entry in _entries) _primaryType(entry.pokemon.type),
      },
    ];
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
                      ? SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBattleDeckSection(),
                              const SizedBox(height: AppSpacing.lg),
                              _buildCollectionSection(filteredEntries),
                            ],
                          ),
                        )
                      : const InventoryScreen(embedded: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBattleDeckSection() {
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
                      Text(
                        'Battle Deck',
                        style: AppTextStyles.title.copyWith(fontSize: 18),
                      ),
                      const Spacer(),
                      Text(
                        'Edit',
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
                  const SizedBox(height: AppSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = AppSpacing.sm;
                      final cardWidth = (constraints.maxWidth -
                              (spacing * (_battleDeck.length - 1))) /
                          _battleDeck.length;

                      return Row(
                        children: List.generate(_battleDeck.length, (index) {
                          final entry = _battleDeck[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              right: index == _battleDeck.length - 1 ? 0 : spacing,
                            ),
                            child: PokemonCard(
                              pokemon: entry.pokemon,
                              level: entry.level,
                              xp: entry.xp,
                              xpGoal: entry.xpGoal,
                              width: cardWidth,
                              height: cardWidth * 1.68,
                              onTap: () => _showPokemonDetails(entry.pokemon),
                            ),
                          );
                        }),
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

  Widget _buildCollectionSection(List<_PokemonInventoryEntry> filteredEntries) {
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
                      setState(() {
                        _sortMode = value;
                      });
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
                            setState(() {
                              _selectedTypeFilter = filter;
                            });
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
                                onTap: () => _showPokemonDetails(entry.pokemon),
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

  void _showPokemonDetails(Pokemon pokemon) {
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
                  pokemon: pokemon,
                  margin: EdgeInsets.zero,
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

  List<_PokemonInventoryEntry> _filteredEntries() {
    final filtered = _entries.where((entry) {
      final matchesType = _selectedTypeFilter == _allFilter ||
          _primaryType(entry.pokemon.type) == _selectedTypeFilter;
      return matchesType;
    }).toList();

    filtered.sort((a, b) {
      if (_sortMode == _SortMode.rarity) {
        final rarityCompare = _rarityWeight(b.pokemon.rarity).compareTo(
          _rarityWeight(a.pokemon.rarity),
        );
        if (rarityCompare != 0) {
          return rarityCompare;
        }
      }

      return a.pokemon.name.compareTo(b.pokemon.name);
    });

    return filtered;
  }

  List<_PokemonInventoryEntry> _buildEntries() {
    return starterCreatures.asMap().entries.map((entry) {
      final index = entry.key;
      final pokemon = entry.value;
      final level = 6 + (pokemon.evolution * 2) + (index % 4);
      final xpGoal = level * 150;
      final xpSeed = (xpGoal * (0.35 + ((index % 5) * 0.14))).round();
      final xp = xpSeed > xpGoal ? xpGoal : xpSeed;

      return _PokemonInventoryEntry(
        pokemon: pokemon,
        level: level,
        xp: xp,
        xpGoal: xpGoal,
        inDeck: const {
          'charmander3',
          'squirtle3',
          'abra2',
          'pichu3',
          'bulbasaur2',
        }.contains(pokemon.id),
      );
    }).toList();
  }

  List<_PokemonInventoryEntry> _buildBattleDeck(
    List<_PokemonInventoryEntry> entries,
  ) {
    final deckOrder = const [
      'charmander3',
      'squirtle3',
      'abra2',
      'pichu3',
      'bulbasaur2',
    ];

    return deckOrder
        .map(
          (id) => entries.firstWhere(
            (entry) => entry.pokemon.id == id,
          ),
        )
        .toList();
  }

  String _primaryType(String type) => type.split('/').first.trim();

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

class _PokemonInventoryEntry {
  final Pokemon pokemon;
  final int level;
  final int xp;
  final int xpGoal;
  final bool inDeck;

  const _PokemonInventoryEntry({
    required this.pokemon,
    required this.level,
    required this.xp,
    required this.xpGoal,
    required this.inDeck,
  });
}
