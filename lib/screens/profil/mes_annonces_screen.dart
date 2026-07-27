import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/profil_service.dart';
import '../../theme/app_theme.dart';
import '../home/detail_annonce_screen.dart';
import '../annonce/modifier_annonce_screen.dart';

enum _FiltreMesAnnonces { toutes, actives, vendues, masquees }

class MesAnnoncesScreen extends StatefulWidget {
  const MesAnnoncesScreen({super.key});

  @override
  State<MesAnnoncesScreen> createState() => _MesAnnoncesScreenState();
}

class _MesAnnoncesScreenState extends State<MesAnnoncesScreen> {
  final _service = ProfilService();
  List<Map<String, dynamic>> _annonces = [];
  bool _loading = true;
  _FiltreMesAnnonces _filtre = _FiltreMesAnnonces.toutes;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final annonces = await _service.getMesAnnonces();
    setState(() {
      _annonces = annonces;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _annoncesFiltrees {
    switch (_filtre) {
      case _FiltreMesAnnonces.toutes:
        return _annonces;
      case _FiltreMesAnnonces.actives:
        return _annonces.where((a) => a['statut'] == 'active').toList();
      case _FiltreMesAnnonces.vendues:
        return _annonces.where((a) => a['statut'] == 'vendue').toList();
      case _FiltreMesAnnonces.masquees:
        return _annonces.where((a) => a['statut'] == 'suspendue').toList();
    }
  }

  double get _valeurActive {
    return _annonces
        .where((a) => a['statut'] == 'active')
        .fold<double>(
        0, (sum, a) => sum + (a['prix_actuel'] as num).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    final nombreActives =
        _annonces.where((a) => a['statut'] == 'active').length;
    final liste = _annoncesFiltrees;

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
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerMargin,
                    AppSpacing.stackMd,
                    AppSpacing.containerMargin,
                    0,
                  ),
                  child: Row(
                    children: [
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
                      const SizedBox(width: AppSpacing.stackMd),
                      Text('Mes annonces', style: AppTextStyles.displayMd),
                    ],
                  ),
                ),
              ),

              // ── Carte résumé ──────────────────────────────
              if (!_loading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.containerMargin,
                      AppSpacing.stackLg,
                      AppSpacing.containerMargin,
                      0,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VALEUR EN LIGNE',
                                style: AppTextStyles.labelCaps.copyWith(
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_valeurActive.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$nombreActives annonce${nombreActives > 1 ? 's' : ''} active${nombreActives > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront_outlined,
                                color: AppColors.primary, size: 22),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Filtres ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.containerMargin,
                    AppSpacing.stackLg,
                    AppSpacing.containerMargin,
                    0,
                  ),
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _FiltreMesAnnonces.values.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.stackSm),
                      itemBuilder: (context, index) {
                        final f = _FiltreMesAnnonces.values[index];
                        final label = switch (f) {
                          _FiltreMesAnnonces.toutes => 'Toutes',
                          _FiltreMesAnnonces.actives => 'Actives',
                          _FiltreMesAnnonces.vendues => 'Vendues',
                          _FiltreMesAnnonces.masquees => 'Masquées',
                        };
                        final selected = _filtre == f;
                        return GestureDetector(
                          onTap: () => setState(() => _filtre = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 9),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.navy
                                  : AppColors.softBlush,
                              borderRadius:
                              BorderRadius.circular(AppRadius.full),
                            ),
                            child: Center(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.navy,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // ── Grille ──────────────────────────────────
              _loading
                  ? const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary),
                ),
              )
                  : liste.isEmpty
                  ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 56, color: AppColors.paleOak),
                      const SizedBox(height: AppSpacing.stackMd),
                      Text(
                        'Aucune annonce dans cette catégorie',
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
                  AppSpacing.stackLg,
                  AppSpacing.containerMargin,
                  40,
                ),
                sliver: SliverGrid(
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.gutter,
                    mainAxisSpacing: AppSpacing.gutter,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildCard(liste[index]),
                    childCount: liste.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> annonce) {
    final images = (annonce['images_annonce'] as List<dynamic>? ?? [])
        .map((e) => e['url_image'] as String)
        .toList();
    final imageUrl = images.isNotEmpty ? images.first : null;
    final statut = annonce['statut'] as String? ?? 'active';

    late String badgeLabel;
    late Color badgeColor;
    switch (statut) {
      case 'vendue':
        badgeLabel = 'Vendue';
        badgeColor = Colors.blue;
        break;
      case 'suspendue':
        badgeLabel = 'Masquée';
        badgeColor = Colors.orange;
        break;
      default:
        badgeLabel = 'Active';
        badgeColor = AppColors.emerald;
    }

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
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: badgeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
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
}