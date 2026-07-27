import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Traduit une erreur réseau (pas de connexion internet) en message clair.
  bool _estErreurReseau(Object e) {
    final texte = e.toString().toLowerCase();
    return texte.contains('socketexception') ||
        texte.contains('failed host lookup') ||
        texte.contains('network is unreachable') ||
        texte.contains('connection failed') ||
        texte.contains('clientexception');
  }

  Future<void> _inscription() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.inscription(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        telephone: _telephoneController.text.trim(),
        adresse: _adresseController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compte créé avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (mounted) {
        String message = 'Une erreur est survenue';
        if (e.message.contains('already registered')) {
          message = 'Cet email est déjà utilisé';
        } else if (e.message.contains('Password should be')) {
          message = 'Le mot de passe doit contenir au moins 6 caractères';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_estErreurReseau(e)
                ? 'Aucune connexion à internet'
                : 'Une erreur est survenue, veuillez réessayer'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _connexionGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      const webClientId =
          '993089007993-1cs8lggo5ir2un1nacan3270hhqcnil9.apps.googleusercontent.com';
      const androidClientId =
          '993089007993-1n4qb344tiv5ktnod3c8n5nhm6mgvqoa.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: androidClientId,
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Tokens Google manquants');
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_estErreurReseau(e)
                ? 'Aucune connexion à internet'
                : 'Erreur Google : $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.onSurface,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Créer un compte',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Bouton Google
                OutlinedButton(
                  onPressed: _isGoogleLoading ? null : _connexionGoogle,
                  child: _isGoogleLoading
                      ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://www.google.com/favicon.ico',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'S\'inscrire avec Google',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Séparateur
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.paleOak)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          color: AppColors.rosyTaupe,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.paleOak)),
                  ],
                ),

                const SizedBox(height: 20),

                // Prénom
                _buildLabel('PRÉNOM'),
                TextFormField(
                  controller: _prenomController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      color: AppColors.onSurface,
                      fontSize: 14),
                  decoration: const InputDecoration(hintText: 'Abdoulaye'),
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 16),

                // Nom
                _buildLabel('NOM'),
                TextFormField(
                  controller: _nomController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      color: AppColors.onSurface,
                      fontSize: 14),
                  decoration: const InputDecoration(hintText: 'Diop'),
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 16),

                // Email
                _buildLabel('EMAIL'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      color: AppColors.onSurface,
                      fontSize: 14),
                  decoration:
                  const InputDecoration(hintText: 'contact@rizen.sn'),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ obligatoire';
                    if (!v.contains('@')) return 'Email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Téléphone
                _buildLabel('TÉLÉPHONE'),
                TextFormField(
                  controller: _telephoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      color: AppColors.onSurface,
                      fontSize: 14),
                  decoration:
                  const InputDecoration(hintText: '77 000 00 00'),
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 16),

                // Quartier / Adresse
                _buildLabel('QUARTIER / ADRESSE'),
                TextFormField(
                  controller: _adresseController,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      color: AppColors.onSurface,
                      fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Mermoz, Dakar',
                    suffixIcon: Icon(Icons.location_on_outlined,
                        color: AppColors.rosyTaupe, size: 20),
                  ),
                  validator: (v) =>
                  v == null || v.isEmpty ? 'Champ obligatoire' : null,
                ),
                const SizedBox(height: 16),

                // Mot de passe
                _buildLabel('MOT DE PASSE'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      color: AppColors.onSurface,
                      fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.rosyTaupe,
                        size: 20,
                      ),
                      onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ obligatoire';
                    if (v.length < 6) return 'Minimum 6 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmer mot de passe
                _buildLabel('CONFIRMER LE MOT DE PASSE'),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      color: AppColors.onSurface,
                      fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.rosyTaupe,
                        size: 20,
                      ),
                      onPressed: () => setState(() =>
                      _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ obligatoire';
                    if (v != _passwordController.text)
                      return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Bouton inscription
                ElevatedButton(
                  onPressed: _isLoading ? null : _inscription,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Créer mon compte'),
                ),

                const SizedBox(height: 16),

                // Lien connexion
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Déjà un compte ? ',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 14,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Se connecter',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.link,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Continuer sans compte
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      // Important : déconnecte toute session résiduelle
                      // avant de basculer en mode visiteur.
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MainScreen()),
                        );
                      }
                    },
                    child: Text(
                      'Continuer sans compte',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 13,
                        color: AppColors.link,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
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