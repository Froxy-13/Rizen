import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionService {
  final _client = Supabase.instance.client;

  /// Envoie un message automatique dans le chat après paiement
  Future<void> _envoyerMessageTransaction({
    required int annonceId,
    required String acheteurId,
    required String vendeurId,
    required int transactionId,
    required bool estLiquide,
    required double montant,
  }) async {
    // Récupère ou crée la conversation
    final convResult = await _client.rpc('creer_conversation', params: {
      'p_annonce_id': annonceId,
      'p_vendeur_id': vendeurId,
    });
    final conversationId = convResult as int;

    final contenu = estLiquide
        ? 'Commande confirmée - ${montant.toStringAsFixed(0)} FCFA en espèces. Veuillez confirmer la réception du paiement.'
        : 'Paiement de ${montant.toStringAsFixed(0)} FCFA sécurisé. Veuillez confirmer l\'envoi de l\'article.';

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': acheteurId,
      'contenu': contenu,
      'type': 'transaction',
      'transaction_id': transactionId,
    });
  }

  /// Simule un paiement mobile et crée la transaction en séquestre
  Future<int> simulerPaiementMobile({
    required int annonceId,
    required String acheteurId,
    required String vendeurId,
    required double montant,
    required String methode,
  }) async {
    // 1. Créer la transaction en séquestre
    final transaction = await _client
        .from('transactions')
        .insert({
      'annonce_id': annonceId,
      'acheteur_id': acheteurId,
      'vendeur_id': vendeurId,
      'prix_final': montant,
      'statut': 'en_sequestre',
    })
        .select('id')
        .single();

    final transactionId = transaction['id'] as int;

    // 2. Créer le paiement
    await _client.from('paiements').insert({
      'transaction_id': transactionId,
      'montant': montant,
      'methode': methode,
      'reference': 'SIM-${DateTime.now().millisecondsSinceEpoch}',
      'statut': 'confirme',
    });

    // 3. Suspendre l'annonce
    await _client
        .from('annonces')
        .update({'statut': 'suspendue'})
        .eq('id', annonceId);

    // 4. Envoyer message dans le chat
    await _envoyerMessageTransaction(
      annonceId: annonceId,
      acheteurId: acheteurId,
      vendeurId: vendeurId,
      transactionId: transactionId,
      estLiquide: false,
      montant: montant,
    );

    // 5. Simuler délai paiement
    await Future.delayed(const Duration(seconds: 3));

    return transactionId;
  }

  /// Crée une transaction en liquide (pas de séquestre)
  Future<int> creerTransactionLiquide({
    required int annonceId,
    required String acheteurId,
    required String vendeurId,
    required double montant,
  }) async {
    // 1. Créer la transaction directement en livraison
    final transaction = await _client
        .from('transactions')
        .insert({
      'annonce_id': annonceId,
      'acheteur_id': acheteurId,
      'vendeur_id': vendeurId,
      'prix_final': montant,
      'statut': 'en_livraison',
    })
        .select('id')
        .single();

    final transactionId = transaction['id'] as int;

    // 2. Créer le paiement
    await _client.from('paiements').insert({
      'transaction_id': transactionId,
      'montant': montant,
      'methode': 'liquide',
      'reference': 'LIQ-${DateTime.now().millisecondsSinceEpoch}',
      'statut': 'en_attente',
    });

    // 3. Suspendre l'annonce
    await _client
        .from('annonces')
        .update({'statut': 'suspendue'})
        .eq('id', annonceId);

    // 4. Envoyer message dans le chat
    await _envoyerMessageTransaction(
      annonceId: annonceId,
      acheteurId: acheteurId,
      vendeurId: vendeurId,
      transactionId: transactionId,
      estLiquide: true,
      montant: montant,
    );

    return transactionId;
  }

  /// Vendeur confirme l'envoi (paiement mobile)
  Future<void> confirmerEnvoi(int transactionId) async {
    await _client
        .from('transactions')
        .update({'statut': 'en_livraison'})
        .eq('id', transactionId);
  }

  /// Acheteur confirme la réception (paiement mobile)
  /// ou vendeur confirme réception du liquide
  Future<void> confirmerReception(int transactionId, int annonceId) async {
    await _client
        .from('transactions')
        .update({'statut': 'completee'})
        .eq('id', transactionId);

    await _client
        .from('paiements')
        .update({'statut': 'libere'})
        .eq('transaction_id', transactionId);

    await _client
        .from('annonces')
        .update({'statut': 'vendue'})
        .eq('id', annonceId);
  }

  /// Ouvrir un litige — le motif est maintenant obligatoire pour que
  /// l'admin ait un vrai contexte à traiter, pas juste un statut vide.
  Future<void> ouvrirLitige(int transactionId, String motif) async {
    await _client.from('transactions').update({
      'statut': 'litige',
      'motif_litige': motif,
    }).eq('id', transactionId);
  }

  /// Récupère une transaction par son ID
  Future<Map<String, dynamic>?> getTransaction(int transactionId) async {
    final data = await _client
        .from('transactions')
        .select('*, annonces(titre, images_annonce(url_image, ordre)), paiements(methode, statut, reference)')
        .eq('id', transactionId)
        .maybeSingle();
    return data;
  }

  /// Récupère les transactions de l'utilisateur (acheteur ou vendeur)
  Future<List<Map<String, dynamic>>> getMesTransactions(String userId) async {
    final data = await _client
        .from('transactions')
        .select('*, annonces(titre, images_annonce(url_image, ordre)), paiements(methode, statut)')
        .or('acheteur_id.eq.$userId,vendeur_id.eq.$userId')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }
}