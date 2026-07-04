import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'register_screen.dart';
import '../main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _connexion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.connexion(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } on AuthException catch (e) {
      print('AUTH EXCEPTION: ${e.message} | STATUS: ${e.statusCode}');
      if (mounted) {
        String message = 'Une erreur est survenue, veuillez réessayer';
        if (e.message.contains('Invalid login credentials')) {
          message = 'Email ou mot de passe incorrect';
        } else if (e.statusCode == '500' ||
            e.message.contains('Database error granting user') ||
            e.message.contains('unexpected_failure')) {
          message = 'Votre compte a été suspendu. Contactez l\'administrateur.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Logo / Titre
                Center(
                  child: Text(
                    'Rizen',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mauveShadow,
                      letterSpacing: -0.02,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Bienvenue sur Rizen',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                Text(
                  'Connexion',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                    letterSpacing: -0.01,
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'exemple@email.com',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!value.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Minimum 6 caractères';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _isLoading ? null : _connexion,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Se connecter'),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pas encore de compte ? ',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'S\'inscrire',
                        style: TextStyle(
                          color: AppColors.mauveShadow,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}