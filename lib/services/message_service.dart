import 'package:supabase_flutter/supabase_flutter.dart';

class MessageService {
  final _client = Supabase.instance.client;

  /// Récupère ou crée une conversation entre l'utilisateur courant et le vendeur, pour une annonce donnée
  Future<int> getOrCreateConversation({
    required int annonceId,
    required String userId,
    required String vendeurId,
  }) async {
    final result = await _client.rpc('creer_conversation', params: {
      'p_annonce_id': annonceId,
      'p_vendeur_id': vendeurId,
    });
    return result as int;
  }

  /// Liste des conversations de l'utilisateur avec dernier message + infos annonce
  Future<List<Map<String, dynamic>>> getConversations(String userId) async {
    final data = await _client
        .from('conversation_participants')
        .select('''
          conversation_id,
          conversations(
            id,
            annonces(id, titre, prix_actuel, images_annonce(url_image, ordre)),
            messages(contenu, date_envoi, sender_id)
          )
        ''')
        .eq('utilisateur_id', userId);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Récupère le ou les autres participants d'une conversation (hors utilisateur courant)
  Future<Map<String, dynamic>?> getAutreParticipant(
      int conversationId, String userId) async {
    final data = await _client
        .from('conversation_participants')
        .select('utilisateur_id, profils(nom, prenom, photo)')
        .eq('conversation_id', conversationId)
        .neq('utilisateur_id', userId)
        .maybeSingle();
    return data;
  }

  /// Messages d'une conversation, triés par date
  Future<List<Map<String, dynamic>>> getMessages(int conversationId) async {
    final data = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('date_envoi', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Envoyer un message
  Future<void> envoyerMessage({
    required int conversationId,
    required String expediteurId,
    required String contenu,
  }) async {
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': expediteurId,
      'contenu': contenu,
    });
  }

  /// Stream temps réel des messages d'une conversation
  Stream<List<Map<String, dynamic>>> streamMessages(int conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('date_envoi');
  }
}