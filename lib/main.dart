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
    url: 'https://dfyyiqntogktwmqzkttk.supabase.co',
    anonKey: 'sb_publishable_XLJf2r9S4PJT8Ah_qh9u0w_Ps3rEK0F',
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
  final int initialIndex;

  const MainScreen({
    super.key,
    this.initialIndex = 2,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _index;

  final List<Widget> screens = const [
    ArenaScreen(),
    PokemonsScreen(),
    HomeScreen(),
    StudyScreen(),
    ShopScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

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
