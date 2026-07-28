import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class ChangerMotDePasseScreen extends StatefulWidget {
  const ChangerMotDePasseScreen({super.key});

  @override
  State<ChangerMotDePasseScreen> createState() =>
      _ChangerMotDePasseScreenState();
}

class _ChangerMotDePasseScreenState extends State<ChangerMotDePasseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _actuelController = TextEditingController();
  final _nouveauController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureActuel = true;
  bool _obscureNouveau = true;
  bool _obscureConfirm = true;
  bool _resterConnecte = true;
  bool _loading = false;

  @override
  void dispose() {
    _actuelController.dispose();
    _nouveauController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validerNouveauMotDePasse(String? value) {
    if (value == null || value.isEmpty) return 'Champ obligatoire';
    if (value.length < 8) return 'Minimum 8 caractères';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Doit contenir au moins une majuscule';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Doit contenir au moins un chiffre';
    }
    return null;
  }

  Future<void> _confirmer() async {
    if (!_formKey.currentState!.validate()) return;

    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) return;

    setState(() => _loading = true);

    try {
      // 1. Vérifie le mot de passe actuel en ré-authentifiant l'utilisateur
      try {
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: _actuelController.text,
        );
      } on AuthException {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mot de passe actuel incorrect'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // 2. Change le mot de passe
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _nouveauController.text),
      );

      // 3. Respecte le choix "rester connecté"
      if (!_resterConnecte) {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe mis à jour')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Changer le mot de passe', style: AppTextStyles.titleMd),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('MOT DE PASSE ACTUEL'),
              const SizedBox(height: AppSpacing.stackSm),
              _buildChampMotDePasse(
                controller: _actuelController,
                obscure: _obscureActuel,
                onToggle: () =>
                    setState(() => _obscureActuel = !_obscureActuel),
                validator: (v) =>
                v == null || v.isEmpty ? 'Champ obligatoire' : null,
              ),

              const SizedBox(height: AppSpacing.stackLg),
              _buildLabel('NOUVEAU MOT DE PASSE'),
              const SizedBox(height: AppSpacing.stackSm),
              _buildChampMotDePasse(
                controller: _nouveauController,
                obscure: _obscureNouveau,
                onToggle: () =>
                    setState(() => _obscureNouveau = !_obscureNouveau),
                validator: _validerNouveauMotDePasse,
              ),

              const SizedBox(height: AppSpacing.stackLg),
              _buildLabel('CONFIRMER LE NOUVEAU MOT DE PASSE'),
              const SizedBox(height: AppSpacing.stackSm),
              _buildChampMotDePasse(
                controller: _confirmController,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ obligatoire';
                  if (v != _nouveauController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.stackMd),

              // Encadré d'info sécurité
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.shield_outlined,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pour plus de sécurité, utilisez au moins 8 '
                            'caractères avec une majuscule et un chiffre.',
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.primary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.stackLg),

              // Rester connecté
              GestureDetector(
                onTap: () =>
                    setState(() => _resterConnecte = !_resterConnecte),
                child: Row(
                  children: [
                    Checkbox(
                      value: _resterConnecte,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (v) =>
                          setState(() => _resterConnecte = v ?? true),
                    ),
                    Expanded(
                      child: Text(
                        'Rester connecté après la modification',
                        style: AppTextStyles.bodyMd,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.stackLg + 8),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _confirmer,
                  child: _loading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Confirmer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: AppTextStyles.labelCaps);
  }

  Widget _buildChampMotDePasse({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        style: AppTextStyles.bodyMd,
        decoration: InputDecoration(
          hintText: '••••••••',
          hintStyle: AppTextStyles.bodyMd.copyWith(
            color: AppColors.rosyTaupe,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: AppColors.rosyTaupe,
              size: 20,
            ),
            onPressed: onToggle,
          ),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}