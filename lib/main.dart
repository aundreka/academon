import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/theme.dart';
import 'core/widgets/ui/bottomnav.dart';
import 'screens/arena.dart';
import 'screens/home.dart';
import 'screens/pokemons.dart';
import 'screens/shop.dart';
import 'screens/study.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://nntpbnmmrsjgmtjtvquc.supabase.co',
    anonKey: 'sb_publishable_jJwgTWhLUaBzzGlvWjXcOA_2r1PSvTl',
  );

  runApp(const AcademonApp());
}

final supabase = Supabase.instance.client;

class AcademonApp extends StatelessWidget {
  const AcademonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 2; // default = Home

  final List<Widget> screens = const [
    ArenaScreen(),
    PokemonsScreen(),
    HomeScreen(),
    StudyScreen(),
    ShopScreen(),
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
