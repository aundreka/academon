import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_shell.dart';
import 'core/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ujqmkwyfunwlvkwqvimi.supabase.co',
    anonKey: 'sb_publishable_i8ZgH3xyf_kTogOfcPbQBw_MESUsMsH',
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
      home: const AppRoot(),
    );
  }
}
