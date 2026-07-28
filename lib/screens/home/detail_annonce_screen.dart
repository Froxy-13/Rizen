import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/annonce_service.dart';
import '../../theme/app_theme.dart';
import '../../services/message_service.dart';
import '../messages/chat_screen.dart';
import '../negociations/negociation_screen.dart';
import '../transaction/paiement_screen.dart';
import '../annonce/modifier_annonce_screen.dart';
import '../../utils/auth_guard.dart';
import '../../widgets/confirmation_dialog.dart';

class DetailAnnonceScreen extends StatefulWidget {
  final int annonceId;

  const DetailAnnonceScreen({super.key, required this.annonceId});

  @override
  State<DetailAnnonceScreen> createState() => _DetailAnnonceScreenState();
}

class _DetailAnnonceScreenState extends State<DetailAnnonceScreen> {
  final _service = AnnonceService();
  Map<String, dynamic>? _data;
  Map<String, dynamic>? _noteVendeur;
  bool _loading = true;
  int _photoIndex = 0;
  bool _estFavori = false;
  bool _detailsOuverts = false;
  double? _prixNegocie;
  List<double> _prixNegociesVendeur = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final data = await _service.getAnnonceById(widget.annonceId);
      final vendeurId = data['utilisateur_id'] as String;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      bool favori = false;
      double? prixNegocie;
      List<double> prixVendeur = [];

      final noteVendeur = await _service.getNoteVendeur(vendeurId);

      if (userId != null) {
        final ids = await _service.getFavorisIds(userId);
        favori = ids.contains(widget.annonceId);

        // Prix négocié pour l'acheteur
        final negAcheteur =
        await _service.getMesNegociationsAcceptees(userId);
        prixNegocie = negAcheteur[widget.annonceId];

        // Prix négociés pour le vendeur (si c'est son annonce)
        if (vendeurId == userId) {
          final negVendeur =
          await _service.getNegociationsAccepteesVendeur(userId);
          prixVendeur = negVendeur[widget.annonceId] ?? [];
        }
      }

