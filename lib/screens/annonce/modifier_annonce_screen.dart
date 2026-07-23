import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/annonce_service.dart';
import '../../theme/app_theme.dart';

class ModifierAnnonceScreen extends StatefulWidget {
  final Map<String, dynamic> annonce;

  const ModifierAnnonceScreen({super.key, required this.annonce});

  @override
  State<ModifierAnnonceScreen> createState() => _ModifierAnnonceScreenState();
}

class _ModifierAnnonceScreenState extends State<ModifierAnnonceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = AnnonceService();

  late final TextEditingController _titreController;
  late final TextEditingController _descController;
  late final TextEditingController _prixController;
  late final TextEditingController _villeController;
  late final TextEditingController _quartierController;

  List<Map<String, dynamic>> _categories = [];
  int? _categorieId;

  // Photos déjà en base — {id, url_image}. Retirées de la liste = à supprimer.
  late List<Map<String, dynamic>> _imagesExistantes;
  // Nouvelles photos ajoutées localement, pas encore uploadées.
  final List<File> _nouvellesImages = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final a = widget.annonce;

    _titreController = TextEditingController(text: a['titre'] ?? '');
    _descController = TextEditingController(text: a['description'] ?? '');
    _prixController = TextEditingController(
      text: (a['prix_actuel'] as num?)?.toStringAsFixed(0) ?? '',
    );
    _villeController = TextEditingController(text: a['ville'] ?? '');
    _quartierController = TextEditingController(text: a['quartier'] ?? '');
    _categorieId = a['categorie_id'] as int?;

    final imgs = (a['images_annonce'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    imgs.sort((x, y) => (x['ordre'] as int? ?? 0)
        .compareTo(y['ordre'] as int? ?? 0));
    _imagesExistantes = imgs;

    _chargerCategories();
  }

  Future<void> _chargerCategories() async {
    final cats = await _service.getCategories();
    setState(() => _categories = cats);
  }

  int get _totalPhotos =>
      _imagesExistantes.length + _nouvellesImages.length;

  /// Slot i (0 = principale) → soit une image existante (Map), soit une
  /// nouvelle image locale (File), soit null si le slot est vide.
  dynamic _contenuSlot(int index) {
    if (index < _imagesExistantes.length) {
      return _imagesExistantes[index];
    }
    final indexNouvelle = index - _imagesExistantes.length;
    if (indexNouvelle < _nouvellesImages.length) {
      return _nouvellesImages[indexNouvelle];
    }
    return null;
  }

  void _retirerSlot(int index) {
    setState(() {
      if (index < _imagesExistantes.length) {
        _imagesExistantes.removeAt(index);
      } else {
        _nouvellesImages.removeAt(index - _imagesExistantes.length);
      }
    });
  }

  Future<void> _ajouterImage() async {
    if (_totalPhotos >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 photos')),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _nouvellesImages.add(File(picked.path)));
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categorieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez une catégorie')),
      );
      return;
    }
    if (_totalPhotos == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins une photo')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final annonceId = widget.annonce['id'] as int;

      // 1. Supprimer les photos existantes retirées par l'utilisateur
      final idsOriginaux = (widget.annonce['images_annonce'] as List<dynamic>)
          .map((e) => (e as Map)['id'] as int)
          .toSet();
      final idsConserves =
      _imagesExistantes.map((e) => e['id'] as int).toSet();
      final idsASupprimer = idsOriginaux.difference(idsConserves);
      for (final id in idsASupprimer) {
        await _service.supprimerImageAnnonce(id);
      }

      // 2. Uploader et ajouter les nouvelles photos
      var ordre = _imagesExistantes.length;
      for (final img in _nouvellesImages) {
        final url = await _service.uploadImage(img.path);
        await _service.ajouterImageAnnonce(
          annonceId: annonceId,
          urlImage: url,
          ordre: ordre,
        );
        ordre++;
      }

      // 3. Mettre à jour les champs de l'annonce
      await _service.modifierAnnonce(
        annonceId: annonceId,
        titre: _titreController.text.trim(),
        description: _descController.text.trim(),
        prix: double.parse(_prixController.text.trim()),
        categorieId: _categorieId!,
        ville: _villeController.text.trim(),
        quartier: _quartierController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annonce mise à jour')),
        );
        Navigator.pop(context, true);
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Modifier l\'annonce', style: AppTextStyles.titleMd),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('PHOTOS (MAX 5)'),
              const SizedBox(height: AppSpacing.stackSm),
              _buildPhotoPicker(),

              const SizedBox(height: AppSpacing.stackLg),
              _buildLabel('TITRE DE L\'ANNONCE'),
              const SizedBox(height: AppSpacing.stackSm),
              _buildField(
                controller: _titreController,
                hint: 'Ex: iPhone 14 Pro Max 256GB',
                validator: (v) =>
                v == null || v.isEmpty ? 'Champ obligatoire' : null,
              ),

              const SizedBox(height: AppSpacing.stackLg),
              _buildLabel('PRIX (FCFA)'),
              const SizedBox(height: AppSpacing.stackSm),
              _buildField(
                controller: _prixController,
                hint: '0',
                keyboardType: TextInputType.number,
                suffixText: 'CFA',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ obligatoire';
                  if (double.tryParse(v) == null) return 'Prix invalide';
                  return null;
                },
              ),

              const SizedBox(height: AppSpacing.stackLg),
              _buildLabel('CATÉGORIE'),
              const SizedBox(height: AppSpacing.stackSm),
              _buildCategorieDropdown(),

              const SizedBox(height: AppSpacing.stackLg),
              _buildLabel('DESCRIPTION'),
              const SizedBox(height: AppSpacing.stackSm),
              _buildField(
                controller: _descController,
                hint:
                'Décrivez l\'état de l\'objet, son utilisation, ses défauts...',
                maxLines: 4,
                validator: (v) =>
                v == null || v.isEmpty ? 'Champ obligatoire' : null,
              ),

              const SizedBox(height: AppSpacing.stackLg),
              _buildLabel('VILLE'),
              const SizedBox(height: AppSpacing.stackSm),
              _buildField(
                controller: _villeController,
                hint: 'Ex: Dakar',
                validator: (v) =>
                v == null || v.isEmpty ? 'Champ obligatoire' : null,
              ),

              const SizedBox(height: AppSpacing.stackLg),
              _buildLabel('QUARTIER'),
              const SizedBox(height: AppSpacing.stackSm),
              _buildField(
                controller: _quartierController,
                hint: 'Ex: Plateau',
              ),

              const SizedBox(height: AppSpacing.stackLg + 8),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Grille photos : principale (grande) + 4 secondaires ──
  Widget _buildPhotoPicker() {
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: _buildPhotoSlot(0, principal: true),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildPhotoSlot(1, principal: false)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildPhotoSlot(2, principal: false)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildPhotoSlot(3, principal: false)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildPhotoSlot(4, principal: false)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlot(int index, {required bool principal}) {
    final contenu = _contenuSlot(index);

    return GestureDetector(
      onTap: contenu == null ? _ajouterImage : null,
      child: Container(
        decoration: BoxDecoration(
          color: contenu == null ? AppColors.softBlush : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        clipBehavior: Clip.antiAlias,
        child: contenu == null
            ? Center(
          child: principal
              ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_a_photo_outlined,
                  color: AppColors.primary, size: 26),
              const SizedBox(height: 8),
              Text('Photo principale',
                  style: AppTextStyles.bodySm.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  )),
            ],
          )
              : const Icon(Icons.add,
              color: AppColors.primary, size: 20),
        )
            : Stack(
          fit: StackFit.expand,
          children: [
            contenu is File
                ? Image.file(contenu, fit: BoxFit.cover)
                : CachedNetworkImage(
              imageUrl: contenu['url_image'] as String,
              fit: BoxFit.cover,
              placeholder: (_, __) =>
                  Container(color: AppColors.softBlush),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _retirerSlot(index),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 13, color: AppColors.navy),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(text, style: AppTextStyles.labelCaps),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? suffixText,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: AppTextStyles.bodyMd,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.bodyMd.copyWith(
            color: AppColors.rosyTaupe,
          ),
          suffixText: suffixText,
          suffixStyle: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
            fontSize: 14,
          ),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategorieDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: DropdownButtonFormField<int>(
        value: _categorieId,
        hint: Text('Sélectionner',
            style:
            AppTextStyles.bodyMd.copyWith(color: AppColors.rosyTaupe)),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            borderSide: BorderSide.none,
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.navy),
        items: _categories
            .map((c) => DropdownMenuItem<int>(
          value: c['id'] as int,
          child: Text(c['nom'], style: AppTextStyles.bodyMd),
        ))
            .toList(),
        onChanged: (v) => setState(() => _categorieId = v),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _enregistrer,
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
            : const Icon(Icons.check_rounded, size: 20),
        label: Text(
          _loading ? 'Enregistrement...' : 'Enregistrer les modifications',
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}