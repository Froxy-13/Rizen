import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/visitor_gate_screen.dart';

/// À appeler en tête de toute action nécessitant un compte.
/// Retourne true si l'utilisateur n'est PAS connecté (et l'a déjà redirigé
/// vers l'écran d'accès visiteur) — dans ce cas l'appelant doit stopper
/// son action avec un simple `return`.
///
/// Exemple :
/// ```dart
/// onTap: () {
///   if (exigerConnexion(context)) return;
///   // ... action protégée ...
/// }
/// ```
bool exigerConnexion(BuildContext context) {
  final connecte = Supabase.instance.client.auth.currentUser != null;
  if (!connecte) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VisitorGateScreen()),
    );
    return true;
  }
  return false;
}