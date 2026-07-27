import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  final _client = Supabase.instance.client;

  /// Statistiques globales (legacy — utilisée par les graphes bar/pie existants)
  Future<Map<String, int>> getStatistiques() async {
    final annonces = await _client.from('annonces').select('id').count();
    final utilisateurs = await _client.from('profils').select('id').count();
    final transactions = await _client.from('transactions').select('id').count();
    final signalements = await _client.from('signalements').select('id').count();
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

  /// Statistiques du dashboard v2 : totaux + croissance mensuelle réelle
  /// (comparaison mois en cours vs mois précédent, sur les mêmes fenêtres
  /// calendaires complètes pour les inscriptions/annonces).
  Future<Map<String, dynamic>> getStatistiquesAvancees() async {
    final now = DateTime.now();
    final debutMoisActuel = DateTime(now.year, now.month, 1);
    final debutMoisPrecedent = DateTime(now.year, now.month - 1, 1);
    final finMoisPrecedent =
    debutMoisActuel.subtract(const Duration(seconds: 1));

    final utilisateursTotal =
    await _client.from('profils').select('id').count();
    final annoncesActives = await _client
        .from('annonces')
        .select('id')
        .eq('statut', 'active')
        .count();
    final transactionsMois = await _client
        .from('transactions')
        .select('id')
        .gte('created_at', debutMoisActuel.toIso8601String())
        .count();

    final transactionsCompleteesMois = await _client
        .from('transactions')
        .select('prix_final')
        .gte('created_at', debutMoisActuel.toIso8601String())
        .eq('statut', 'completee');
    final volumeTotal = (transactionsCompleteesMois as List).fold<double>(
      0,
          (somme, t) => somme + (t['prix_final'] as num).toDouble(),
    );

    final utilisateursMoisActuel = await _client
        .from('profils')
        .select('id')
        .gte('created_at', debutMoisActuel.toIso8601String())
        .count();
    final utilisateursMoisPrecedent = await _client
        .from('profils')
        .select('id')
        .gte('created_at', debutMoisPrecedent.toIso8601String())
        .lte('created_at', finMoisPrecedent.toIso8601String())
        .count();

    final annoncesMoisActuel = await _client
        .from('annonces')
        .select('id')
        .gte('date_publication', debutMoisActuel.toIso8601String())
        .count();
    final annoncesMoisPrecedent = await _client
        .from('annonces')
        .select('id')
        .gte('date_publication', debutMoisPrecedent.toIso8601String())
        .lte('date_publication', finMoisPrecedent.toIso8601String())
        .count();

    final litiges = await _client
        .from('transactions')
        .select('id')
        .eq('statut', 'litige')
        .count();

    double? croissance(int actuel, int precedent) {
      if (precedent == 0) return null; // pas de base de comparaison fiable
      return ((actuel - precedent) / precedent) * 100;
    }

    return {
      'utilisateurs': utilisateursTotal.count,
      'annoncesActives': annoncesActives.count,
      'transactionsMois': transactionsMois.count,
      'volumeTotal': volumeTotal,
      'croissanceUtilisateurs': croissance(
          utilisateursMoisActuel.count, utilisateursMoisPrecedent.count),
      'croissanceAnnonces': croissance(
          annoncesMoisActuel.count, annoncesMoisPrecedent.count),
      'litiges': litiges.count,
    };
  }

  /// Nombre d'inscriptions par jour sur les 30 derniers jours (index 0 =
  /// il y a 29 jours, index 29 = aujourd'hui) — alimente le graphique réel.
  Future<List<int>> getInscriptions30Jours() async {
    final depuis = DateTime.now().subtract(const Duration(days: 29));
    final debutJour = DateTime(depuis.year, depuis.month, depuis.day);

    final data = await _client
        .from('profils')
        .select('created_at')
        .gte('created_at', debutJour.toIso8601String());

    final parJour = List<int>.filled(30, 0);
    for (final row in data) {
      final date = DateTime.parse(row['created_at']);
      final jour = DateTime(date.year, date.month, date.day);
      final diff = jour.difference(debutJour).inDays;
      if (diff >= 0 && diff < 30) parJour[diff]++;
    }
    return parJour;
  }

  /// Flux d'activité récente fusionné : derniers signalements, nouveaux
  /// utilisateurs, nouvelles annonces — triés par date décroissante.
  Future<List<Map<String, dynamic>>> getActiviteRecente(
      {int limite = 8}) async {
    final signalements = await _client
        .from('signalements')
        .select('id, raison, created_at, annonces(titre)')
        .order('created_at', ascending: false)
        .limit(5);
    final nouveauxUtilisateurs = await _client
        .from('profils')
        .select('id, nom, prenom, created_at')
        .order('created_at', ascending: false)
        .limit(5);
    final nouvellesAnnonces = await _client
        .from('annonces')
        .select('id, titre, ville, date_publication')
        .order('date_publication', ascending: false)
        .limit(5);

    final List<Map<String, dynamic>> items = [];

    for (final s in signalements) {
      final annonce = s['annonces'] as Map<String, dynamic>?;
      items.add({
        'type': 'signalement',
        'titre': 'Signalement',
        'sousTitre': (annonce?['titre'] ?? s['raison'] ?? '') as String,
        'date': DateTime.parse(s['created_at']),
      });
    }
    for (final u in nouveauxUtilisateurs) {
      items.add({
        'type': 'utilisateur',
        'titre': 'Nouvel utilisateur',
        'sousTitre': '${u['prenom'] ?? ''} ${u['nom'] ?? ''}'.trim(),
        'date': DateTime.parse(u['created_at']),
      });
    }
    for (final a in nouvellesAnnonces) {
      final ville = a['ville'] as String?;
      items.add({
        'type': 'annonce',
        'titre': 'Annonce publiée',
        'sousTitre': '${a['titre']}${ville != null ? ' - $ville' : ''}',
        'date': DateTime.parse(a['date_publication']),
      });
    }

    items.sort((a, b) =>
        (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    return items.take(limite).toList();
  }

  /// Catégories enrichies avec le nombre réel d'annonces actives par catégorie
  Future<List<Map<String, dynamic>>> getCategoriesAvecCompte() async {
    final categories =
    await _client.from('categories').select('id, nom').order('nom');
    final annonces = await _client
        .from('annonces')
        .select('categorie_id')
        .eq('statut', 'active');

    final Map<int, int> comptes = {};
    for (final a in annonces) {
      final id = a['categorie_id'] as int?;
      if (id != null) comptes[id] = (comptes[id] ?? 0) + 1;
    }

    return categories
        .map<Map<String, dynamic>>((c) => {
      'id': c['id'],
      'nom': c['nom'],
      'nombreAnnonces': comptes[c['id']] ?? 0,
    })
        .toList();
  }

  /// Renomme une catégorie
  Future<void> renommerCategorie(int id, String nouveauNom) async {
    await _client
        .from('categories')
        .update({'nom': nouveauNom})
        .eq('id', id);
  }

  /// Annonces d'une catégorie donnée (pour le tap-through depuis la liste)
  Future<List<Map<String, dynamic>>> getAnnoncesParCategorie(
      int categorieId) async {
    final data = await _client
        .from('annonces')
        .select('*, profils(nom, prenom), images_annonce(url_image, ordre)')
        .eq('categorie_id', categorieId)
        .order('date_publication', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Ajoute une catégorie (branché sur le champ d'ajout de CategoriesScreen)
  Future<void> ajouterCategorie(String nom) async {
    await _client.from('categories').insert({'nom': nom});
  }

  /// Liste des annonces enrichie avec le nombre de signalements de chacune
  Future<List<Map<String, dynamic>>> getAnnoncesAvecSignalements() async {
    final annonces = await getAnnonces();
    final signalements =
    await _client.from('signalements').select('annonce_id');

    final Map<int, int> comptes = {};
    for (final s in signalements) {
      final id = s['annonce_id'] as int?;
      if (id != null) comptes[id] = (comptes[id] ?? 0) + 1;
    }

    for (final a in annonces) {
      a['nombreSignalements'] = comptes[a['id']] ?? 0;
    }
    return annonces;
  }

  /// Réactive une annonce masquée
  Future<void> reactiverAnnonce(int annonceId) async {
    await _client
        .from('annonces')
        .update({'statut': 'active'})
        .eq('id', annonceId);
  }

  /// Métriques réelles pour la carte "Aperçu Modération"
  Future<Map<String, dynamic>> getApercuModeration() async {
    final signalements =
    await _client.from('signalements').select('id, statut, annonce_id');

    final enAttenteIds = signalements
        .where((s) => s['statut'] == 'en_attente')
        .map((s) => s['annonce_id'])
        .toSet();
    final total = signalements.length;
    final traites =
        signalements.where((s) => s['statut'] != 'en_attente').length;
    final tauxTraites = total == 0 ? null : (traites / total) * 100;

    final masquees = await _client
        .from('annonces')
        .select('id')
        .eq('statut', 'suspendue')
        .count();

    return {
      'enAttente': enAttenteIds.length,
      'tauxTraites': tauxTraites,
      'annoncesMasquees': masquees.count,
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
    await _client.from('annonces').delete().eq('id', annonceId);
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
    await _client.from('profils').delete().eq('id', userId);
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

  /// Litiges (ouverts ET résolus) — basé sur motif_litige plutôt que sur
  /// le statut, pour garder l'historique visible même après résolution
  /// (le statut passe à 'completee' ou 'remboursee' une fois traité).
  Future<List<Map<String, dynamic>>> getLitiges() async {
    final data = await _client
        .from('transactions')
        .select(
        '*, annonces(titre, images_annonce(url_image, ordre)), '
            'acheteur:profils!acheteur_id(nom, prenom), '
            'vendeur:profils!vendeur_id(nom, prenom)')
        .not('motif_litige', 'is', null)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  /// Résoudre un litige
  Future<void> resoldreLitige(
      int transactionId, int annonceId, bool favorVendeur) async {
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