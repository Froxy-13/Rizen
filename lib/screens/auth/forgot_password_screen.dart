import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _emailEnvoye = false;

  Future<void> _envoyer() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un email valide')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.rizen://reset-callback',
      );
      setState(() => _emailEnvoye = true);
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _emailEnvoye ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Bouton retour
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.arrow_back,
                color: AppColors.onSurface, size: 20),
          ),
        ),

        const SizedBox(height: 24),

        // Titre
        Text(
          'Mot de passe oublié ?',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Saisissez votre adresse e-mail pour recevoir un lien de réinitialisation.',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 24),

        // Image placeholder — remplace 'assets/images/forgot_password.png' par ton image
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/forgot_password.png',
            width: double.infinity,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(Icons.image_outlined,
                    color: AppColors.rosyTaupe, size: 40),
              ),
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Label
        Text(
          'ADRESSE E-MAIL',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),

        // Champ email
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            color: AppColors.onSurface,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: 'votre@email.com',
            prefixIcon: Icon(Icons.mail_outline,
                color: AppColors.rosyTaupe, size: 20),
          ),
        ),

        const SizedBox(height: 28),

        // Bouton envoyer
        ElevatedButton(
          onPressed: _loading ? null : _envoyer,
          child: _loading
              ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
          )
              : const Text('Envoyer le lien'),
        ),

        const Spacer(),

        // Logo bas de page
        Center(
          child: Image.asset(
            'assets/images/Rizen.png',
            height: 50,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 48,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Email envoyé !',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Vérifiez votre boîte mail et cliquez sur le lien pour réinitialiser votre mot de passe.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 14,
            color: AppColors.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Retour à la connexion'),
        ),
      ],
    );
  }
}