import 'package:phosphor_flutter/phosphor_flutter.dart';

class NavItem {
  final String label;
  final PhosphorIconData icon;

  NavItem({
    required this.label,
    required this.icon,
  });
}

final navItems = <NavItem>[
  NavItem(label: 'Arena', icon: PhosphorIcons.hexagon()),
  NavItem(label: 'Pokemons', icon: PhosphorIcons.squaresFour()),
  NavItem(label: 'Home', icon: PhosphorIcons.houseSimple()),
  NavItem(label: 'Study', icon: PhosphorIcons.notebook()),
  NavItem(label: 'Shop', icon: PhosphorIcons.shoppingBag()),
];
