import 'package:flutter/material.dart';
import '../../services/profil_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/confirmation_dialog.dart';
import '../auth/login_screen.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  final _service = ProfilService();
  bool _suppressionEnCours = false;

  void _apropos() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.paleOak,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront_outlined,
                            color: AppColors.primary, size: 30),
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      Text('À propos de Rizen',
                          style: AppTextStyles.displayMd
                              .copyWith(fontSize: 26)),
                      const SizedBox(height: AppSpacing.stackMd),
                      _buildParagraphe(
                        'Rizen est une marketplace de seconde main pensée '
                            'pour le Sénégal. Vendez ce que vous n\'utilisez '
                            'plus, trouvez de bonnes affaires près de chez '
                            'vous, directement entre particuliers.',
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      _buildParagraphe(
                        'Négociez le prix directement dans l\'app, échangez '
                            'avec le vendeur ou l\'acheteur par messagerie, '
                            'et payez en toute confiance : l\'argent est '
                            'conservé en séquestre jusqu\'à ce que vous '
                            'confirmiez avoir bien reçu votre article.',
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('J\'ai compris'),
                        ),
                      ),
                      const SizedBox(height: 12),
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

  Widget _buildParagraphe(String texte) {
    return Text(
      texte,
      style: AppTextStyles.bodyMd.copyWith(
        color: AppColors.onSurfaceVariant,
        height: 1.6,
      ),
    );
  }

  void _aideSupport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.paleOak,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            Text('Besoin d\'aide ?', style: AppTextStyles.headlineSm),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'Une question, un problème avec une transaction, un bug ? '
                  'Écrivez-nous, on répond au plus vite.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.email_outlined,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.stackMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email support',
                            style: AppTextStyles.labelCaps),
                        // ⚠️ Placeholder — remplace par une vraie adresse
                        // de support avant mise en production.
                        Text('support@rizen.sn',
                            style: AppTextStyles.titleMd
                                .copyWith(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _supprimerCompte() async {
    final confirm = await confirmerAction(
      context,
      titre: 'Supprimer votre compte ?',
      message: 'Cette action est définitive : vos annonces, messages et '
          'historique seront perdus. Vous ne pourrez pas revenir en '
          'arrière.',
      labelConfirmer: 'Supprimer',
      destructif: true,
    );

    if (confirm != true) return;

    setState(() => _suppressionEnCours = true);
    try {
      await _service.supprimerMonCompte();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _suppressionEnCours = false);
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
        title: Text('Paramètres', style: AppTextStyles.titleMd),
      ),
      body: _suppressionEnCours
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.info_outline,
                    label: 'À propos de Rizen',
                    onTap: _apropos,
                  ),
                  const Divider(
                      color: AppColors.paleOak, height: 1, indent: 60),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    label: 'Aide / Support',
                    onTap: _aideSupport,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.stackLg + 8),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: AppShadows.card,
              ),
              child: _buildMenuItem(
                icon: Icons.delete_outline,
                label: 'Supprimer mon compte',
                color: AppColors.error,
                onTap: _supprimerCompte,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    Color? color,
    required VoidCallback onTap,
  }) {
    final c = color ?? AppColors.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: (color ?? AppColors.navy).withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: c, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: c,
                ),
              ),
            ),
            if (color == null)
              const Icon(Icons.chevron_right,
                  color: AppColors.paleOak, size: 20),
          ],
        ),
      ),
    );
  }
}