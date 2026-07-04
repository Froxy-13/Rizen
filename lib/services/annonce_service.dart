import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/annonce.dart';
import 'dart:io';

class AnnonceService {
  final _client = Supabase.instance.client;

  /// Récupère les annonces actives avec leurs images (triées par date)
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

  /// Récupère les 7 catégories
  Future<List<Map<String, dynamic>>> getCategories() async {
    final data = await _client
        .from('categories')
        .select('id, nom')
        .order('id');
    return List<Map<String, dynamic>>.from(data);
  }

  /// Toggle favori (ajoute ou retire)
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

  /// Récupère les IDs des favoris de l'utilisateur
  Future<Set<int>> getFavorisIds(String userId) async {
    final data = await _client
        .from('favoris')
        .select('annonce_id')
        .eq('utilisateur_id', userId);
    return (data as List).map((e) => e['annonce_id'] as int).toSet();
  }

  /// Récupère une annonce par son ID avec images + profil vendeur
  Future<Map<String, dynamic>> getAnnonceById(int id) async {
    final data = await _client
        .from('annonces')
        .select('*, images_annonce(url_image, ordre), profils(nom, prenom, photo, telephone)')
        .eq('id', id)
        .single();
    return data;
  }

  /// Signaler une annonce
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
  /// Crée une annonce avec ses images
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
    // 1. Créer l'annonce
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

    // 2. Ajouter les images
    for (int i = 0; i < urlsImages.length; i++) {
      await _client.from('images_annonce').insert({
        'annonce_id': annonceId,
        'url_image': urlsImages[i],
        'ordre': i,
      });
    }

    return annonceId;
  }

  /// Upload une image dans Supabase Storage et retourne son URL publique
  Future<String> uploadImage(String filePath) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';
    final bytes = await File(filePath).readAsBytes();

    await _client.storage.from('annonces-images').uploadBinary(
      fileName,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );

    return _client.storage.from('annonces-images').getPublicUrl(fileName);
  }
}