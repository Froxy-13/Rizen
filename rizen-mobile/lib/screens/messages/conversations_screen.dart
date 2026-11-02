import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/message_service.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';

enum _Filtre { tous, nonLus, ventes, achats }

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _service = MessageService();
  List<Map<String, dynamic>> _conversations = [];
  Map<int, Map<String, dynamic>> _autresParticipants = {};
  bool _loading = true;
  _Filtre _filtre = _Filtre.tous;

  String? get _userId =>
      Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    try {
      final userId = _userId;
      if (userId == null) {
        setState(() => _loading = false);
        return;
      }
      final data = await _service.getConversations(userId);

      final ids = data
          .map((d) => (d['conversations'] as Map?)?['id'] as int?)
          .whereType<int>()
          .toList();
      final participants =
      await _service.getAutresParticipants(ids, userId);

      setState(() {
        _conversations = data;
        _autresParticipants = participants;
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

  // ── Données dérivées d'une conversation brute ────────────
  Map<String, dynamic> _analyser(Map<String, dynamic> convData) {
    final conv = convData['conversations'] as Map<String, dynamic>?;
    final annonce = conv?['annonces'] as Map<String, dynamic>?;
    final messages =
    List<Map<String, dynamic>>.from(conv?['messages'] as List? ?? []);
    messages.sort((a, b) => DateTime.parse(b['date_envoi'])
        .compareTo(DateTime.parse(a['date_envoi'])));

    final userId = _userId;
    final nonLus = messages
        .where((m) => m['sender_id'] != userId && m['lu'] == false)
        .length;

    return {
      'conv': conv,
      'annonce': annonce,
      'convId': conv?['id'] as int?,
      'dernierMessage':
      messages.isNotEmpty ? messages.first['contenu'] as String? : null,
      'dateDernierMessage': messages.isNotEmpty
          ? DateTime.parse(messages.first['date_envoi'])
          : null,
      'nonLus': nonLus,
      'estVendeur': annonce?['utilisateur_id'] == userId,
    };
  }

  List<Map<String, dynamic>> get _conversationsAnalysees {
    final liste = _conversations
        .map(_analyser)
        .where((c) => c['convId'] != null)
        .toList();

    liste.sort((a, b) {
      final da = a['dateDernierMessage'] as DateTime?;
      final db = b['dateDernierMessage'] as DateTime?;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    switch (_filtre) {
      case _Filtre.tous:
        return liste;
      case _Filtre.nonLus:
        return liste.where((c) => (c['nonLus'] as int) > 0).toList();
      case _Filtre.ventes:
        return liste.where((c) => c['estVendeur'] == true).toList();
      case _Filtre.achats:
        return liste.where((c) => c['estVendeur'] == false).toList();
    }
  }

  String _formatHeure(DateTime? date) {
    if (date == null) return '';
    final maintenant = DateTime.now();
    final aujourdHui = DateTime(
        maintenant.year, maintenant.month, maintenant.day);
    final jourMessage = DateTime(date.year, date.month, date.day);
    final diffJours = aujourdHui.difference(jourMessage).inDays;

    if (diffJours == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } else if (diffJours == 1) {
      return 'Hier';
    } else if (diffJours < 7) {
      const jours = [
        'Lundi', 'Mardi', 'Mercredi', 'Jeudi',
        'Vendredi', 'Samedi', 'Dimanche'
      ];
      return jours[date.weekday - 1];
    } else {
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _ouvrirConversation(
      int convId, String titreAnnonce, String? imageUrl) async {
    final userId = _userId;
    if (userId != null) {
      await _service.marquerConversationLue(convId, userId);
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: convId,
          annonceTitre: titreAnnonce,
          annonceImageUrl: imageUrl,
        ),
      ),
    );
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    final liste = _conversationsAnalysees;

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
                      const Icon(Icons.chat_bubble_outline_rounded,
                          color: AppColors.navy, size: 26),
                      const SizedBox(width: 10),
                      Text('Messages', style: AppTextStyles.displayMd),
                    ],
                  ),
                ),
              ),

              // ── Filtres ─────────────────────────────────
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 55,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.containerMargin,
                      vertical: AppSpacing.stackSm,
                    ),
                    itemCount: _Filtre.values.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.stackSm),
                    itemBuilder: (context, index) {
                      final f = _Filtre.values[index];
                      return _buildFiltreChip(f);
                    },
                  ),
                ),
              ),

              // ── Liste ───────────────────────────────────
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
                      const Icon(Icons.chat_bubble_outline,
                          size: 56, color: AppColors.paleOak),
                      const SizedBox(height: AppSpacing.stackSm),
                      Text(
                        'Aucune conversation',
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
                  120,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                        _buildItem(liste[index]),
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

  Widget _buildFiltreChip(_Filtre f) {
    final selected = _filtre == f;
    final label = switch (f) {
      _Filtre.tous => 'TOUS',
      _Filtre.nonLus => 'NON LUS',
      _Filtre.ventes => 'VENTES',
      _Filtre.achats => 'ACHATS',
    };
    return GestureDetector(
      onTap: () => setState(() => _filtre = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.softBlush,
          borderRadius: BorderRadius.circular(AppRadius.md),
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

  Widget _buildItem(Map<String, dynamic> c) {
    final annonce = c['annonce'] as Map<String, dynamic>?;
    final convId = c['convId'] as int;
    final nonLus = c['nonLus'] as int;
    final participant = _autresParticipants[convId];

    final images = (annonce?['images_annonce'] as List<dynamic>? ?? []);
    final imageUrl =
    images.isNotEmpty ? images.first['url_image'] as String : null;
    final titreAnnonce = annonce?['titre'] as String? ?? 'Annonce supprimée';

    final nomParticipant = participant != null
        ? '${participant['prenom'] ?? ''} ${participant['nom'] ?? ''}'.trim()
        : titreAnnonce;
    final photoParticipant = participant?['photo'] as String?;

    final dernierMessage =
        c['dernierMessage'] as String? ?? 'Démarrer la conversation';
    final heure = _formatHeure(c['dateDernierMessage'] as DateTime?);

    return GestureDetector(
      onTap: () => _ouvrirConversation(convId, titreAnnonce, imageUrl),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.stackSm),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            // Avatar du participant, avec la photo de l'annonce en repli
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: photoParticipant != null
                  ? CachedNetworkImage(
                imageUrl: photoParticipant,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 56,
                  height: 56,
                  color: AppColors.softBlush,
                ),
              )
                  : imageUrl != null
                  ? CachedNetworkImage(
                imageUrl: imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 56,
                height: 56,
                color: AppColors.softBlush,
                child: const Icon(Icons.person_outline,
                    color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 14),

            // Contenu texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          nomParticipant,
                          style: AppTextStyles.titleMd,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        heure,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          color: nonLus > 0
                              ? AppColors.primary
                              : AppColors.rosyTaupe,
                          fontWeight: nonLus > 0
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    titreAnnonce,
                    style: AppTextStyles.bodySm.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          dernierMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: nonLus > 0
                                ? AppColors.onSurface
                                : AppColors.rosyTaupe,
                            fontWeight: nonLus > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (nonLus > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            nonLus > 9 ? '9+' : '$nonLus',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
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