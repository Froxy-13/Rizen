import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/annonce.dart';
import '../../services/annonce_service.dart';
import '../../theme/app_theme.dart';
import 'detail_annonce_screen.dart';
import '../../utils/auth_guard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = AnnonceService();
  final _searchController = TextEditingController();

  List<Annonce> _annonces = [];
  List<Map<String, dynamic>> _topVendeurs = [];
  Set<int> _favorisIds = {};
  Map<int, double> _prixNegocies = {};
  bool _loading = true;
  String _recherche = '';

  // ── Contenu éditorial statique (pas de backend pour l'instant) ──
  static const List<Map<String, String>> _conseils = [
    {
      'tag': 'GUIDE VENDEUR',
      'titre': 'Comment bien photographier ses articles',
      'image':
      'https://images.unsplash.com/photo-1492724441997-5dc865305da7?q=80&w=1000',
    },
    {
      'tag': 'TENDANCE',
      'titre': 'Les tendances de la mode circulaire au Sénégal',
      'image':
      'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?q=80&w=1000',
    },
  ];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final annonces = await _service.getAnnonces();
      final topVendeurs = await _service.getTopVendeurs();
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final favoris = userId != null
          ? await _service.getFavorisIds(userId)
          : <int>{};
      final prixNegocies = userId != null
          ? await _service.getMesNegociationsAcceptees(userId)
          : <int, double>{};

      setState(() {
        _annonces = annonces;
        _topVendeurs = topVendeurs;
        _favorisIds = favoris;
        _prixNegocies = prixNegocies;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> _toggleFavori(Annonce annonce) async {
    if (exigerConnexion(context)) return;
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final estFavori = _favorisIds.contains(annonce.id);
    setState(() {
      if (estFavori) {
        _favorisIds.remove(annonce.id);
      } else {
        _favorisIds.add(annonce.id);
      }
    });
    try {
      await _service.toggleFavori(annonce.id, userId, estFavori);
    } catch (_) {
      setState(() {
        if (estFavori) {
          _favorisIds.add(annonce.id);
        } else {
          _favorisIds.remove(annonce.id);
        }
      });
    }
  }

  List<Annonce> get _annoncesFiltrees {
    if (_recherche.isEmpty) return _annonces;
    final q = _recherche.toLowerCase();
    return _annonces
        .where((a) =>
    a.titre.toLowerCase().contains(q) ||
        (a.ville?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _charger,
          child: CustomScrollView(
            slivers: [
              // ── Header ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.containerMargin,
                    AppSpacing.stackMd,
                    AppSpacing.containerMargin,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rizen', style: AppTextStyles.displayMd),
                      const SizedBox(height: AppSpacing.stackMd),

                      // Search bar — blanc pur, sans bordure, ombre douce
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: AppShadows.card,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (v) => setState(() => _recherche = v),
                          style: AppTextStyles.bodyMd,
                          decoration: InputDecoration(
                            hintText: 'Rechercher une annonce...',
                            hintStyle: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.rosyTaupe,
                            ),
                            prefixIcon: const Icon(Icons.search,
                                color: AppColors.rosyTaupe),
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(AppRadius.lg),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Top Vendeurs ──────────────────────────────
              if (!_loading && _topVendeurs.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader('Top Vendeurs'),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 96,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.containerMargin,
                      ),
                      itemCount: _topVendeurs.length,
                      itemBuilder: (context, index) =>
                          _buildVendeurItem(_topVendeurs[index]),
                    ),
                  ),
                ),
              ],

              // ── Annonces récentes ─────────────────────────
              SliverToBoxAdapter(
                child: _buildSectionHeader('Annonces récentes'),
              ),

              _loading
                  ? const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
              )
                  : _annoncesFiltrees.isEmpty
                  ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inbox_outlined,
                          size: 48, color: AppColors.paleOak),
                      const SizedBox(height: AppSpacing.stackSm),
                      Text(
                        'Aucune annonce trouvée',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.rosyTaupe,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.containerMargin,
                  AppSpacing.stackSm,
                  AppSpacing.containerMargin,
                  8,
                ),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.gutter,
                    mainAxisSpacing: AppSpacing.gutter,
                    childAspectRatio: 0.68,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                        _buildCard(_annoncesFiltrees[index]),
                    childCount: _annoncesFiltrees.length,
                  ),
                ),
              ),

              // ── Conseils & Inspiration ────────────────────
              if (!_loading)
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildSectionHeader('Conseils & Inspiration'),
                      ..._conseils.map((c) => _buildInspirationCard(
                        titre: c['titre']!,
                        tag: c['tag']!,
                        imageUrl: c['image']!,
                      )),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header de section (titre + éventuel "TOUT VOIR") ──────
  Widget _buildSectionHeader(String titre, {String? actionText}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.containerMargin,
        AppSpacing.stackLg,
        AppSpacing.containerMargin,
        AppSpacing.stackSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titre, style: AppTextStyles.headlineSm),
          if (actionText != null)
            Text(
              actionText,
              style: AppTextStyles.labelCaps.copyWith(
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  // ── Item vendeur (avatar + nom) ────────────────────────────
  Widget _buildVendeurItem(Map<String, dynamic> vendeur) {
    final photo = vendeur['photo'] as String?;
    final prenom = vendeur['prenom'] as String? ?? 'Vendeur';

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.containerMargin),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.softBlush,
              backgroundImage: photo != null ? NetworkImage(photo) : null,
              child: photo == null
                  ? Icon(Icons.person_outline,
                  color: AppColors.primary, size: 22)
                  : null,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            prenom,
            style: AppTextStyles.bodySm.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.navy,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Annonce annonce) {
    final estFavori = _favorisIds.contains(annonce.id);
    final estMonAnnonce =
        annonce.utilisateurId ==
            Supabase.instance.client.auth.currentUser?.id;
    final imageUrl =
    annonce.images.isNotEmpty ? annonce.images.first : null;
    final prixNegorie = _prixNegocies[annonce.id];
    final aPrixNegocie = prixNegorie != null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DetailAnnonceScreen(annonceId: annonce.id),
          ),
        );
      },
      child: Container(
        // Design sans bordure — hiérarchie par ombre douce uniquement
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg),
                    ),
                    child: imageUrl != null
                        ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.softBlush,
                        child: const Center(
                          child: Icon(Icons.image_outlined,
                              color: AppColors.paleOak),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.softBlush,
                        child: const Center(
                          child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.paleOak),
                        ),
                      ),
                    )
                        : Container(
                      color: AppColors.softBlush,
                      child: const Center(
                        child: Icon(Icons.image_outlined,
                            color: AppColors.paleOak, size: 32),
                      ),
                    ),
                  ),
                  // Bouton favori
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleFavori(annonce),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          estFavori
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  // Badge prix négocié
                  if (aPrixNegocie)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius:
                          BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Text(
                          'Prix négocié',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Badge Votre annonce (seller own listing)
                  if (estMonAnnonce)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                          BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Text(
                          'Votre annonce',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Infos
            Padding(
              padding: const EdgeInsets.all(AppSpacing.cardPadding * 0.6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    annonce.titre,
                    style: AppTextStyles.titleMd.copyWith(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Prix avec ou sans barré
                  if (aPrixNegocie) ...[
                    Text(
                      '${annonce.prixActuel.toStringAsFixed(0)} FCFA',
                      style: AppTextStyles.bodySm.copyWith(
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Text(
                      '${prixNegorie!.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ] else
                    Text(
                      '${annonce.prixActuel.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),

                  if (annonce.ville != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.rosyTaupe),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            annonce.ville!,
                            style: AppTextStyles.bodySm.copyWith(
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bannière conseil / inspiration (contenu statique) ─────
  Widget _buildInspirationCard({
    required String titre,
    required String tag,
    required String imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.containerMargin,
        vertical: AppSpacing.stackSm,
      ),
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            AppColors.navy.withOpacity(0.35),
            BlendMode.darken,
          ),
        ),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.stackLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            tag,
            style: AppTextStyles.labelCaps.copyWith(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            titre,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}