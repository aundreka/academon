import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class NavItem {
  final String label;
  final IconData icon;

  const NavItem({
    required this.label,
    required this.icon,
  });
}

const navItems = [
NavItem(label: 'Arena', icon: PhosphorIcons.sword),
NavItem(label: 'Pokemons', icon: PhosphorIcons.pawPrint),
NavItem(label: 'Home', icon: PhosphorIcons.house),
NavItem(label: 'Study', icon: PhosphorIcons.book),
NavItem(label: 'Shop', icon: PhosphorIcons.shoppingCart),
