import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'theme/app_theme.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/splash/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  runApp(const RizenApp());
}

class RizenApp extends StatefulWidget {
  const RizenApp({super.key});

  @override
  State<RizenApp> createState() => _RizenAppState();
}

class _RizenAppState extends State<RizenApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _ecouterAuthChanges();
  }

  void _ecouterAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        // L'utilisateur a cliqué sur le lien de réinitialisation
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (_) => const ResetPasswordScreen()),
              (_) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Rizen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}