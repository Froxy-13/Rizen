import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/annonce.dart';
import '../../services/annonce_service.dart';
import '../../theme/app_theme.dart';
import '../../services/message_service.dart';
import '../messages/chat_screen.dart';
import '../negociations/negociation_screen.dart';

class DetailAnnonceScreen extends StatefulWidget {
  final int annonceId;

  const DetailAnnonceScreen({super.key, required this.annonceId});

  @override
  State<DetailAnnonceScreen> createState() => _DetailAnnonceScreenState();
}

class _DetailAnnonceScreenState extends State<DetailAnnonceScreen> {
  final _service = AnnonceService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  int _photoIndex = 0;
  bool _estFavori = false;
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
      final userId = Supabase.instance.client.auth.currentUser?.id;
      bool favori = false;
      double? prixNegocie;
      List<double> prixVendeur = [];

      if (userId != null) {
        final ids = await _service.getFavorisIds(userId);
        favori = ids.contains(widget.annonceId);

        // Prix négocié pour l'acheteur
        final negAcheteur =
        await _service.getMesNegociationsAcceptees(userId);
        prixNegocie = negAcheteur[widget.annonceId];

        // Prix négociés pour le vendeur (si c'est son annonce)
        final vendeurId = data['utilisateur_id'] as String;
        if (vendeurId == userId) {
          final negVendeur =
          await _service.getNegociationsAccepteesVendeur(userId);
          prixVendeur = negVendeur[widget.annonceId] ?? [];
        }
      }

      setState(() {
        _data = data;
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
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Connectez-vous pour ajouter aux favoris')),
      );
      return;
    }
    setState(() => _estFavori = !_estFavori);
    try {
      await _service.toggleFavori(widget.annonceId, userId, !_estFavori);
    } catch (_) {
      setState(() => _estFavori = !_estFavori);
    }
  }

  void _ouvrirSignalement() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
            Text('Connectez-vous pour signaler une annonce')),
      );
      return;
    }

    String? raisonSelectionnee;
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Signaler cette annonce',
            style: TextStyle(
              fontFamily: 'PlusJakartaSans',
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
              fontSize: 16,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: raisonSelectionnee,
                hint: Text('Choisir une raison',
                    style: TextStyle(
                        color: AppColors.rosyTaupe, fontSize: 13)),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.paleOak),
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
                  hintStyle: TextStyle(color: AppColors.rosyTaupe),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.paleOak),
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
                backgroundColor: AppColors.mauveShadow,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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
            child:
            CircularProgressIndicator(color: AppColors.dustyRose)),
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── AppBar avec carrousel ──────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.white,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child:
                Icon(Icons.arrow_back, color: AppColors.onSurface),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: _ouvrirSignalement,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.flag_outlined,
                      color: AppColors.rosyTaupe, size: 20),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: images.isEmpty
                  ? Container(
                color: AppColors.softBlush,
                child: Center(
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
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                              (i) => Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 3),
                            width: _photoIndex == i ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _photoIndex == i
                                  ? AppColors.dustyRose
                                  : AppColors.white
                                  .withOpacity(0.6),
                              borderRadius:
                              BorderRadius.circular(9999),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Contenu ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prix — logique acheteur vs vendeur
                  if (_prixNegocie != null) ...[
                    // Acheteur avec prix négocié
                    Text(
                      '${prix.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 16,
                        color: AppColors.rosyTaupe,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_prixNegocie!.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mauveShadow,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.softBlush,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Prix négocié pour vous',
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dustyRose,
                        ),
                      ),
                    ),
                  ] else if (estVendeur &&
                      _prixNegociesVendeur.isNotEmpty) ...[
                    // Vendeur avec négociations acceptées
                    Text(
                      '${prix.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mauveShadow,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.softBlush,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline,
                              size: 14, color: AppColors.dustyRose),
                          const SizedBox(width: 6),
                          Text(
                            '${_prixNegociesVendeur.length} acheteur${_prixNegociesVendeur.length > 1 ? 's ont' : ' a'} un prix négocié',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.dustyRose,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Prix normal
                    Text(
                      '${prix.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.mauveShadow,
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),

                  // Titre
                  Text(
                    _data!['titre'],
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Localisation
                  if (localisation.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.rosyTaupe),
                        const SizedBox(width: 4),
                        Text(
                          localisation,
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 13,
                            color: AppColors.rosyTaupe,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),
                  Divider(color: AppColors.paleOak),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Description',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _data!['description'],
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 14,
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 20),
                  Divider(color: AppColors.paleOak),
                  const SizedBox(height: 16),

                  // Vendeur
                  Text(
                    'Vendeur',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.softBlush,
                        backgroundImage: profil?['photo'] != null
                            ? NetworkImage(profil!['photo'])
                            : null,
                        child: profil?['photo'] == null
                            ? Icon(Icons.person_outline,
                            color: AppColors.dustyRose)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        vendeurNom,
                        style: TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Boutons bas de page ────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF744253).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Favori
            GestureDetector(
              onTap: _toggleFavori,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.paleOak),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _estFavori ? Icons.favorite : Icons.favorite_border,
                  color: AppColors.dustyRose,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Contacter
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final userId =
                      Supabase.instance.client.auth.currentUser?.id;
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Connectez-vous pour contacter le vendeur')),
                    );
                    return;
                  }
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
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.softBlush,
                  foregroundColor: AppColors.mauveShadow,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                label: const Text('Contacter',
                    style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 8),

            // Négocier
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final userId =
                      Supabase.instance.client.auth.currentUser?.id;
                  if (userId == null) return;
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
                  final prixAffiche =
                      _prixNegocie ?? prix;
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mauveShadow,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.handshake_outlined, size: 18),
                label: const Text('Négocier',
                    style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}