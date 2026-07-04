import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/message_service.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _service = MessageService();
  List<Map<String, dynamic>> _conversations = [];
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
      final data = await _service.getConversations(userId);
      setState(() {
        _conversations = data;
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Text(
                    'Messages',
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
              _loading
                  ? const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.dustyRose),
                ),
              )
                  : _conversations.isEmpty
                  ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 56, color: AppColors.paleOak),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune conversation',
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
                        _buildItem(_conversations[index]),
                    childCount: _conversations.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> convData) {
    final conv = convData['conversations'] as Map<String, dynamic>?;
    if (conv == null) return const SizedBox.shrink();

    final annonce = conv['annonces'] as Map<String, dynamic>?;
    final messages = (conv['messages'] as List<dynamic>? ?? []);

    String dernierMessage = 'Démarrer la conversation';
    if (messages.isNotEmpty) {
      final sorted = List<Map<String, dynamic>>.from(messages)
        ..sort((a, b) =>
            DateTime.parse(b['date_envoi']).compareTo(DateTime.parse(a['date_envoi'])));
      dernierMessage = sorted.first['contenu'] ?? '';
    }

    final images = (annonce?['images_annonce'] as List<dynamic>? ?? []);
    final imageUrl = images.isNotEmpty ? images.first['url_image'] as String : null;
    final titre = annonce?['titre'] ?? 'Annonce supprimée';
    final convId = conv['id'] as int;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: convId,
              annonceTitre: titre,
            ),
          ),
        );
        _charger();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.paleOak),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null
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
                child: Icon(Icons.image_outlined,
                    color: AppColors.paleOak, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titre,
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dernierMessage,
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 13,
                      color: AppColors.rosyTaupe,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.paleOak),
          ],
        ),
      ),
    );
  }
}