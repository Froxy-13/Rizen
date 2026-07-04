import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/negociation_service.dart';
import '../../theme/app_theme.dart';

class NegociationBottomSheet extends StatefulWidget {
  final int annonceId;
  final String vendeurId;
  final double prixActuel;
  final String titrAnnonce;

  const NegociationBottomSheet({
    super.key,
    required this.annonceId,
    required this.vendeurId,
    required this.prixActuel,
    required this.titrAnnonce,
  });

  @override
  State<NegociationBottomSheet> createState() => _NegociationBottomSheetState();
}

class _NegociationBottomSheetState extends State<NegociationBottomSheet> {
  final _service = NegociationService();
  final _prixController = TextEditingController();
  final _messageController = TextEditingController();
  double? _prixSelectionne;
  bool _loading = false;

  double get _prix5 => widget.prixActuel * 0.95;
  double get _prix15 => widget.prixActuel * 0.85;
  double get _prix25 => widget.prixActuel * 0.75;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.paleOak,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Titre
            Text(
              'Proposer un prix',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Prix actuel : ${widget.prixActuel.toStringAsFixed(0)} FCFA',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                color: AppColors.rosyTaupe,
              ),
            ),
            const SizedBox(height: 20),

            // Boutons rapides
            Text(
              'Réductions rapides',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildChipPrix('-5%', _prix5),
                const SizedBox(width: 8),
                _buildChipPrix('-15%', _prix15),
                const SizedBox(width: 8),
                _buildChipPrix('-25%', _prix25),
              ],
            ),
            const SizedBox(height: 20),

            // Champ prix personnalisé
            Text(
              'Ou proposez votre prix',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _prixController,
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null) {
                  setState(() => _prixSelectionne = parsed);
                }
              },
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: AppColors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Ex: 12000',
                hintStyle: TextStyle(color: AppColors.rosyTaupe),
                suffixText: 'FCFA',
                filled: true,
                fillColor: AppColors.softBlush,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Message optionnel
            TextField(
              controller: _messageController,
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                color: AppColors.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Message optionnel...',
                hintStyle: TextStyle(color: AppColors.rosyTaupe),
                filled: true,
                fillColor: AppColors.softBlush,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),

            // Bouton envoyer
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading || _prixSelectionne == null
                    ? null
                    : _envoyer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mauveShadow,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: AppColors.paleOak,
                ),
                child: _loading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : Text(
                  _prixSelectionne != null
                      ? 'Proposer ${_prixSelectionne!.toStringAsFixed(0)} FCFA'
                      : 'Choisissez un prix',
                  style: const TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipPrix(String label, double prix) {
    final selected = _prixSelectionne == prix;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _prixSelectionne = prix;
            _prixController.clear();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.mauveShadow : AppColors.softBlush,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.mauveShadow,
                ),
              ),
              Text(
                '${prix.toStringAsFixed(0)} F',
                style: TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 11,
                  color: selected
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.rosyTaupe,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _envoyer() async {
    if (_prixSelectionne == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _loading = true);
    try {
      await _service.proposerNegociation(
        annonceId: widget.annonceId,
        acheteurId: userId,
        vendeurId: widget.vendeurId,
        prixPropose: _prixSelectionne!,
        message: _messageController.text.isEmpty
            ? null
            : _messageController.text,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Proposition envoyée !')),
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
}