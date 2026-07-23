import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/profil_service.dart';
import '../../services/annonce_service.dart';
import '../../theme/app_theme.dart';
import '../home/detail_annonce_screen.dart';
import '../auth/login_screen.dart';
import '../favoris/favoris_screen.dart';
import 'mes_annonces_screen.dart';
import 'mes_transactions_screen.dart';

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Déconnexion',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        content: Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            color: AppColors.onSurfaceVariant,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: TextStyle(color: AppColors.rosyTaupe)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mauveShadow,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnecter',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
            child: CircularProgressIndicator(color: AppColors.dustyRose)),
      );
    }

    final nom = _profil != null
        ? '${_profil!['prenom']} ${_profil!['nom']}'
        : 'Utilisateur';
    final photo = _profil?['photo'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.dustyRose,
        onRefresh: _charger,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                child: Column(
                  children: [
                    // Photo
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.dustyRose, width: 2.5),
                          ),
                          child: ClipOval(
                            child: _uploadingPhoto
                                ? Container(
                              color: AppColors.softBlush,
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.dustyRose),
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
                                child: Icon(Icons.person,
                                    color: AppColors.dustyRose,
                                    size: 40),
                              ),
                            )
                                : Container(
                              color: AppColors.softBlush,
                              child: Icon(Icons.person,
                                  color: AppColors.dustyRose,
                                  size: 40),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _changerPhoto,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.mauveShadow,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Nom
                    Text(
                      nom,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _membreDepuis(),
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 13,
                        color: AppColors.rosyTaupe,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bouton modifier
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _ouvrirModification(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.mauveShadow,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'Modifier le profil',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: _buildStat(
                            '${_annonces.length}',
                            'ANNONCES',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStat(
                            _noteMoyenne != null
                                ? _noteMoyenne!.toStringAsFixed(1)
                                : '-',
                            'Avis',
                            icon: _noteMoyenne != null
                                ? Icons.star
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Mes annonces
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mes annonces',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    if (_annonces.length > 4)
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MesAnnoncesScreen()),
                        ),
                        child: Text(
                          'Voir tout',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.dustyRose,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            _annonces.isEmpty
                ? SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Center(
                  child: Text(
                    'Aucune annonce publiée',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      color: AppColors.rosyTaupe,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            )
                : SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final annonce = _annonces[index];
                    final images = (annonce['images_annonce']
                    as List<dynamic>? ??
                        [])
                        .map((e) => e['url_image'] as String)
                        .toList();
                    final imageUrl =
                    images.isNotEmpty ? images.first : null;

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailAnnonceScreen(
                              annonceId: annonce['id'] as int),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                          Border.all(color: AppColors.paleOak),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius:
                                const BorderRadius.vertical(
                                    top: Radius.circular(16)),
                                child: imageUrl != null
                                    ? CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                                    : Container(
                                  color: AppColors.softBlush,
                                  child: Center(
                                    child: Icon(
                                        Icons.image_outlined,
                                        color:
                                        AppColors.paleOak),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${(annonce['prix_actuel'] as num).toStringAsFixed(0)} FCFA',
                                    style: TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.mauveShadow,
                                    ),
                                  ),
                                  Text(
                                    annonce['titre'] ?? '',
                                    style: TextStyle(
                                      fontFamily: 'PlusJakartaSans',
                                      fontSize: 12,
                                      color: AppColors.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _annonces.length > 4
                      ? 4
                      : _annonces.length,
                ),
              ),
            ),

            // Menu
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.paleOak),
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
                      Divider(
                          color: AppColors.paleOak,
                          height: 1,
                          indent: 56),
                      _buildMenuItem(
                        icon: Icons.settings_outlined,
                        label: 'Paramètres',
                        onTap: () {},
                      ),
                      Divider(
                          color: AppColors.paleOak,
                          height: 1,
                          indent: 56),
                      _buildMenuItem(
                        icon: Icons.history,
                        label: "Historique d'achat",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MesTransactionsScreen()),
                        ),
                      ),
                      Divider(
                          color: AppColors.paleOak,
                          height: 1,
                          indent: 56),
                      _buildMenuItem(
                        icon: Icons.logout,
                        label: 'Déconnexion',
                        color: AppColors.dustyRose,
                        onTap: _deconnecter,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String valeur, String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.paleOak),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.dustyRose, size: 16),
                const SizedBox(width: 4),
              ],
              Text(
                valeur,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.mauveShadow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.rosyTaupe,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (color ?? AppColors.mauveShadow).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: c, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: c,
                ),
              ),
            ),
            if (color == null)
              Icon(Icons.chevron_right,
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
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(24)),
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
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Modifier le profil',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              _buildChamp('Prénom', prenomController),
              const SizedBox(height: 12),
              _buildChamp('Nom', nomController),
              const SizedBox(height: 12),
              _buildChamp('Téléphone', telController,
                  type: TextInputType.phone),
              const SizedBox(height: 20),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mauveShadow,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Enregistrer',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
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
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: type,
          style: TextStyle(
              fontFamily: 'PlusJakartaSans', color: AppColors.onSurface),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.softBlush,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
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