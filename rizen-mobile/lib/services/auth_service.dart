import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Inscription
  Future<AuthResponse> inscription({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required String telephone,
    required String adresse,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'nom': nom,
        'prenom': prenom,
        'telephone': telephone,
        'adresse': adresse,
      },
    );
  }

  // Connexion
  Future<AuthResponse> connexion({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Déconnexion
  Future<void> deconnexion() async {
    await _supabase.auth.signOut();
  }

  // Utilisateur actuel
  User? get utilisateurActuel => _supabase.auth.currentUser;

  // Vérifier si connecté
  bool get estConnecte => _supabase.auth.currentUser != null;
}