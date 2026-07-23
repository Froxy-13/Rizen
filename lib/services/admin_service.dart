import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final _client = Supabase.instance.client;

  /// Statistiques globales
  Future<Map<String, int>> getStatistiques() async {
    final annonces = await _client
        .from('annonces')
        .select('id')
        .count();

    final utilisateurs = await _client
        .from('profils')
        .select('id')
        .count();

    final transactions = await _client
        .from('transactions')
        .select('id')
        .count();

    final signalements = await _client
        .from('signalements')
        .select('id')
        .count();

    final litiges = await _client
        .from('transactions')
        .select('id')
        .eq('statut', 'litige')
        .count();

    return {
      'annonces': annonces.count,
      'utilisateurs': utilisateurs.count,
      'transactions': transactions.count,
      'signalements': signalements.count,
      'litiges': litiges.count,
    };
  }

  /// Liste tous les signalements
  Future<List<Map<String, dynamic>>> getSignalements() async {
    final data = await _client
        .from('signalements')
        .select('*, annonces(titre, statut), profils!utilisateur_id(nom, prenom)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Valider un signalement (masquer l'annonce)
  Future<void> validerSignalement(int signalementId, int annonceId) async {
    await _client
        .from('annonces')
        .update({'statut': 'suspendue'})
        .eq('id', annonceId);

    await _client
        .from('signalements')
        .update({'statut': 'traite'})
        .eq('id', signalementId);
  }

  /// Rejeter un signalement
  Future<void> rejeterSignalement(int signalementId) async {
    await _client
        .from('signalements')
        .update({'statut': 'rejete'})
        .eq('id', signalementId);
  }

  /// Liste toutes les annonces
  Future<List<Map<String, dynamic>>> getAnnonces({String? statut}) async {
    List<dynamic> data;

    if (statut != null) {
      data = await _client
          .from('annonces')
          .select('*, profils(nom, prenom), images_annonce(url_image, ordre)')
          .eq('statut', statut)
          .order('date_publication', ascending: false);
    } else {
      data = await _client
          .from('annonces')
          .select('*, profils(nom, prenom), images_annonce(url_image, ordre)')
          .order('date_publication', ascending: false);
    }

    return List<Map<String, dynamic>>.from(data);
  }

  /// Masquer une annonce
  Future<void> masquerAnnonce(int annonceId) async {
    await _client
        .from('annonces')
        .update({'statut': 'suspendue'})
        .eq('id', annonceId);
  }

  /// Supprimer une annonce
  Future<void> supprimerAnnonce(int annonceId) async {
    await _client
        .from('annonces')
        .delete()
        .eq('id', annonceId);
  }

  /// Liste tous les utilisateurs
  Future<List<Map<String, dynamic>>> getUtilisateurs() async {
    final data = await _client
        .from('profils')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Supprimer un utilisateur
  Future<void> supprimerUtilisateur(String userId) async {
    await _client
        .from('profils')
        .delete()
        .eq('id', userId);
  }

  /// Suspendre un utilisateur
  Future<void> suspendreUtilisateur(String userId) async {
    await _client
        .from('profils')
        .update({'statut': 'suspendu'})
        .eq('id', userId);
  }

  /// Réactiver un utilisateur
  Future<void> reactiverUtilisateur(String userId) async {
    await _client
        .from('profils')
        .update({'statut': 'actif'})
        .eq('id', userId);
  }

  /// Transactions en litige
  Future<List<Map<String, dynamic>>> getLitiges() async {
    final data = await _client
        .from('transactions')
        .select('*, annonces(titre), profils!acheteur_id(nom, prenom)')
        .eq('statut', 'litige')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Résoudre un litige
  Future<void> resoldreLitige(int transactionId, int annonceId, bool favorVendeur) async {
    if (favorVendeur) {
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
    } else {
      await _client
          .from('transactions')
          .update({'statut': 'remboursee'})
          .eq('id', transactionId);
      await _client
          .from('paiements')
          .update({'statut': 'rembourse'})
          .eq('transaction_id', transactionId);
      await _client
          .from('annonces')
          .update({'statut': 'active'})
          .eq('id', annonceId);
    }
  }
}