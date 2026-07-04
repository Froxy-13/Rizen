import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  runApp(const RizenApp());
}

class RizenApp extends StatelessWidget {
  const RizenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rizen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const LoginScreen(),
    );
  }
}