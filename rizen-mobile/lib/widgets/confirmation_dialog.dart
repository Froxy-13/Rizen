import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Affiche un dialogue de confirmation cohérent avec le design system,
/// avec deux boutons de même largeur bien alignés (au lieu du layout
/// par défaut d'AlertDialog qui tasse les actions à droite).
///
/// Retourne `true` si confirmé, `false`/`null` sinon.
///
/// Exemple :
/// ```dart
/// final ok = await confirmerAction(
///   context,
///   titre: 'Déconnexion',
///   message: 'Voulez-vous vraiment vous déconnecter ?',
///   labelConfirmer: 'Déconnecter',
///   destructif: true,
/// );
/// if (ok == true) { ... }
/// ```
Future<bool?> confirmerAction(
    BuildContext context, {
      required String titre,
      required String message,
      String labelConfirmer = 'Confirmer',
      String labelAnnuler = 'Annuler',
      bool destructif = false,
      Color? couleurConfirmer,
    }) {
  final couleur =
      couleurConfirmer ?? (destructif ? AppColors.error : AppColors.primary);

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Text(titre),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: AppColors.rosyTaupe,
                  side: const BorderSide(color: AppColors.paleOak),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(labelAnnuler, maxLines: 1),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  backgroundColor: couleur,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(labelConfirmer, maxLines: 1),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}