import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class AvisDialog extends StatefulWidget {
  final String acheteurId;
  final String vendeurId;
  final String destinataireNom;
  final int transactionId;
  final String emetteur; // 'acheteur' ou 'vendeur'

  const AvisDialog({
    super.key,
    required this.acheteurId,
    required this.vendeurId,
    required this.destinataireNom,
    required this.transactionId,
    required this.emetteur,
  });

  @override
  State<AvisDialog> createState() => _AvisDialogState();
}

class _AvisDialogState extends State<AvisDialog> {
  final _client = Supabase.instance.client;
  final _commentaireController = TextEditingController();
  int _noteSelectionnee = 0;
  bool _loading = false;

  Future<void> _soumettre() async {
    if (_noteSelectionnee == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une note')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _client.from('avis').insert({
        'acheteur_id': widget.acheteurId,
        'vendeur_id': widget.vendeurId,
        'transaction_id': widget.transactionId,
        'note': _noteSelectionnee,
        'commentaire': _commentaireController.text.isEmpty
            ? null
            : _commentaireController.text.trim(),
        'emetteur': widget.emetteur,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avis envoyé, merci !')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.softBlush,
                shape: BoxShape.circle,
              ),
              child:
              Icon(Icons.star, color: AppColors.dustyRose, size: 28),
            ),
            const SizedBox(height: 16),

            // Titre
            Text(
              widget.emetteur == 'acheteur'
                  ? 'Noter le vendeur'
                  : "Noter l'acheteur",
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.destinataireNom,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                color: AppColors.rosyTaupe,
              ),
            ),
            const SizedBox(height: 20),

            // Étoiles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final note = index + 1;
                return GestureDetector(
                  onTap: () =>
                      setState(() => _noteSelectionnee = note),
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      _noteSelectionnee >= note
                          ? Icons.star
                          : Icons.star_border,
                      color: _noteSelectionnee >= note
                          ? const Color(0xFFFFB800)
                          : AppColors.paleOak,
                      size: 36,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Text(
              _noteSelectionnee == 0
                  ? 'Touchez une étoile pour noter'
                  : _noteSelectionnee == 1
                  ? 'Très mauvais'
                  : _noteSelectionnee == 2
                  ? 'Mauvais'
                  : _noteSelectionnee == 3
                  ? 'Correct'
                  : _noteSelectionnee == 4
                  ? 'Bien'
                  : 'Excellent',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                color: _noteSelectionnee == 0
                    ? AppColors.rosyTaupe
                    : const Color(0xFFFFB800),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Commentaire
            TextField(
              controller: _commentaireController,
              maxLines: 3,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: AppColors.onSurface,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Laissez un commentaire (optionnel)...',
                hintStyle: TextStyle(
                    color: AppColors.rosyTaupe, fontSize: 13),
                filled: true,
                fillColor: AppColors.softBlush,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Plus tard',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        color: AppColors.rosyTaupe,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _soumettre,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.mauveShadow,
                      padding:
                      const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loading
                        ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                        : const Text(
                      'Envoyer',
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}