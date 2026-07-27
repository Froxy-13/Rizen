import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/admin_service.dart';
import '../../theme/app_theme.dart';
import '../home/detail_annonce_screen.dart';

IconData iconePourCategorie(String nom) {
  final n = nom.toLowerCase();
  if (n.contains('électro') || n.contains('electro') || n.contains('tech')) {
    return Icons.devices;
  }
  if (n.contains('mode') ||
      n.contains('vêtement') ||
      n.contains('vetement') ||
      n.contains('habill')) {
    return Icons.checkroom;
  }
  if (n.contains('maison') || n.contains('meuble') || n.contains('déco')) {
    return Icons.home_outlined;
  }
  if (n.contains('véhicule') ||
      n.contains('vehicule') ||
      n.contains('voiture') ||
      n.contains('auto')) {
    return Icons.directions_car_filled_outlined;
  }
  if (n.contains('sport') || n.contains('loisir')) {
    return Icons.sports_basketball_outlined;
  }
  if (n.contains('livre') || n.contains('éduc') || n.contains('educ')) {
    return Icons.menu_book_outlined;
  }
  if (n.contains('beaut') || n.contains('cosmé') || n.contains('cosme')) {
    return Icons.face_retouching_natural_outlined;
  }
  if (n.contains('enfant') || n.contains('jouet') || n.contains('bébé')) {
    return Icons.child_friendly_outlined;
  }
  return Icons.category_outlined;
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _service = AdminService();
  final _nouvelleCategorieController = TextEditingController();
  List<Map<String, dynamic>> _categories = [];
  int _annoncesActives = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final categories = await _service.getCategoriesAvecCompte();
    final stats = await _service.getStatistiquesAvancees();
    setState(() {
      _categories = categories;
      _annoncesActives = stats['annoncesActives'] as int;
      _loading = false;
    });
  }

  Future<void> _ajouterCategorie() async {
    final nom = _nouvelleCategorieController.text.trim();
    if (nom.isEmpty) return;
    _nouvelleCategorieController.clear();
    await _service.ajouterCategorie(nom);
    _charger();
  }

  Future<void> _renommer(Map<String, dynamic> categorie) async {
    final controller = TextEditingController(text: categorie['nom'] as String);
    final nouveauNom = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('Renommer la catégorie', style: AppTextStyles.titleMd),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.rosyTaupe)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md)),
            ),
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Enregistrer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (nouveauNom != null &&
        nouveauNom.isNotEmpty &&
        nouveauNom != categorie['nom']) {
      await _service.renommerCategorie(categorie['id'] as int, nouveauNom);
      _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _charger,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.navy),
                    ),
                    const SizedBox(width: AppSpacing.stackMd),
                    Text('Catégories', style: AppTextStyles.displayMd),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    "Gérez les segments de marché et l'organisation des annonces.",
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.rosyTaupe,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.stackLg),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'TOTAL\nCATÉGORIES',
                        '${_categories.length}',
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.gutter),
                    Expanded(
                      child: _buildStatCard(
                        'ANNONCES\nACTIVES',
                        '$_annoncesActives',
                        AppColors.emerald,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackLg + 8),

                if (_categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Aucune catégorie',
                          style: AppTextStyles.bodyMd
                              .copyWith(color: AppColors.rosyTaupe)),
                    ),
                  )
                else
                  ..._categories.map((c) => Padding(
                    padding:
                    const EdgeInsets.only(bottom: AppSpacing.stackMd),
                    child: _buildCategoryItem(c),
                  )),

                const SizedBox(height: AppSpacing.stackSm),
                _buildAddCategoryField(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String valeur, Color couleurAccent) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
        border: Border(
          left: BorderSide(color: couleurAccent, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelCaps),
          const SizedBox(height: 6),
          Text(
            valeur,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> categorie) {
    final nom = categorie['nom'] as String;
    final nombre = categorie['nombreAnnonces'] as int;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnnoncesCategorieScreen(
            categorieId: categorie['id'] as int,
            nomCategorie: nom,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(iconePourCategorie(nom),
                  color: AppColors.navy, size: 22),
            ),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nom, style: AppTextStyles.titleMd.copyWith(fontSize: 16)),
                  Text('$nombre annonce${nombre > 1 ? 's' : ''}',
                      style: AppTextStyles.bodySm),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _renommer(categorie),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.edit_outlined,
                    color: AppColors.rosyTaupe, size: 20),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: AppColors.rosyTaupe, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCategoryField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: _nouvelleCategorieController,
              onSubmitted: (_) => _ajouterCategorie(),
              style: AppTextStyles.bodyMd,
              decoration: InputDecoration(
                hintText: 'Nouvelle catégorie...',
                hintStyle: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.rosyTaupe,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: _ajouterCategorie,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Text(
                'Ajouter',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Annonces d'une catégorie donnée (tap-through depuis le chevron)
// ─────────────────────────────────────────────
class AnnoncesCategorieScreen extends StatefulWidget {
  final int categorieId;
  final String nomCategorie;

  const AnnoncesCategorieScreen({
    super.key,
    required this.categorieId,
    required this.nomCategorie,
  });

  @override
  State<AnnoncesCategorieScreen> createState() =>
      _AnnoncesCategorieScreenState();
}

class _AnnoncesCategorieScreenState extends State<AnnoncesCategorieScreen> {
  final _service = AdminService();
  List<Map<String, dynamic>> _annonces = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final data = await _service.getAnnoncesParCategorie(widget.categorieId);
    setState(() {
      _annonces = data;
      _loading = false;
    });
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
        title: Text(widget.nomCategorie, style: AppTextStyles.titleMd),
      ),
      body: _loading
          ? const Center(
          child: CircularProgressIndicator(color: AppColors.primary))
          : _annonces.isEmpty
          ? Center(
        child: Text('Aucune annonce dans cette catégorie',
            style: AppTextStyles.bodyMd
                .copyWith(color: AppColors.rosyTaupe)),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _annonces.length,
        itemBuilder: (context, index) =>
            _buildItem(_annonces[index]),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> annonce) {
    final profil = annonce['profils'] as Map<String, dynamic>?;
    final images = (annonce['images_annonce'] as List<dynamic>? ?? []);
    final imageUrl =
    images.isNotEmpty ? images.first['url_image'] as String : null;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DetailAnnonceScreen(annonceId: annonce['id'] as int),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.stackMd),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: imageUrl != null
                  ? CachedNetworkImage(
                imageUrl: imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 64,
                height: 64,
                color: AppColors.softBlush,
                child: const Icon(Icons.image_outlined,
                    color: AppColors.paleOak),
              ),
            ),
            const SizedBox(width: AppSpacing.stackMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    annonce['titre'] ?? '',
                    style: AppTextStyles.titleMd.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${profil?['prenom'] ?? ''} ${profil?['nom'] ?? ''}',
                    style: AppTextStyles.bodySm,
                  ),
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
            const Icon(Icons.chevron_right, color: AppColors.paleOak),
          ],
        ),
      ),
    );
  }
}