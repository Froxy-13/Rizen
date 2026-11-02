import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class VisitorGateScreen extends StatelessWidget {
  const VisitorGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.card,
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: AppColors.navy, size: 18),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      _buildIllustration(),
                      const SizedBox(height: AppSpacing.stackLg + 8),
                      _buildTitreEtDescription(),
                      const SizedBox(height: AppSpacing.stackLg + 8),
                      _buildHighlights(),
                      const SizedBox(height: AppSpacing.stackLg + 8),
                      _buildBoutons(context),
                      const SizedBox(height: AppSpacing.stackLg),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'RETOUR',
                          style: AppTextStyles.labelCaps,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withOpacity(0.12),
                AppColors.primary.withOpacity(0.0),
              ],
            ),
          ),
        ),
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            boxShadow: AppShadows.card,
          ),
          child: const Icon(Icons.lock_outline,
              size: 56, color: AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildTitreEtDescription() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              height: 1.15,
            ),
            children: [
              const TextSpan(text: 'Débloquez tout le\n'),
              TextSpan(
                text: 'potentiel',
                style: TextStyle(color: AppColors.primary),
              ),
              const TextSpan(text: ' de Rizen'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Text(
          'Connectez-vous ou créez un compte pour accéder à toutes '
              'les fonctionnalités : négociation, messagerie, mise en '
              'vente et bien plus.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.rosyTaupe,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildHighlights() {
    return Row(
      children: [
        Expanded(
            child: _buildHighlightItem(Icons.storefront_outlined, 'Vendre')),
        const SizedBox(width: AppSpacing.stackMd),
        Expanded(
            child: _buildHighlightItem(
                Icons.chat_bubble_outline, 'Messagerie')),
      ],
    );
  }

  Widget _buildHighlightItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 26),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.titleMd.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBoutons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full)),
              elevation: 0,
            ),
            child: const Text(
              'Se connecter',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.stackSm),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD9E2FF),
              foregroundColor: AppColors.navy,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full)),
              elevation: 0,
            ),
            child: const Text(
              'Créer un compte',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}