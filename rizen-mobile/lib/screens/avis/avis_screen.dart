import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class AvisScreen extends StatefulWidget {
  final String acheteurId;
  final String vendeurId;
  final String destinataireNom;
  final int transactionId;
  final String emetteur; // 'acheteur' ou 'vendeur'
  final String? titreAnnonce;

  const AvisScreen({
    super.key,
    required this.acheteurId,
    required this.vendeurId,
    required this.destinataireNom,
    required this.transactionId,
    required this.emetteur,
    this.titreAnnonce,
  });

  @override
  State<AvisScreen> createState() => _AvisScreenState();
}

class _AvisScreenState extends State<AvisScreen> {
  final _client = Supabase.instance.client;
  final _commentaireController = TextEditingController();
  int _noteSelectionnee = 0;
  final Set<String> _tagsSelectionnes = {};
  bool _loading = false;

  static const List<String> _tagsDisponibles = [
    'Rapide',
    'Conforme',
    'Aimable',
    'Bien emballé',
  ];

  String get _labelNote {
    switch (_noteSelectionnee) {
      case 0:
        return 'Touchez une étoile pour noter';
      case 1:
        return 'Très mauvais';
      case 2:
        return 'Mauvais';
      case 3:
        return 'Correct';
      case 4:
        return 'Bien';
      default:
        return 'Excellent';
    }
  }

  Future<void> _soumettre() async {
    if (_noteSelectionnee == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une note')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // Les tags sélectionnés sont préfixés au commentaire — pas de colonne
      // dédiée pour ça en base, donc on les intègre au texte librement.
      final commentaireLibre = _commentaireController.text.trim();
      final tagsTexte = _tagsSelectionnes.join(', ');
      String? commentaireFinal;
      if (tagsTexte.isNotEmpty && commentaireLibre.isNotEmpty) {
        commentaireFinal = '$tagsTexte — $commentaireLibre';
      } else if (tagsTexte.isNotEmpty) {
        commentaireFinal = tagsTexte;
      } else if (commentaireLibre.isNotEmpty) {
        commentaireFinal = commentaireLibre;
      }

      await _client.from('avis').insert({
        'acheteur_id': widget.acheteurId,
        'vendeur_id': widget.vendeurId,
        'transaction_id': widget.transactionId,
        'note': _noteSelectionnee,
        'commentaire': commentaireFinal,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Laisser un avis', style: AppTextStyles.headlineSm),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDestinataireCard(),
            const SizedBox(height: AppSpacing.stackLg + 8),
            _buildRatingSection(),
            const SizedBox(height: AppSpacing.stackLg + 8),
            _buildTagsSection(),
            const SizedBox(height: AppSpacing.stackLg + 8),
            _buildCommentSection(),
            const SizedBox(height: AppSpacing.stackLg + 12),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinataireCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.softBlush,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline,
                color: AppColors.primary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.destinataireNom,
                  style: AppTextStyles.titleMd.copyWith(fontSize: 17),
                ),
                if (widget.titreAnnonce != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag_outlined,
                          size: 14, color: AppColors.rosyTaupe),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.titreAnnonce!,
                          style: AppTextStyles.bodySm,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Column(
      children: [
        Center(
          child: Text('QUELLE EST VOTRE NOTE ?', style: AppTextStyles.labelCaps),
        ),
        const SizedBox(height: AppSpacing.stackMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final note = index + 1;
            return GestureDetector(
              onTap: () => setState(() => _noteSelectionnee = note),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  _noteSelectionnee >= note
                      ? Icons.star
                      : Icons.star_outline,
                  size: 40,
                  color: _noteSelectionnee >= note
                      ? const Color(0xFFFFB800)
                      : AppColors.paleOak,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          _labelNote,
          style: AppTextStyles.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: _noteSelectionnee == 0
                ? AppColors.rosyTaupe
                : const Color(0xFFFFB800),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('POINTS FORTS', style: AppTextStyles.labelCaps),
        const SizedBox(height: AppSpacing.stackSm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tagsDisponibles.map((tag) {
            final selected = _tagsSelectionnes.contains(tag);
            return GestureDetector(
              onTap: () => setState(() {
                if (selected) {
                  _tagsSelectionnes.remove(tag);
                } else {
                  _tagsSelectionnes.add(tag);
                }
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.softBlush,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.navy,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('VOTRE COMMENTAIRE', style: AppTextStyles.labelCaps),
        const SizedBox(height: AppSpacing.stackSm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: TextField(
            controller: _commentaireController,
            maxLines: 5,
            minLines: 4,
            style: AppTextStyles.bodyMd,
            decoration: InputDecoration(
              hintText: widget.emetteur == 'acheteur'
                  ? 'Partagez votre expérience avec ce vendeur...'
                  : 'Partagez votre expérience avec cet acheteur...',
              hintStyle: AppTextStyles.bodyMd.copyWith(
                color: AppColors.rosyTaupe,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _soumettre,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.full)),
          elevation: 0,
        ),
        icon: _loading
            ? const SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2),
        )
            : const Icon(Icons.send_rounded, size: 18),
        label: Text(
          _loading ? 'Envoi...' : 'Publier l\'avis',
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}