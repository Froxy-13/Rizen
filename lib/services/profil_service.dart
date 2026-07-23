import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilService {
  final _client = Supabase.instance.client;

  Future<Map<String, dynamic>?> getMonProfil() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('profils')
        .select()
        .eq('id', userId)
        .maybeSingle();
    return data;
  }

  Future<List<Map<String, dynamic>>> getMesAnnonces() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final data = await _client
        .from('annonces')
        .select('*, images_annonce(url_image, ordre)')
        .eq('utilisateur_id', userId)
        .order('date_publication', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<double?> getNotemoyenne() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('avis')
        .select('note')
        .eq('vendeur_id', userId);

    if ((data as List).isEmpty) return null;
    final total = data.fold<double>(
        0, (sum, a) => sum + (a['note'] as num).toDouble());
    return total / data.length;
  }

  Future<String> uploadPhotoProfil(String filePath) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Non connecté');

    final bytes = await File(filePath).readAsBytes();
    final fileName = 'profil_$userId.jpg';

    await _client.storage.from('profils-photos').uploadBinary(
      fileName,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );

    final url = _client.storage
        .from('profils-photos')
        .getPublicUrl(fileName);

    await _client
        .from('profils')
        .update({'photo': url})
        .eq('id', userId);

    return url;
  }

  Future<void> mettreAJourProfil({
    required String nom,
    required String prenom,
    String? telephone,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from('profils').update({
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
    }).eq('id', userId);
  }

  Future<void> deconnecter() async {
    await _client.auth.signOut();
  }
}