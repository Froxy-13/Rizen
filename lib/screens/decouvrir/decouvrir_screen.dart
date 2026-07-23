import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/annonce.dart';
import '../../services/annonce_service.dart';
import '../../theme/app_theme.dart';
import '../home/detail_annonce_screen.dart';
import 'filtres_bottom_sheet.dart';

class DecouvrirScreen extends StatefulWidget {
  const DecouvrirScreen({super.key});

  @override
  State<DecouvrirScreen> createState() => _DecouvrirScreenState();
}

class _DecouvrirScreenState extends State<DecouvrirScreen> {
  final _service = AnnonceService();
  final _searchController = TextEditingController();

  List<Annonce> _annonces = [];
  List<Map<String, dynamic>> _categories = [];
  Set<int> _favorisIds = {};
  int? _categorieSelectionnee;
  bool _loading = true;
  String _recherche = '';
  FiltresResult? _filtres;

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
        const SnackBar(
            content: Text('Connectez-vous pour ajouter aux favoris')),
      );
      return;
    }
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

  double get _prixMinDisponible {
    if (_annonces.isEmpty) return 0;
    return _annonces.map((a) => a.prixActuel).reduce((a, b) => a < b ? a : b);
  }

  double get _prixMaxDisponible {
    if (_annonces.isEmpty) return 500000;
    final max =
    _annonces.map((a) => a.prixActuel).reduce((a, b) => a > b ? a : b);
    return max > _prixMinDisponible ? max : _prixMinDisponible + 1;
  }

  List<String> get _villesDisponibles {
    final villes =
    _annonces.map((a) => a.ville).whereType<String>().toSet().toList();
    villes.sort();
    return villes;
  }

  bool get _filtresActifs {
    if (_filtres == null) return false;
    return _filtres!.ville != null ||
        _filtres!.tri != TriAnnonces.recent ||
        _filtres!.prix.start > _prixMinDisponible ||
        _filtres!.prix.end < _prixMaxDisponible;
  }

  List<Annonce> get _annoncesFiltrees {
    Iterable<Annonce> resultat = _annonces;

    if (_recherche.isNotEmpty) {
      final q = _recherche.toLowerCase();
      resultat = resultat.where((a) =>
      a.titre.toLowerCase().contains(q) ||
          (a.ville?.toLowerCase().contains(q) ?? false));
    }

    if (_filtres != null) {
      resultat = resultat.where((a) =>
      a.prixActuel >= _filtres!.prix.start &&
          a.prixActuel <= _filtres!.prix.end);

      if (_filtres!.ville != null) {
        resultat = resultat.where((a) => a.ville == _filtres!.ville);
      }
    }

    final liste = resultat.toList();

    switch (_filtres?.tri ?? TriAnnonces.recent) {
      case TriAnnonces.prixCroissant:
        liste.sort((a, b) => a.prixActuel.compareTo(b.prixActuel));
        break;
      case TriAnnonces.prixDecroissant:
        liste.sort((a, b) => b.prixActuel.compareTo(a.prixActuel));
        break;
      case TriAnnonces.recent:
        liste.sort((a, b) => b.datePublication.compareTo(a.datePublication));
        break;
    }

    return liste;
  }

  Future<void> _ouvrirFiltres() async {
    final prixMin = _prixMinDisponible;
    final prixMax = _prixMaxDisponible;

    final result = await showModalBottomSheet<FiltresResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FiltresBottomSheet(
        filtresActuels: _filtres ??
            FiltresResult(
              prix: RangeValues(prixMin, prixMax),
              ville: null,
              tri: TriAnnonces.recent,
            ),
        prixMin: prixMin,
        prixMax: prixMax,
        villesDisponibles: _villesDisponibles,
      ),
    );

    if (result != null) {
      setState(() => _filtres = result);
    }
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
              // ── Chips catégories ─────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.stackMd),
                  child: SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.containerMargin,
                      ),
                      itemCount: _categories.length + 1,
                      separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.stackSm),
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildChip('TOUT', null);
                        }
                        final cat = _categories[index - 1];
                        return _buildChip(
                          (cat['nom'] as String).toUpperCase(),
                          cat['id'],
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── Titre + compteur + bouton filtrer ────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerMargin,
                    AppSpacing.stackLg,
                    AppSpacing.containerMargin,
                    AppSpacing.stackMd,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Découvrir', style: AppTextStyles.displayMd),
                          const SizedBox(height: 2),
                          Text(
                            '${_annoncesFiltrees.length} article${_annoncesFiltrees.length > 1 ? 's' : ''} trouvé${_annoncesFiltrees.length > 1 ? 's' : ''}',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.rosyTaupe,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: _ouvrirFiltres,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                            BorderRadius.circular(AppRadius.md),
                            boxShadow: AppShadows.card,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.tune,
                                  size: 18, color: AppColors.navy),
                              const SizedBox(width: 6),
                              Text(
                                'Filtrer',
                                style: AppTextStyles.bodySm.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy,
                                ),
                              ),
                              if (_filtresActifs) ...[
                                const SizedBox(width: 6),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Search bar ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerMargin,
                    0,
                    AppSpacing.containerMargin,
                    AppSpacing.stackMd,
                  ),
                  child: Container(
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
                        hintText: 'Rechercher un article...',
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
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Grille ─────────────────────────────────────
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
                      const Icon(Icons.search_off,
                          size: 48, color: AppColors.paleOak),
                      const SizedBox(height: AppSpacing.stackSm),
                      Text(
                        'Aucun article trouvé',
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
                  0,
                  AppSpacing.containerMargin,
                  120,
                ),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.gutter,
                    mainAxisSpacing: AppSpacing.stackLg,
                    childAspectRatio: 0.7,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                        _buildListingCard(_annoncesFiltrees[index]),
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
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.softBlush,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: selected ? AppColors.white : AppColors.rosyTaupe,
          ),
        ),
      ),
    );
  }

  // ── Carte listing : prix incrusté sur l'image (style "Découvrir") ──
  Widget _buildListingCard(Annonce annonce) {
    final estFavori = _favorisIds.contains(annonce.id);
    final imageUrl =
    annonce.images.isNotEmpty ? annonce.images.first : null;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailAnnonceScreen(annonceId: annonce.id),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.softBlush,
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.softBlush,
                      child: const Icon(Icons.broken_image_outlined,
                          color: AppColors.paleOak),
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
                // Favori
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => _toggleFavori(annonce),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        estFavori
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
                // Badge prix incrusté
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Text(
                      '${annonce.prixActuel.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackSm),
          Text(
            annonce.titre,
            style: AppTextStyles.titleMd.copyWith(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (annonce.ville != null) ...[
            const SizedBox(height: 2),
            Text(
              annonce.ville!,
              style: AppTextStyles.bodySm.copyWith(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}