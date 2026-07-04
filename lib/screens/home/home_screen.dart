import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/annonce.dart';
import '../../services/annonce_service.dart';
import '../../theme/app_theme.dart';
import 'detail_annonce_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = AnnonceService();
  final _searchController = TextEditingController();

  List<Annonce> _annonces = [];
  List<Map<String, dynamic>> _categories = [];
  Set<int> _favorisIds = {};
  int? _categorieSelectionnee;
  bool _loading = true;
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final cats = await _service.getCategories();
      final annonces = await _service.getAnnonces(
        categorieId: _categorieSelectionnee,
      );
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final favoris = userId != null
          ? await _service.getFavorisIds(userId)
          : <int>{};

      setState(() {
        _categories = cats;
        _annonces = annonces;
        _favorisIds = favoris;
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
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour ajouter aux favoris')),
      );
      return;
    }
    final estFavori = _favorisIds.contains(annonce.id);
    // Mise à jour optimiste
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
      // Rollback si erreur
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
    return _annonces.where((a) =>
    a.titre.toLowerCase().contains(q) ||
        (a.ville?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.dustyRose,
          onRefresh: _charger,
          child: CustomScrollView(
            slivers: [
              // ── AppBar ──────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rizen',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.mauveShadow,
                          letterSpacing: -0.56,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Barre de recherche
                      TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _recherche = v),
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          color: AppColors.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Rechercher une annonce...',
                          hintStyle: TextStyle(color: AppColors.rosyTaupe),
                          prefixIcon: Icon(Icons.search, color: AppColors.rosyTaupe),
                          filled: true,
                          fillColor: AppColors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.paleOak),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.paleOak),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.dustyRose),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Chips catégories ─────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8,
                    ),
                    itemCount: _categories.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Chip "Tout"
                        return _buildChip('Tout', null);
                      }
                      final cat = _categories[index - 1];
                      return _buildChip(cat['nom'], cat['id']);
                    },
                  ),
                ),
              ),

              // ── Grille annonces ──────────────────────────
              _loading
                  ? const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.dustyRose,
                  ),
                ),
              )
                  : _annoncesFiltrees.isEmpty
                  ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined,
                          size: 48, color: AppColors.paleOak),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune annonce trouvée',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          color: AppColors.rosyTaupe,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                        _buildCard(_annoncesFiltrees[index]),
                    childCount: _annoncesFiltrees.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, int? categorieId) {
    final selected = _categorieSelectionnee == categorieId;
    return GestureDetector(
      onTap: () {
        setState(() => _categorieSelectionnee = categorieId);
        _charger();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.mauveShadow : AppColors.softBlush,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.white : AppColors.mauveShadow,
            letterSpacing: 0.04,
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Annonce annonce) {
    final estFavori = _favorisIds.contains(annonce.id);
    final imageUrl = annonce.images.isNotEmpty ? annonce.images.first : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailAnnonceScreen(annonceId: annonce.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.paleOak),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF744253).withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
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
                      top: Radius.circular(16),
                    ),
                    child: imageUrl != null
                        ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.softBlush,
                        child: Center(
                          child: Icon(Icons.image_outlined,
                              color: AppColors.paleOak),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.softBlush,
                        child: Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: AppColors.paleOak),
                        ),
                      ),
                    )
                        : Container(
                      color: AppColors.softBlush,
                      child: Center(
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
                          color: AppColors.dustyRose,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Infos
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    annonce.titre,
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${annonce.prixActuel.toStringAsFixed(0)} FCFA',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mauveShadow,
                    ),
                  ),
                  if (annonce.ville != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 12, color: AppColors.rosyTaupe),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            annonce.ville!,
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 11,
                              color: AppColors.rosyTaupe,
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
}