import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/annonce.dart';
import '../../services/annonce_service.dart';
import '../../theme/app_theme.dart';
import '../home/detail_annonce_screen.dart';

class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  final _service = AnnonceService();
  List<Annonce> _favoris = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }

      final ids = await _service.getFavorisIds(userId);
      if (ids.isEmpty) {
        setState(() {
          _favoris = [];
          _loading = false;
        });
        return;
      }

      final data = await Supabase.instance.client
          .from('annonces')
          .select('*, images_annonce(url_image, ordre)')
          .inFilter('id', ids.toList())
          .eq('statut', 'active');

      setState(() {
        _favoris = (data as List).map((e) => Annonce.fromMap(e)).toList();
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

  Future<void> _retirerFavori(Annonce annonce) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _favoris.removeWhere((a) => a.id == annonce.id));

    try {
      await _service.toggleFavori(annonce.id, userId, true);
    } catch (_) {
      _charger(); // rollback
    }
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
              // Titre
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Text(
                    'Mes favoris',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mauveShadow,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),

              // Contenu
              _loading
                  ? const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.dustyRose),
                ),
              )
                  : _favoris.isEmpty
                  ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_border,
                          size: 56, color: AppColors.paleOak),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun favori pour l\'instant',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          color: AppColors.rosyTaupe,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                        _buildItem(_favoris[index]),
                    childCount: _favoris.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(Annonce annonce) {
    final imageUrl =
    annonce.images.isNotEmpty ? annonce.images.first : null;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailAnnonceScreen(annonceId: annonce.id),
          ),
        );
        _charger(); // Recharge au retour (au cas où le favori a été retiré)
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.paleOak),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF744253).withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
              child: imageUrl != null
                  ? CachedNetworkImage(
                imageUrl: imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 100,
                  height: 100,
                  color: AppColors.softBlush,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  color: AppColors.softBlush,
                  child: Icon(Icons.broken_image_outlined,
                      color: AppColors.paleOak),
                ),
              )
                  : Container(
                width: 100,
                height: 100,
                color: AppColors.softBlush,
                child: Icon(Icons.image_outlined,
                    color: AppColors.paleOak),
              ),
            ),

            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      annonce.titre,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 14,
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
                        fontSize: 15,
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
                          Text(
                            annonce.ville!,
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 11,
                              color: AppColors.rosyTaupe,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bouton retirer favori
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _retirerFavori(annonce),
                child: Icon(Icons.favorite,
                    color: AppColors.dustyRose, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}