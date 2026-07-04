import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/message_service.dart';
import '../../theme/app_theme.dart';
import '../../services/negociation_service.dart';
import '../negociations/negociation_screen.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String annonceTitre;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.annonceTitre,
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

  late final Stream<List<Map<String, dynamic>>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _messagesStream = _service.streamMessages(widget.conversationId);
    _chargerStatutsNegociations();
  }

  Future<void> _chargerStatutsNegociations() async {
    try {
      final statuts = await NegociationService()
          .getStatutsNegociations(widget.conversationId);
      if (mounted) setState(() => _negociationsTraitees.addAll(statuts));
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.annonceTitre,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
                        color: AppColors.dustyRose),
                  );
                }

                final messages = List<Map<String, dynamic>>.from(snapshot.data!)
                  ..sort((a, b) => DateTime.parse(a['date_envoi'])
                      .compareTo(DateTime.parse(b['date_envoi'])));

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Envoyez le premier message',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        color: AppColors.rosyTaupe,
                        fontSize: 14,
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        color: AppColors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Votre message...',
                      hintStyle: TextStyle(color: AppColors.rosyTaupe),
                      filled: true,
                      fillColor: AppColors.softBlush,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _envoyer(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _envoyer,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.dustyRose,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send,
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
    final isNegociation = msg['type'] == 'negociation';

    if (isNegociation && !isMe) {
      return _buildBulleNegociation(msg);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? AppColors.mauveShadow : AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: AppColors.paleOak),
        ),
        child: Text(
          msg['contenu'],
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 14,
            color: isMe ? Colors.white : AppColors.onSurface,
          ),
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dejaTraite ? AppColors.paleOak : AppColors.dustyRose,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF744253).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: dejaTraite ? AppColors.paleOak : AppColors.softBlush,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Icon(
                    dejaTraite
                        ? Icons.check_circle_outline
                        : Icons.handshake_outlined,
                    size: 16,
                    color: dejaTraite
                        ? AppColors.rosyTaupe
                        : AppColors.dustyRose,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dejaTraite
                        ? 'Négociation traitée'
                        : 'Proposition de négociation',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dejaTraite
                          ? AppColors.rosyTaupe
                          : AppColors.dustyRose,
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
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: dejaTraite
                      ? AppColors.rosyTaupe
                      : AppColors.mauveShadow,
                ),
              ),
            ),

            const SizedBox(height: 10),
            Divider(color: AppColors.paleOak, height: 1),

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
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    resultat == 'acceptee'
                        ? 'Acceptée'
                        : resultat == 'refusee'
                        ? 'Refusée'
                        : 'Contre-proposition envoyée',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: resultat == 'acceptee'
                          ? Colors.green.shade700
                          : resultat == 'refusee'
                          ? Colors.red.shade700
                          : AppColors.mauveShadow,
                    ),
                  ),
                ),
              ),
            )
                : Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: negociationId == null
                          ? null
                          : () => _refuser(negociationId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.softBlush,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Refuser',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.rosyTaupe,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: negociationId == null
                          ? null
                          : () => _contreProposer(negociationId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.softBlush,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Contre-proposer',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mauveShadow,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      onTap: negociationId == null
                          ? null
                          : () => _accepter(negociationId),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.mauveShadow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: const Text(
                            'Accepter',
                            style: TextStyle(
                              fontFamily: 'PlusJakartaSans',
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
    final neg = await NegociationService().getNegociation(negociationId);
    if (neg == null || !mounted) return;

    // Marque l'ancienne négociation comme refusée silencieusement
    await NegociationService().refuserNegociation(
      negociationId: negociationId,
      userId: _userId!,
      conversationId: widget.conversationId,
      silencieux: true,
    );

    setState(() => _negociationsTraitees[negociationId] = 'refusee');

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