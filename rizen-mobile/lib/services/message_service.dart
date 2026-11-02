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
            annonces(id, titre, prix_actuel, utilisateur_id, images_annonce(url_image, ordre)),
            messages(id, contenu, date_envoi, sender_id, lu)
          )
        ''')
        .eq('utilisateur_id', userId);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Récupère le ou les autres participants d'une conversation (hors utilisateur courant)
  Future<Map<String, dynamic>?> getAutreParticipant(
      int conversationId, String userId) async {
    // 1. Trouve l'id de l'autre participant (requête simple, sans embed)
    final participation = await _client
        .from('conversation_participants')
        .select('utilisateur_id')
        .eq('conversation_id', conversationId)
        .neq('utilisateur_id', userId)
        .maybeSingle();

    if (participation == null) return null;
    final autreId = participation['utilisateur_id'] as String;

    // 2. Récupère son profil en requête séparée
    final profil = await _client
        .from('profils')
        .select('nom, prenom, photo')
        .eq('id', autreId)
        .maybeSingle();

    return profil;
  }

  /// Version groupée de getAutreParticipant, pour éviter une requête par
  /// conversation dans une liste. Retourne Map<conversationId, profil>.
  Future<Map<int, Map<String, dynamic>>> getAutresParticipants(
      List<int> conversationIds, String userId) async {
    if (conversationIds.isEmpty) return {};

    // 1. Toutes les lignes de participation des AUTRES personnes
    final participations = await _client
        .from('conversation_participants')
        .select('conversation_id, utilisateur_id')
        .inFilter('conversation_id', conversationIds)
        .neq('utilisateur_id', userId);

    if (participations.isEmpty) return {};

    final autresIds = (participations as List)
        .map((p) => p['utilisateur_id'] as String)
        .toSet()
        .toList();

    // 2. Récupère tous les profils correspondants en une seule requête
    final profils = await _client
        .from('profils')
        .select('id, nom, prenom, photo')
        .inFilter('id', autresIds);

    final Map<String, Map<String, dynamic>> profilsParId = {
      for (final p in profils)
        p['id'] as String: Map<String, dynamic>.from(p),
    };

    // 3. Associe conversation_id -> profil
    final Map<int, Map<String, dynamic>> result = {};
    for (final p in participations) {
      final convId = p['conversation_id'] as int;
      final uid = p['utilisateur_id'] as String;
      final profil = profilsParId[uid];
      if (profil != null) {
        result[convId] = profil;
      }
    }
    return result;
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

  /// Marque comme lus tous les messages d'une conversation qui n'ont pas
  /// été envoyés par l'utilisateur courant (donc ceux qu'il vient de lire).
  Future<void> marquerConversationLue(
      int conversationId, String userId) async {
    await _client
        .from('messages')
        .update({'lu': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', userId)
        .eq('lu', false);
  }

  /// Nombre total de messages non lus reçus par l'utilisateur, toutes
  /// conversations confondues. Utilisé pour le badge de la bottom nav.
  Future<int> getNombreMessagesNonLus(String userId) async {
    final conversationsIds = await _client
        .from('conversation_participants')
        .select('conversation_id')
        .eq('utilisateur_id', userId);

    final ids = (conversationsIds as List)
        .map((c) => c['conversation_id'] as int)
        .toList();

    if (ids.isEmpty) return 0;

    final messages = await _client
        .from('messages')
        .select('id')
        .inFilter('conversation_id', ids)
        .neq('sender_id', userId)
        .eq('lu', false);

    return (messages as List).length;
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