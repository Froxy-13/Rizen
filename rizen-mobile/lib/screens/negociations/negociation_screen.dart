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

  double? get _economie {
    if (_prixSelectionne == null) return null;
    final diff = widget.prixActuel - _prixSelectionne!;
    return diff > 0 ? diff : null;
  }

  double? get _pourcentageEconomie {
    final e = _economie;
    if (e == null) return null;
    return (e / widget.prixActuel) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),

            Text('Proposer un prix', style: AppTextStyles.headlineSm),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.sell_outlined,
                    size: 14, color: AppColors.rosyTaupe),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.titrAnnonce,
                    style: AppTextStyles.bodySm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Prix actuel : ${widget.prixActuel.toStringAsFixed(0)} FCFA',
              style: AppTextStyles.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            Text('RÉDUCTIONS RAPIDES', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.stackSm),
            Row(
              children: [
                _buildChipPrix('-5%', _prix5),
                const SizedBox(width: 8),
                _buildChipPrix('-15%', _prix15),
                const SizedBox(width: 8),
                _buildChipPrix('-25%', _prix25),
              ],
            ),
            const SizedBox(height: AppSpacing.stackLg),

            Text('OU PROPOSEZ VOTRE PRIX', style: AppTextStyles.labelCaps),
            const SizedBox(height: AppSpacing.stackSm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: TextField(
                controller: _prixController,
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final parsed = double.tryParse(v);
                  setState(() => _prixSelectionne = parsed);
                },
                style: AppTextStyles.bodyMd,
                decoration: InputDecoration(
                  hintText: 'Ex: 12000',
                  hintStyle: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.rosyTaupe,
                  ),
                  suffixText: 'FCFA',
                  suffixStyle: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // Indicateur d'économie en temps réel
            if (_economie != null) ...[
              const SizedBox(height: AppSpacing.stackSm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.emerald.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.savings_outlined,
                        size: 15, color: AppColors.emerald),
                    const SizedBox(width: 6),
                    Text(
                      'Vous économisez ${_economie!.toStringAsFixed(0)} FCFA '
                          '(${_pourcentageEconomie!.toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.stackMd),

            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: AppShadows.card,
              ),
              child: TextField(
                controller: _messageController,
                style: AppTextStyles.bodyMd,
                decoration: InputDecoration(
                  hintText: 'Message optionnel...',
                  hintStyle: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.rosyTaupe,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.stackLg),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _loading || _prixSelectionne == null
                    ? null
                    : _envoyer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full)),
                  disabledBackgroundColor: AppColors.paleOak,
                  elevation: 0,
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
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.softBlush,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.navy,
                ),
              ),
              Text(
                '${prix.toStringAsFixed(0)} F',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
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