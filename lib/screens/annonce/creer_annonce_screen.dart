import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../services/annonce_service.dart';
import '../../theme/app_theme.dart';

class CreerAnnonceScreen extends StatefulWidget {
  const CreerAnnonceScreen({super.key});

  @override
  State<CreerAnnonceScreen> createState() => _CreerAnnonceScreenState();
}

class _CreerAnnonceScreenState extends State<CreerAnnonceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = AnnonceService();
  final _titreController = TextEditingController();
  final _descController = TextEditingController();
  final _prixController = TextEditingController();
  final _villeController = TextEditingController();
  final _quartierController = TextEditingController();

  List<Map<String, dynamic>> _categories = [];
  int? _categorieId;
  List<File> _images = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _chargerCategories();
  }

  Future<void> _chargerCategories() async {
    final cats = await _service.getCategories();
    setState(() => _categories = cats);
  }

  Future<void> _ajouterImage() async {
    if (_images.length >= 5) {
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
      setState(() => _images.add(File(picked.path)));
    }
  }

  void _supprimerImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _publier() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categorieId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez une catégorie')),
      );
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _loading = true);

    try {
      final urls = <String>[];
      for (final img in _images) {
        final url = await _service.uploadImage(img.path);
        urls.add(url);
      }

      await _service.creerAnnonce(
        titre: _titreController.text.trim(),
        description: _descController.text.trim(),
        prix: double.parse(_prixController.text.trim()),
        categorieId: _categorieId!,
        ville: _villeController.text.trim(),
        quartier: _quartierController.text.trim(),
        userId: userId,
        urlsImages: urls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annonce publiée avec succès')),
        );
        _formKey.currentState!.reset();
        _titreController.clear();
        _descController.clear();
        _prixController.clear();
        _villeController.clear();
        _quartierController.clear();
        setState(() {
          _images = [];
          _categorieId = null;
        });
        Navigator.pop(context);
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
        title: Text('Vendre un article', style: AppTextStyles.titleMd),
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
              _buildPublishButton(),
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
            child: _buildPhotoSlot(
              file: _images.isNotEmpty ? _images[0] : null,
              principal: true,
              onTap: _images.isEmpty ? _ajouterImage : null,
              onRemove:
              _images.isNotEmpty ? () => _supprimerImage(0) : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildSecondarySlot(1)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSecondarySlot(2)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _buildSecondarySlot(3)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSecondarySlot(4)),
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

  Widget _buildSecondarySlot(int index) {
    final hasImage = index < _images.length;
    return _buildPhotoSlot(
      file: hasImage ? _images[index] : null,
      principal: false,
      onTap: !hasImage ? _ajouterImage : null,
      onRemove: hasImage ? () => _supprimerImage(index) : null,
    );
  }

  Widget _buildPhotoSlot({
    File? file,
    required bool principal,
    VoidCallback? onTap,
    VoidCallback? onRemove,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: file == null ? AppColors.softBlush : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          image: file != null
              ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
              : null,
        ),
        child: file == null
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
          children: [
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
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

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : _publier,
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
            : const Icon(Icons.publish_rounded, size: 20),
        label: Text(
          _loading ? 'Publication...' : 'Publier l\'annonce',
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