      setState(() {
        _data = data;
        _noteVendeur = noteVendeur;
        _estFavori = favori;
        _prixNegocie = prixNegocie;
        _prixNegociesVendeur = prixVendeur;
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

  Future<void> _toggleFavori() async {
    if (exigerConnexion(context)) return;
    final userId = Supabase.instance.client.auth.currentUser!.id;
    setState(() => _estFavori = !_estFavori);
    try {
      await _service.toggleFavori(widget.annonceId, userId, !_estFavori);
    } catch (_) {
      setState(() => _estFavori = !_estFavori);
    }
  }

  void _ouvrirSignalement() {
    if (exigerConnexion(context)) return;
    final userId = Supabase.instance.client.auth.currentUser!.id;

    String? raisonSelectionnee;
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg)),
          title: Text(
            'Signaler cette annonce',
            style: AppTextStyles.titleMd.copyWith(fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: raisonSelectionnee,
                hint: Text('Choisir une raison',
                    style: AppTextStyles.bodySm),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.paleOak),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                ),
                items: [
                  'Contenu inapproprié',
                  'Arnaque ou fraude',
                  'Article déjà vendu',
                  'Informations fausses',
                  'Autre',
                ]
                    .map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r,
                        style:
                        const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) =>
                    setStateDialog(() => raisonSelectionnee = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Description (optionnel)',
                  hintStyle: AppTextStyles.bodySm,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.paleOak),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler',
                  style: TextStyle(color: AppColors.rosyTaupe)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              onPressed: raisonSelectionnee == null
                  ? null
                  : () async {
                Navigator.pop(ctx);
                try {
                  await _service.signalerAnnonce(
                    annonceId: widget.annonceId,
                    userId: userId,
                    raison: raisonSelectionnee!,
                    description: descController.text.isEmpty
                        ? null
                        : descController.text,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Signalement envoyé')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur : $e')),
                    );
                  }
                }
              },
              child: const Text('Envoyer',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_data == null) {
      return const Scaffold(
        body: Center(child: Text('Annonce introuvable')),
      );
    }

    final images = (_data!['images_annonce'] as List<dynamic>? ?? [])
        .map((e) => e['url_image'] as String)
        .toList();
    final profil = _data!['profils'] as Map<String, dynamic>?;
    final categorie = _data!['categories'] as Map<String, dynamic>?;
    final vendeurNom = profil != null
        ? '${profil['prenom']} ${profil['nom']}'
        : 'Vendeur inconnu';
    final prix = (_data!['prix_actuel'] as num).toDouble();
    final ville = _data!['ville'] as String?;
    final quartier = _data!['quartier'] as String?;
    final localisation =
    [quartier, ville].where((e) => e != null).join(', ');
    final estVendeur = _data!['utilisateur_id'] ==
        Supabase.instance.client.auth.currentUser?.id;
    final estVendue = _data!['statut'] == 'vendue';
    final noteMoyenne = _noteVendeur?['note_moyenne'] as double?;
    final nombreAvis = _noteVendeur?['nombre_avis'] as int?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Carrousel image ─────────────────────────
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.navy.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: _ouvrirSignalement,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag_outlined,
                      color: Colors.white, size: 20),
                ),
              ),
              GestureDetector(
                onTap: _toggleFavori,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 8, 12, 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _estFavori ? Icons.favorite : Icons.favorite_border,
                    color: _estFavori ? AppColors.primary : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: images.isEmpty
                  ? Container(
                color: AppColors.softBlush,
                child: const Center(
                  child: Icon(Icons.image_outlined,
                      size: 64, color: AppColors.paleOak),
                ),
              )
                  : Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (i) =>
                        setState(() => _photoIndex = i),
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: images[i],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                              (i) => AnimatedContainer(
                            duration:
                            const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 3),
                            width: _photoIndex == i ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _photoIndex == i
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(
                                  AppRadius.full),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Sheet contenu (remonte légèrement sur l'image) ──
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre + catégorie
                    Text(
                      _data!['titre'],
                      style: AppTextStyles.headlineSm,
                    ),
                    if (categorie != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        (categorie['nom'] as String).toUpperCase(),
                        style: AppTextStyles.labelCaps,
                      ),
                    ],
                    const SizedBox(height: 10),

                    // Prix — logique acheteur vs vendeur
                    if (_prixNegocie != null) ...[
                      Text(
                        '${prix.toStringAsFixed(0)} FCFA',
                        style: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.rosyTaupe,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_prixNegocie!.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildTagInfo('Prix négocié pour vous'),
                    ] else if (estVendeur &&
                        _prixNegociesVendeur.isNotEmpty) ...[
                      Text(
                        '${prix.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildTagInfo(
                        '${_prixNegociesVendeur.length} acheteur${_prixNegociesVendeur.length > 1 ? 's ont' : ' a'} un prix négocié',
                      ),
                    ] else
                      Text(
                        '${prix.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),

                    const SizedBox(height: AppSpacing.stackLg),

                    // ── Bandeau "Vendu" ──────────────────────
                    if (estVendue && !estVendeur) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius:
                          BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Cet article a déjà été vendu',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.stackLg),
                    ],

                    // ── Carte vendeur ──────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                        BorderRadius.circular(AppRadius.xl),
                        boxShadow: AppShadows.card,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.softBlush,
                            backgroundImage: profil?['photo'] != null
                                ? NetworkImage(profil!['photo'])
                                : null,
                            child: profil?['photo'] == null
                                ? const Icon(Icons.person_outline,
                                color: AppColors.primary)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vendeurNom,
                                  style: AppTextStyles.titleMd,
                                ),
                                if (localisation.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                          Icons.location_on_outlined,
                                          size: 13,
                                          color: AppColors.rosyTaupe),
                                      const SizedBox(width: 3),
                                      Text(
                                        localisation,
                                        style: AppTextStyles.bodySm,
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.end,
                            children: [
                              if (noteMoyenne != null) ...[
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        color: Color(0xFFFFB800),
                                        size: 15),
                                    const SizedBox(width: 3),
                                    Text(
                                      noteMoyenne.toStringAsFixed(1),
                                      style: AppTextStyles.titleMd
                                          .copyWith(fontSize: 14),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$nombreAvis AVIS',
                                  style: AppTextStyles.labelCaps,
                                ),
                              ] else
                                Text(
                                  'Nouveau',
                                  style: AppTextStyles.bodySm,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.stackLg),

                    // ── Détails dépliables ──────────────────
                    GestureDetector(
                      onTap: () => setState(
                              () => _detailsOuverts = !_detailsOuverts),
                      child: Column(
                        children: [
                          const Divider(color: AppColors.paleOak),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Voir tous les détails',
                                    style: AppTextStyles.titleMd),
                                Icon(
                                  _detailsOuverts
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: AppColors.navy,
                                ),
                              ],
                            ),
                          ),
                          if (_detailsOuverts) ...[
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: AppSpacing.stackMd),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Description',
                                    style: AppTextStyles.titleMd
                                        .copyWith(fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _data!['description'] ?? '',
                                    style: AppTextStyles.bodyMd
                                        .copyWith(height: 1.5),
                                  ),
                                  const SizedBox(height: 14),
                                  if (categorie != null)
                                    _buildDetailRow('Catégorie',
                                        categorie['nom'] as String),
                                  if (localisation.isNotEmpty)
                                    _buildDetailRow(
                                        'Localisation', localisation),
                                ],
                              ),
                            ),
                          ],
                          const Divider(color: AppColors.paleOak),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.stackLg),

                    // ── Conseil sécurité ─────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius:
                        BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.verified_user_outlined,
                              color: AppColors.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Conseil de sécurité Rizen',
                                  style: AppTextStyles.titleMd
                                      .copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rencontrez toujours le vendeur dans '
                                      'un lieu public et vérifiez l\'article '
                                      'avant de payer.',
                                  style: AppTextStyles.bodySm.copyWith(
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Barre d'action bas de page ─────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xl)),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: estVendeur
            ? _buildBarreVendeur()
            : estVendue
            ? _buildBarreVendue()
            : _buildBarreAcheteur(prix, images),
      ),
    );
  }

  // ── Barre d'action quand l'annonce est déjà vendue (côté acheteur) ──
  Widget _buildBarreVendue() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.paleOak,
          disabledBackgroundColor: AppColors.paleOak,
          foregroundColor: AppColors.rosyTaupe,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.full)),
          elevation: 0,
        ),
        icon: const Icon(Icons.check_circle_outline, size: 20),
        label: const Text(
          'Article déjà vendu',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ── Barre d'action côté vendeur : juste "Modifier" ──
  Widget _buildBarreVendeur() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () async {
                final modifie = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ModifierAnnonceScreen(annonce: _data!),
                  ),
                );
                if (modifie == true) {
                  _charger();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full)),
                elevation: 0,
              ),
              icon: const Icon(Icons.edit_outlined, size: 20),
              label: const Text(
                'Modifier',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _confirmerSuppression,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full)),
              ),
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text(
                'Supprimer',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmerSuppression() async {
    final confirm = await confirmerAction(
      context,
      titre: 'Supprimer cette annonce ?',
      message:
      'Cette action est irréversible. L\'annonce et ses photos seront définitivement supprimées.',
      labelConfirmer: 'Supprimer',
      destructif: true,
    );

    if (confirm == true) {
      try {
        await _service.supprimerAnnonce(widget.annonceId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Annonce supprimée')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $e')),
          );
        }
      }
    }
  }

  // ── Barre d'action côté acheteur : Message / Négocier / Acheter ──
  Widget _buildBarreAcheteur(double prix, List<String> images) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Message + Négocier
        Row(
          children: [
            Expanded(
              child: _buildSecondaryButton(
                icon: Icons.chat_bubble_outline,
                label: 'Message',
                onTap: () async {
                  if (exigerConnexion(context)) return;
                  final userId =
                      Supabase.instance.client.auth.currentUser!.id;
                  final vendeurId =
                  _data!['utilisateur_id'] as String;
                  if (vendeurId == userId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Vous ne pouvez pas vous contacter vous-même')),
                    );
                    return;
                  }
                  final messageService = MessageService();
                  final convId =
                  await messageService.getOrCreateConversation(
                    annonceId: widget.annonceId,
                    userId: userId,
                    vendeurId: vendeurId,
                  );
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          conversationId: convId,
                          annonceTitre: _data!['titre'],
                          annonceImageUrl: images.isNotEmpty
                              ? images.first
                              : null,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryButton(
                icon: Icons.handshake_outlined,
                label: 'Négocier',
                onTap: () {
                  if (exigerConnexion(context)) return;
                  final userId =
                      Supabase.instance.client.auth.currentUser!.id;
                  final vendeurId =
                  _data!['utilisateur_id'] as String;
                  if (vendeurId == userId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Vous ne pouvez pas négocier votre propre annonce')),
                    );
                    return;
                  }
                  final prixAffiche = _prixNegocie ?? prix;
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => NegociationBottomSheet(
                      annonceId: widget.annonceId,
                      vendeurId: vendeurId,
                      prixActuel: prixAffiche,
                      titrAnnonce: _data!['titre'],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Acheter (pleine largeur)
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () async {
              if (exigerConnexion(context)) return;
              final userId =
                  Supabase.instance.client.auth.currentUser!.id;
              final vendeurId = _data!['utilisateur_id'] as String;
              if (vendeurId == userId) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Vous ne pouvez pas acheter votre propre annonce')),
                );
                return;
              }
              final prixFinal = _prixNegocie ?? prix;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaiementScreen(
                    annonceId: widget.annonceId,
                    vendeurId: vendeurId,
                    titreAnnonce: _data!['titre'],
                    montant: prixFinal,
                    imageUrl: images.isNotEmpty ? images.first : null,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg)),
              elevation: 0,
            ),
            icon: const Icon(Icons.shopping_cart_outlined, size: 20),
            label: const Text(
              'Acheter',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagInfo(String texte) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.softBlush,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        texte,
        style: AppTextStyles.bodySm.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.rosyTaupe,
                )),
          ),
          Expanded(
            child: Text(valeur, style: AppTextStyles.bodyMd),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.navy, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.navy, size: 19),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}