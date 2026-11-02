import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/message_service.dart';
import '../../theme/app_theme.dart';
import '../../services/negociation_service.dart';
import '../../services/transaction_service.dart';
import '../negociations/negociation_screen.dart';
import '../transaction/paiement_screen.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String annonceTitre;
  final String? annonceImageUrl;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.annonceTitre,
    this.annonceImageUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _service = MessageService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _userId = Supabase.instance.client.auth.currentUser?.id;
  final Map<int, String> _negociationsTraitees = {};
  final Map<int, String> _transactionsStatuts = {};
  Map<String, dynamic>? _autreParticipant;

  late final Stream<List<Map<String, dynamic>>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _messagesStream = _service.streamMessages(widget.conversationId);
    _chargerStatutsNegociations();
    _chargerStatutsTransactions();
    _chargerParticipant();
    _marquerCommeLue();
  }

  Future<void> _marquerCommeLue() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _service.marquerConversationLue(widget.conversationId, userId);
    } catch (e) {
      debugPrint('Erreur marquerConversationLue: $e');
    }
  }

  Future<void> _chargerParticipant() async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final profil =
      await _service.getAutreParticipant(widget.conversationId, userId);
      if (mounted && profil != null) {
        setState(() => _autreParticipant = Map<String, dynamic>.from(profil));
      }
    } catch (_) {}
  }

  Future<void> _chargerStatutsNegociations() async {
    try {
      final statuts = await NegociationService()
          .getStatutsNegociations(widget.conversationId);
      if (mounted) setState(() => _negociationsTraitees.addAll(statuts));
    } catch (_) {}
  }

  Future<void> _chargerStatutsTransactions() async {
    try {
      final userId = _userId;
      if (userId == null) return;
      final transactions =
      await TransactionService().getMesTransactions(userId);
      final Map<int, String> statuts = {};
      for (final t in transactions) {
        statuts[t['id'] as int] = t['statut'] as String;
      }
      if (mounted) setState(() => _transactionsStatuts.addAll(statuts));
    } catch (_) {}
  }

  Future<void> _envoyer() async {
    final texte = _messageController.text.trim();
    if (texte.isEmpty || _userId == null) return;

    _messageController.clear();

    try {
      await _service.envoyerMessage(
        conversationId: widget.conversationId,
        expediteurId: _userId,
        contenu: texte,
      );
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = _autreParticipant?['photo'] as String?;
    final nomParticipant = _autreParticipant != null
        ? '${_autreParticipant!['prenom'] ?? ''} ${_autreParticipant!['nom'] ?? ''}'
        .trim()
        : widget.annonceTitre;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.softBlush,
              backgroundImage: photo != null ? NetworkImage(photo) : null,
              child: photo == null
                  ? const Icon(Icons.person_outline,
                  color: AppColors.primary, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nomParticipant,
                    style: AppTextStyles.titleMd.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.annonceTitre,
                    style: AppTextStyles.bodySm.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.annonceImageUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.network(
                  widget.annonceImageUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary),
                  );
                }

                final messages =
                List<Map<String, dynamic>>.from(snapshot.data!)
                  ..sort((a, b) =>
                      DateTime.parse(a['date_envoi'])
                          .compareTo(DateTime.parse(b['date_envoi'])));

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Envoyez le premier message',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.rosyTaupe,
                      ),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildBubble(messages[index]);
                  },
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.softBlush,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: AppColors.navy),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      boxShadow: AppShadows.card,
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: AppTextStyles.bodyMd,
                      decoration: InputDecoration(
                        hintText: 'Écrivez votre message...',
                        hintStyle: AppTextStyles.bodyMd.copyWith(
                          color: AppColors.rosyTaupe,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(AppRadius.full),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _envoyer(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _envoyer,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isMe = msg['sender_id'] == _userId;
    final type = msg['type'] as String? ?? 'texte';

    if (type == 'negociation' && !isMe) {
      return _buildBulleNegociation(msg);
    }

    if (type == 'transaction') {
      return _buildBulleTransaction(msg, isMe);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
        isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72),
            decoration: BoxDecoration(
              color: isMe ? AppColors.navy : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: isMe ? null : AppShadows.card,
            ),
            child: Text(
              msg['contenu'],
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                color: isMe ? Colors.white : AppColors.onSurface,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 10, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatHeureMessage(msg['date_envoi']),
                  style: AppTextStyles.bodySm.copyWith(fontSize: 11),
                ),
                if (isMe) ...[
                  const SizedBox(width: 3),
                  Icon(
                    msg['lu'] == true ? Icons.done_all : Icons.done,
                    size: 14,
                    color: msg['lu'] == true
                        ? AppColors.primary
                        : AppColors.rosyTaupe,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatHeureMessage(String? dateIso) {
    if (dateIso == null) return '';
    final date = DateTime.parse(dateIso);
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildBulleTransaction(Map<String, dynamic> msg, bool isMe) {
    final transactionId = msg['transaction_id'] as int?;
    final statut = transactionId != null
        ? _transactionsStatuts[transactionId]
        : null;
    final estCompletee = statut == 'completee';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: estCompletee
                ? Colors.green.shade300
                : const Color(0xFF1E90FF).withOpacity(0.5),
            width: 1.5,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: estCompletee
                    ? Colors.green.shade50
                    : const Color(0xFF1E90FF).withOpacity(0.08),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg)),
              ),
              child: Row(
                children: [
                  Icon(
                    estCompletee
                        ? Icons.check_circle_outline
                        : Icons.shopping_bag_outlined,
                    size: 16,
                    color: estCompletee
                        ? Colors.green.shade600
                        : const Color(0xFF1E90FF),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    estCompletee
                        ? 'Transaction terminée'
                        : 'Commande en cours',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: estCompletee
                          ? Colors.green.shade600
                          : const Color(0xFF1E90FF),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Text(
                msg['contenu'],
                style: AppTextStyles.bodyMd.copyWith(fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.paleOak, height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: estCompletee
                  ? Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    'Terminée',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              )
                  : GestureDetector(
                onTap: transactionId == null
                    ? null
                    : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SuiviTransactionScreen(
                      transactionId: transactionId,
                      annonceId: 0,
                      estLiquide: statut == 'en_livraison' &&
                          msg['contenu']
                              .contains('espèces'),
                    ),
                  ),
                ).then((_) => _chargerStatutsTransactions()),
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Center(
                    child: Text(
                      'Voir le suivi',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulleNegociation(Map<String, dynamic> msg) {
    final negociationId = msg['negociation_id'] as int?;
    final dejaTraite = negociationId != null &&
        _negociationsTraitees.containsKey(negociationId);
    final resultat = negociationId != null
        ? _negociationsTraitees[negociationId]
        : null;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color:
            dejaTraite ? AppColors.paleOak : AppColors.primary,
            width: 1.5,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: dejaTraite
                    ? AppColors.paleOak.withOpacity(0.3)
                    : AppColors.softBlush,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        dejaTraite
                            ? Icons.check_circle_outline
                            : Icons.handshake_outlined,
                        size: 16,
                        color: dejaTraite
                            ? AppColors.rosyTaupe
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dejaTraite
                            ? 'Négociation traitée'
                            : 'Nouvelle offre',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: dejaTraite
                              ? AppColors.rosyTaupe
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (!dejaTraite)
                    Text(
                      'EN ATTENTE',
                      style: AppTextStyles.labelCaps.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: Text(
                msg['contenu'],
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: dejaTraite
                      ? AppColors.rosyTaupe
                      : AppColors.navy,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.paleOak, height: 1),
            dejaTraite
                ? Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: resultat == 'acceptee'
                        ? const Color(0xFFE8F5E9)
                        : resultat == 'refusee'
                        ? const Color(0xFFFCE4EC)
                        : AppColors.softBlush,
                    borderRadius:
                    BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    resultat == 'acceptee'
                        ? 'Acceptée'
                        : resultat == 'refusee'
                        ? 'Refusée'
                        : 'Contre-proposition envoyée',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: resultat == 'acceptee'
                          ? Colors.green.shade700
                          : resultat == 'refusee'
                          ? Colors.red.shade700
                          : AppColors.navy,
                    ),
                  ),
                ),
              ),
            )
                : Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: negociationId == null
                        ? null
                        : () => _refuser(negociationId),
                    child: Text(
                      'Refuser',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: AppColors.paleOak),
                Expanded(
                  child: TextButton(
                    onPressed: negociationId == null
                        ? null
                        : () => _contreProposer(negociationId),
                    child: Text(
                      'Contre-\nproposer',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 24, color: AppColors.paleOak),
                Expanded(
                  child: TextButton(
                    onPressed: negociationId == null
                        ? null
                        : () => _accepter(negociationId),
                    child: Text(
                      'Accepter',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Future<void> _accepter(int negociationId) async {
    final service = NegociationService();
    try {
      final neg = await service.getNegociation(negociationId);
      if (neg == null) return;
      await service.accepterNegociation(
        negociationId: negociationId,
        annonceId: neg['annonce_id'] as int,
        prixAccepte: (neg['prix_propose'] as num).toDouble(),
        userId: _userId!,
        conversationId: widget.conversationId,
      );
      setState(() => _negociationsTraitees[negociationId] = 'acceptee');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposition acceptée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> _refuser(int negociationId) async {
    final service = NegociationService();
    try {
      await service.refuserNegociation(
        negociationId: negociationId,
        userId: _userId!,
        conversationId: widget.conversationId,
      );
      setState(() => _negociationsTraitees[negociationId] = 'refusee');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposition refusée')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  Future<void> _contreProposer(int negociationId) async {
    final neg =
    await NegociationService().getNegociation(negociationId);
    if (neg == null || !mounted) return;

    await NegociationService().refuserNegociation(
      negociationId: negociationId,
      userId: _userId!,
      conversationId: widget.conversationId,
      silencieux: true,
    );

    setState(
            () => _negociationsTraitees[negociationId] = 'refusee');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NegociationBottomSheet(
        annonceId: neg['annonce_id'] as int,
        vendeurId: neg['acheteur_id'] as String,
        prixActuel: (neg['prix_propose'] as num).toDouble(),
        titrAnnonce: neg['annonces']['titre'] as String,
      ),
    );
  }
}