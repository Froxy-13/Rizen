import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum TriAnnonces { recent, prixCroissant, prixDecroissant }

class FiltresResult {
  final RangeValues prix;
  final String? ville;
  final TriAnnonces tri;

  const FiltresResult({
    required this.prix,
    required this.ville,
    required this.tri,
  });

  FiltresResult reinitialise(double prixMin, double prixMax) {
    return FiltresResult(
      prix: RangeValues(prixMin, prixMax),
      ville: null,
      tri: TriAnnonces.recent,
    );
  }
}

class FiltresBottomSheet extends StatefulWidget {
  final FiltresResult filtresActuels;
  final double prixMin;
  final double prixMax;
  final List<String> villesDisponibles;

  const FiltresBottomSheet({
    super.key,
    required this.filtresActuels,
    required this.prixMin,
    required this.prixMax,
    required this.villesDisponibles,
  });

  @override
  State<FiltresBottomSheet> createState() => _FiltresBottomSheetState();
}

class _FiltresBottomSheetState extends State<FiltresBottomSheet> {
  late RangeValues _prix;
  late String? _ville;
  late TriAnnonces _tri;

  @override
  void initState() {
    super.initState();
    _prix = widget.filtresActuels.prix;
    _ville = widget.filtresActuels.ville;
    _tri = widget.filtresActuels.tri;
  }

  void _reinitialiser() {
    setState(() {
      _prix = RangeValues(widget.prixMin, widget.prixMax);
      _ville = null;
      _tri = TriAnnonces.recent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poignée
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
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filtres', style: AppTextStyles.headlineSm),
                GestureDetector(
                  onTap: _reinitialiser,
                  child: Text(
                    'Réinitialiser',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.stackLg),

            // ── Trier par ──────────────────────────────
            Text('Trier par', style: AppTextStyles.titleMd.copyWith(fontSize: 14)),
            const SizedBox(height: AppSpacing.stackSm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTriChip('Plus récent', TriAnnonces.recent),
                _buildTriChip('Prix croissant', TriAnnonces.prixCroissant),
                _buildTriChip('Prix décroissant', TriAnnonces.prixDecroissant),
              ],
            ),
            const SizedBox(height: AppSpacing.stackLg),

            // ── Prix ───────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Prix (FCFA)',
                    style: AppTextStyles.titleMd.copyWith(fontSize: 14)),
                Text(
                  '${_prix.start.toStringAsFixed(0)} - ${_prix.end.toStringAsFixed(0)}',
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.softBlush,
                thumbColor: AppColors.primary,
                overlayColor: AppColors.primary.withOpacity(0.15),
                rangeThumbShape: const RoundRangeSliderThumbShape(
                  enabledThumbRadius: 9,
                ),
              ),
              child: RangeSlider(
                values: _prix,
                min: widget.prixMin,
                max: widget.prixMax,
                divisions: 20,
                onChanged: (v) => setState(() => _prix = v),
              ),
            ),
            const SizedBox(height: AppSpacing.stackMd),

            // ── Ville ──────────────────────────────────
            if (widget.villesDisponibles.isNotEmpty) ...[
              Text('Ville', style: AppTextStyles.titleMd.copyWith(fontSize: 14)),
              const SizedBox(height: AppSpacing.stackSm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildVilleChip('Toutes', null),
                  ...widget.villesDisponibles
                      .map((v) => _buildVilleChip(v, v)),
                ],
              ),
              const SizedBox(height: AppSpacing.stackLg),
            ],

            // ── Bouton appliquer ───────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    FiltresResult(prix: _prix, ville: _ville, tri: _tri),
                  );
                },
                child: const Text('Appliquer les filtres'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTriChip(String label, TriAnnonces valeur) {
    final selected = _tri == valeur;
    return GestureDetector(
      onTap: () => setState(() => _tri = valeur),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.softBlush,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.navy,
          ),
        ),
      ),
    );
  }

  Widget _buildVilleChip(String label, String? valeur) {
    final selected = _ville == valeur;
    return GestureDetector(
      onTap: () => setState(() => _ville = valeur),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.softBlush,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.white : AppColors.navy,
          ),
        ),
      ),
    );
  }
}