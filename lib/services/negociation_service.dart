import 'package:supabase_flutter/supabase_flutter.dart';

class NegociationService {
  final _client = Supabase.instance.client;

  Future<void> proposerNegociation({
    required int annonceId,
    required String acheteurId,
    required String vendeurId,
    required double prixPropose,
    String? message,
  }) async {
    final convResult = await _client.rpc('creer_conversation', params: {
      'p_annonce_id': annonceId,
      'p_vendeur_id': vendeurId,
    });
    final conversationId = convResult as int;

    final negResult = await _client
        .from('negociations')
        .insert({
      'annonce_id': annonceId,
      'acheteur_id': acheteurId,
      'vendeur_id': vendeurId,
      'prix_propose': prixPropose,
      'conversation_id': conversationId,
      'message': message,
      'statut': 'en_attente',
    })
        .select('id')
        .single();

    final negociationId = negResult['id'] as int;

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': acheteurId,
      'contenu': 'Proposition de prix : ${prixPropose.toStringAsFixed(0)} FCFA',
      'type': 'negociation',
      'negociation_id': negociationId,
    });
  }

  Future<void> accepterNegociation({
    required int negociationId,
    required int annonceId,
    required double prixAccepte,
    required String userId,
    required int conversationId,
  }) async {
    await _client
        .from('negociations')
        .update({'statut': 'acceptee'})
        .eq('id', negociationId);

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': userId,
      'contenu': 'Proposition acceptée - Prix convenu : ${prixAccepte.toStringAsFixed(0)} FCFA',
      'type': 'texte',
    });
  }

  Future<void> refuserNegociation({
    required int negociationId,
    required String userId,
    required int conversationId,
    bool silencieux = false,
  }) async {
    await _client
        .from('negociations')
        .update({'statut': 'refusee'})
        .eq('id', negociationId);

    if (!silencieux) {
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': userId,
        'contenu': 'Proposition refusée',
        'type': 'texte',
      });
    }
  }

  Future<Map<String, dynamic>?> getNegociation(int negociationId) async {
    final data = await _client
        .from('negociations')
        .select('*, annonces(titre, prix_actuel)')
        .eq('id', negociationId)
        .maybeSingle();
    return data;
  }

  Future<Map<int, String>> getStatutsNegociations(int conversationId) async {
    final data = await _client
        .from('negociations')
        .select('id, statut')
        .eq('conversation_id', conversationId)
        .neq('statut', 'en_attente');

    final Map<int, String> statuts = {};
    for (final n in data) {
      statuts[n['id'] as int] = n['statut'] as String;
    }
    return statuts;
  }
}