import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/confirmation_dialog.dart';
import '../auth/login_screen.dart';
import '../profil/changer_mot_de_passe_screen.dart';

class AdminProfilScreen extends StatefulWidget {
  final AdminService service;
  final VoidCallback onVoirSignalements;

  const AdminProfilScreen({
    super.key,
    required this.service,
    required this.onVoirSignalements,
  });

  @override
  State<AdminProfilScreen> createState() => _AdminProfilScreenState();
}

class _AdminProfilScreenState extends State<AdminProfilScreen> {
  Map<String, dynamic>? _profil;
  Map<String, int>? _bilan;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final profil = await widget.service.getMonProfilAdmin();
    final bilan = await widget.service.getBilanModeration();
    setState(() {
      _profil = profil;
      _bilan = bilan;
      _loading = false;
    });
  }

  String _membreDepuis() {
    final iso = _profil?['created_at'] as String?;
    if (iso == null) return '';
    final date = DateTime.tryParse(iso);
    if (date == null) return '';
    const mois = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return 'Administrateur depuis ${mois[date.month - 1]} ${date.year}';
  }

  void _changerMotDePasse() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangerMotDePasseScreen()),
    );
  }

  void _apropos() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.92,
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
                            'pour le Sénégal. Elle permet à n\'importe qui '
                            'de vendre et d\'acheter des articles d\'occasion '
                            'en toute confiance, directement entre '
                            'particuliers.',
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      _buildParagraphe(
                        'La plateforme mise sur la confiance : négociation '
                            'intégrée entre acheteur et vendeur, paiement '
                            'sécurisé par séquestre (l\'argent n\'est '
                            'reversé qu\'après confirmation de réception), '
                            'et une messagerie directe pour échanger avant '
                            'toute transaction.',
                      ),
                      const SizedBox(height: AppSpacing.stackMd),
                      _buildParagraphe(
                        'Le rôle du panneau d\'administration est de '
                            'garantir cette confiance au quotidien : '
                            'modération des annonces, traitement des '
                            'signalements et résolution des litiges entre '
                            'utilisateurs.',
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

  Future<void> _deconnecter() async {
    final confirm = await confirmerAction(
      context,
      titre: 'Déconnexion',
      message: 'Voulez-vous vraiment vous déconnecter ?',
      labelConfirmer: 'Déconnecter',
      destructif: true,
    );

    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final nom =
    '${_profil?['prenom'] ?? ''} ${_profil?['nom'] ?? ''}'.trim();
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    final photo = _profil?['photo'] as String?;
    final emailVerifie =
        Supabase.instance.client.auth.currentUser?.emailConfirmedAt != null;
    final bilan = _bilan!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _charger,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Identité ──────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: AppColors.white, width: 4),
                          boxShadow: AppShadows.card,
                        ),
                        child: ClipOval(
                          child: photo != null
                              ? CachedNetworkImage(
                            imageUrl: photo,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.softBlush,
                              child: const Icon(Icons.person,
                                  color: AppColors.primary, size: 40),
                            ),
                          )
                              : Container(
                            color: AppColors.softBlush,
                            child: const Icon(Icons.person,
                                color: AppColors.primary, size: 40),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackSm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                          BorderRadius.circular(AppRadius.full),
                        ),
                        child: const Text(
                          'SUPERADMIN',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackSm),
                      Text(nom.isEmpty ? 'Administrateur' : nom,
                          style: AppTextStyles.headlineSm),
                      const SizedBox(height: 2),
                      Text(email, style: AppTextStyles.bodySm),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 12, color: AppColors.rosyTaupe),
                          const SizedBox(width: 4),
                          Text(_membreDepuis(),
                              style: AppTextStyles.bodySm),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.stackLg + 8),

                // ── Bilan de modération ──────────────────
                Text('Bilan de modération',
                    style: AppTextStyles.headlineSm),
                const SizedBox(height: AppSpacing.stackMd),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('${bilan['signalementsTraites']}',
                          'Signalements traités'),
                    ),
                    const SizedBox(width: AppSpacing.gutter),
                    Expanded(
                      child: _buildStatCard(
                          '${bilan['litigesResolus']}', 'Litiges résolus'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.gutter),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('${bilan['annoncesModerees']}',
                          'Annonces modérées'),
                    ),
                    const SizedBox(width: AppSpacing.gutter),
                    Expanded(
                      child: _buildStatCard(
                          '${bilan['utilisateursSuspendus']}',
                          'Utilisateurs suspendus'),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.stackLg + 8),

                // ── Sécurité ──────────────────────────────
                Text('Sécurité', style: AppTextStyles.headlineSm),
                const SizedBox(height: AppSpacing.stackMd),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.lock_reset_outlined,
                        label: 'Changer le mot de passe',
                        onTap: _changerMotDePasse,
                      ),
                      const Divider(
                          color: AppColors.paleOak, height: 1, indent: 60),
                      _buildMenuItem(
                        icon: Icons.email_outlined,
                        label: 'Email de récupération',
                        sousTitre:
                        emailVerifie ? 'Vérifié' : 'Non vérifié',
                        sousTitreCouleur: emailVerifie
                            ? AppColors.emerald
                            : AppColors.error,
                        onTap: null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.stackLg + 8),

                // ── Paramètres ────────────────────────────
                Text('Paramètres', style: AppTextStyles.headlineSm),
                const SizedBox(height: AppSpacing.stackMd),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.notifications_none,
                        label: 'Signalements en attente',
                        sousTitre: 'Voir les alertes à traiter',
                        onTap: widget.onVoirSignalements,
                      ),
                      const Divider(
                          color: AppColors.paleOak, height: 1, indent: 60),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        label: 'À propos de la plateforme',
                        onTap: _apropos,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.stackLg + 8),

                // ── Déconnexion ───────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _deconnecter,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(
                          color: AppColors.error, width: 1.5),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(AppRadius.full)),
                    ),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Déconnexion'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String valeur, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valeur,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySm),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    String? sousTitre,
    Color? sousTitreCouleur,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.navy.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: AppColors.navy, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.titleMd.copyWith(fontSize: 14)),
                  if (sousTitre != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (sousTitreCouleur == AppColors.emerald)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.check_circle,
                                size: 12, color: AppColors.emerald),
                          ),
                        Text(
                          sousTitre,
                          style: AppTextStyles.bodySm.copyWith(
                            color: sousTitreCouleur ?? AppColors.rosyTaupe,
                            fontWeight: sousTitreCouleur != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right,
                  color: AppColors.paleOak, size: 20),
          ],
        ),
      ),
    );
  }
}