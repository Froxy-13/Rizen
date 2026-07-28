import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/profil_service.dart';
import '../../theme/app_theme.dart';
import '../home/detail_annonce_screen.dart';
import '../annonce/modifier_annonce_screen.dart';
import '../auth/login_screen.dart';
import '../favoris/favoris_screen.dart';
import 'mes_annonces_screen.dart';
import 'mes_transactions_screen.dart';
import '../../widgets/confirmation_dialog.dart';
import 'changer_mot_de_passe_screen.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _service = ProfilService();
  Map<String, dynamic>? _profil;
  List<Map<String, dynamic>> _annonces = [];
  double? _noteMoyenne;
  bool _loading = true;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final profil = await _service.getMonProfil();
      final annonces = await _service.getMesAnnonces();
      final note = await _service.getNotemoyenne();
      setState(() {
        _profil = profil;
        _annonces = annonces;
        _noteMoyenne = note;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _changerPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await _service.uploadPhotoProfil(picked.path);
      setState(() {
        _profil = {...?_profil, 'photo': url};
        _uploadingPhoto = false;
      });
    } catch (e) {
      setState(() => _uploadingPhoto = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
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
      await _service.deconnecter();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
        );
      }
    }
  }

  String _membreDepuis() {
    if (_profil == null) return '';
    final date = DateTime.tryParse(_profil!['created_at'] ?? '');
    if (date == null) return '';
    final mois = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return 'Membre depuis ${mois[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final nom = _profil != null
        ? '${_profil!['prenom']} ${_profil!['nom']}'
        : 'Utilisateur';
    final photo = _profil?['photo'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _charger,
        child: CustomScrollView(
          slivers: [
            // ── Header profil ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                child: Column(
                  children: [
                    // Photo
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.white, width: 4),
                            boxShadow: AppShadows.card,
                          ),
                          child: ClipOval(
                            child: _uploadingPhoto
                                ? Container(
                              color: AppColors.softBlush,
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary),
                              ),
                            )
                                : photo != null
                                ? CachedNetworkImage(
                              imageUrl: photo,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                  color: AppColors.softBlush),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.softBlush,
                                child: const Icon(Icons.person,
                                    color: AppColors.primary,
                                    size: 44),
                              ),
                            )
                                : Container(
                              color: AppColors.softBlush,
                              child: const Icon(Icons.person,
                                  color: AppColors.primary,
                                  size: 44),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _changerPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.stackMd),

                    Text(nom, style: AppTextStyles.headlineSm),
                    const SizedBox(height: 4),
                    Text(
                      _membreDepuis(),
                      style: AppTextStyles.bodySm,
                    ),
                    const SizedBox(height: 10),

                    // Modifier le profil (édition nom/prénom/téléphone)
                    TextButton(
                      onPressed: _ouvrirModification,
                      child: Text(
                        'Modifier le profil',
                        style: AppTextStyles.bodySm.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackMd),

                    // ── Carte stats fusionnée ────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        boxShadow: AppShadows.card,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStat('${_annonces.length}', 'ANNONCES'),
                          Container(
                            height: 36,
                            width: 1,
                            color: AppColors.paleOak,
                          ),
                          _buildStat(
                            _noteMoyenne != null
                                ? _noteMoyenne!.toStringAsFixed(1)
                                : '-',
                            'NOTE',
                            icon: _noteMoyenne != null
                                ? Icons.star
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                  ],
                ),
              ),
            ),

            // ── Section Compte ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin, 0,
                  AppSpacing.containerMargin,
                  AppSpacing.stackSm,
                ),
                child: Text('Compte', style: AppTextStyles.headlineSm),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.containerMargin),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    boxShadow: AppShadows.card,
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.favorite_border,
                        label: 'Mes favoris',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const FavorisScreen()),
                        ),
                      ),
                      const Divider(
                          color: AppColors.paleOak, height: 1, indent: 60),
                      _buildMenuItem(
                        icon: Icons.lock_reset_outlined,
                        label: 'Changer le mot de passe',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                              const ChangerMotDePasseScreen()),
                        ),
                      ),
                      const Divider(
                          color: AppColors.paleOak, height: 1, indent: 60),
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        label: 'Paramètres',
                        onTap: () {},
                      ),
                      const Divider(
                          color: AppColors.paleOak, height: 1, indent: 60),
                      _buildMenuItem(
                        icon: Icons.history,
                        label: "Historique d'achat",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MesTransactionsScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Section Mes annonces ─────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin,
                  AppSpacing.stackLg,
                  AppSpacing.containerMargin,
                  AppSpacing.stackSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mes annonces', style: AppTextStyles.headlineSm),
                    if (_annonces.length > 4)
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MesAnnoncesScreen()),
                        ),
                        child: Text(
                          'VOIR TOUT',
                          style: AppTextStyles.labelCaps.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            _annonces.isEmpty
                ? SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Center(
                  child: Text(
                    'Aucune annonce publiée',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.rosyTaupe,
                    ),
                  ),
                ),
              ),
            )
                : SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.containerMargin),
              sliver: SliverGrid(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.gutter,
                  mainAxisSpacing: AppSpacing.gutter,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                      _buildAnnonceCard(_annonces[index]),
                  childCount: _annonces.length > 4
                      ? 4
                      : _annonces.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.stackLg + 8)),

            // ── Déconnexion ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.containerMargin),
                child: SizedBox(
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
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 140)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnonceCard(Map<String, dynamic> annonce) {
    final images = (annonce['images_annonce'] as List<dynamic>? ?? [])
        .map((e) => e['url_image'] as String)
        .toList();
    final imageUrl = images.isNotEmpty ? images.first : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DetailAnnonceScreen(annonceId: annonce['id'] as int),
        ),
      ).then((_) => _charger()),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.lg)),
                    child: SizedBox.expand(
                      child: imageUrl != null
                          ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        color: AppColors.softBlush,
                        child: const Center(
                          child: Icon(Icons.image_outlined,
                              color: AppColors.paleOak),
                        ),
                      ),
                    ),
                  ),
                  // Menu rapide : modifier cette annonce
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () async {
                        final modifie = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ModifierAnnonceScreen(annonce: annonce),
                          ),
                        );
                        if (modifie == true) _charger();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.more_horiz,
                            size: 18, color: AppColors.navy),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    annonce['titre'] ?? '',
                    style: AppTextStyles.titleMd.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(annonce['prix_actuel'] as num).toStringAsFixed(0)} FCFA',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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

  Widget _buildStat(String valeur, String label, {IconData? icon}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              const Icon(Icons.star, color: Color(0xFFFFB800), size: 17),
              const SizedBox(width: 4),
            ],
            Text(
              valeur,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.labelCaps),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
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

  void _ouvrirModification() {
    final nomController =
    TextEditingController(text: _profil?['nom'] ?? '');
    final prenomController =
    TextEditingController(text: _profil?['prenom'] ?? '');
    final telController =
    TextEditingController(text: _profil?['telephone'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.paleOak,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.stackMd),
              Text('Modifier le profil', style: AppTextStyles.headlineSm),
              const SizedBox(height: AppSpacing.stackLg),
              _buildChamp('Prénom', prenomController),
              const SizedBox(height: AppSpacing.stackMd),
              _buildChamp('Nom', nomController),
              const SizedBox(height: AppSpacing.stackMd),
              _buildChamp('Téléphone', telController,
                  type: TextInputType.phone),
              const SizedBox(height: AppSpacing.stackLg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _service.mettreAJourProfil(
                      nom: nomController.text.trim(),
                      prenom: prenomController.text.trim(),
                      telephone: telController.text.isEmpty
                          ? null
                          : telController.text.trim(),
                    );
                    _charger();
                  },
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChamp(String label, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          style: AppTextStyles.bodyMd,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.softBlush,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}