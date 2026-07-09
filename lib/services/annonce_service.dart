import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/annonce.dart';

class AnnonceService {
  final _client = Supabase.instance.client;

  Future<List<Annonce>> getAnnonces({int? categorieId}) async {
    List<dynamic> data;

    if (categorieId != null) {
      data = await _client
          .from('annonces')
          .select('*, images_annonce(url_image, ordre)')
          .eq('statut', 'active')
          .eq('categorie_id', categorieId)
          .order('date_publication', ascending: false);
    } else {
      data = await _client
          .from('annonces')
          .select('*, images_annonce(url_image, ordre)')
          .eq('statut', 'active')
          .order('date_publication', ascending: false);
    }

    return data.map((e) => Annonce.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final data = await _client
        .from('categories')
        .select('id, nom')
        .order('id');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> toggleFavori(int annonceId, String userId, bool estFavori) async {
    if (estFavori) {
      await _client.from('favoris').delete().match({
        'utilisateur_id': userId,
        'annonce_id': annonceId,
      });
    } else {
      await _client.from('favoris').insert({
        'utilisateur_id': userId,
        'annonce_id': annonceId,
      });
    }
  }

  Future<Set<int>> getFavorisIds(String userId) async {
    final data = await _client
        .from('favoris')
        .select('annonce_id')
        .eq('utilisateur_id', userId);
    return (data as List).map((e) => e['annonce_id'] as int).toSet();
  }

  Future<Map<String, dynamic>> getAnnonceById(int id) async {
    final data = await _client
        .from('annonces')
        .select('*, images_annonce(url_image, ordre), profils(nom, prenom, photo, telephone)')
        .eq('id', id)
        .single();
    return data;
  }

  Future<void> signalerAnnonce({
    required int annonceId,
    required String userId,
    required String raison,
    String? description,
  }) async {
    await _client.from('signalements').insert({
      'annonce_id': annonceId,
      'utilisateur_id': userId,
      'raison': raison,
      'description': description,
    });
  }

  Future<int> creerAnnonce({
    required String titre,
    required String description,
    required double prix,
    required int categorieId,
    required String ville,
    required String quartier,
    required String userId,
    required List<String> urlsImages,
  }) async {
    final result = await _client.from('annonces').insert({
      'titre': titre,
      'description': description,
      'prix_initial': prix,
      'prix_actuel': prix,
      'categorie_id': categorieId,
      'ville': ville,
      'quartier': quartier,
      'utilisateur_id': userId,
    }).select('id').single();

    final annonceId = result['id'] as int;

    for (int i = 0; i < urlsImages.length; i++) {
      await _client.from('images_annonce').insert({
        'annonce_id': annonceId,
        'url_image': urlsImages[i],
        'ordre': i,
      });
    }

    return annonceId;
  }

  Future<String> uploadImage(String filePath) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
    final bytes = await File(filePath).readAsBytes();

    await _client.storage.from('annonces-images').uploadBinary(
      fileName,
      bytes,
    );

    return _client.storage.from('annonces-images').getPublicUrl(fileName);
  }

  /// Récupère les négociations acceptées de l'utilisateur connecté (acheteur)
  /// Retourne un Map<annonceId, prixNégocié>
  Future<Map<int, double>> getMesNegociationsAcceptees(String userId) async {
    final data = await _client
        .from('negociations')
        .select('annonce_id, prix_propose')
        .eq('acheteur_id', userId)
        .eq('statut', 'acceptee');

    final Map<int, double> result = {};
    for (final n in data) {
      result[n['annonce_id'] as int] = (n['prix_propose'] as num).toDouble();
    }
    return result;
  }

  /// Récupère les négociations acceptées sur les annonces du vendeur
  /// Retourne un Map<annonceId, List<prixNégocié>>
  Future<Map<int, List<double>>> getNegociationsAccepteesVendeur(String userId) async {
    final data = await _client
        .from('negociations')
        .select('annonce_id, prix_propose')
        .eq('vendeur_id', userId)
        .eq('statut', 'acceptee');

    final Map<int, List<double>> result = {};
    for (final n in data) {
      final annonceId = n['annonce_id'] as int;
      final prix = (n['prix_propose'] as num).toDouble();
      result.putIfAbsent(annonceId, () => []).add(prix);
    }
    return result;
  }
}