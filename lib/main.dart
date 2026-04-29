import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/widgets/ui/bottomnav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nntpbnmmrsjgmtjtvquc.supabase.co',
    anonKey: 'sb_publishable_jJwgTWhLUaBzzGlvWjXcOA_2r1PSvTl',
  );

  runApp(const MainScreen());
}

final supabase = Supabase.instance.client;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 2; // default = Home

  final screens = [
    Center(child: Text('Arena')),
    Center(child: Text('Pokemons')),
    Center(child: Text('Home')),
    Center(child: Text('Study')),
    Center(child: Text('Shop')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: (i) {
          setState(() => _index = i);
        },
      ),
    );
  }
}